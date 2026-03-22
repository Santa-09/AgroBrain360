import logging
import os
import re

from config.settings import settings
from services import groq_service, translation_service

log = logging.getLogger(__name__)
PROMPT_DIR = os.path.join(os.path.dirname(__file__), "..", "llm", "prompts")


def _load_prompt(name: str) -> str:
    path = os.path.join(PROMPT_DIR, f"{name}_prompt.txt")
    if not os.path.exists(path):
        return "You are an expert agricultural advisor for Indian farmers. {context}"
    with open(path, encoding="utf-8") as f:
        return f.read()


def build_prompt(module: str, data: dict) -> str:
    template = _load_prompt(module)
    try:
        return template.format(**data)
    except KeyError:
        return template + f"\n\nContext: {data}"


def _build_realtime_instructions(module: str, data: dict, language: str) -> str:
    prompt = build_prompt(module, data)
    return (
        "You are AgroBrain360, a practical agricultural advisor for Indian farmers. "
        f"Respond in {language}. Keep guidance concise, accurate, and action-oriented.\n\n"
        f"{prompt}"
    )


def clean_advisory_text(text: str) -> str:
    cleaned = (text or "").strip()
    if not cleaned:
        return cleaned

    # Remove markdown emphasis and heading markers.
    cleaned = re.sub(r"\*\*(.*?)\*\*", r"\1", cleaned)
    cleaned = cleaned.replace("**", "").replace("__", "")
    cleaned = re.sub(r"^[#>\-\s]+", "", cleaned, flags=re.MULTILINE)

    # Remove generic assistant openers that make the advisory useless.
    generic_openers = [
        r"^how can i assist you today[\s\?\.\!,:-]*",
        r"^how may i assist you today[\s\?\.\!,:-]*",
        r"^how can i help you today[\s\?\.\!,:-]*",
        r"^how may i help you today[\s\?\.\!,:-]*",
        r"^hello[\s,!.:-]*",
        r"^hi[\s,!.:-]*",
    ]
    for pattern in generic_openers:
        cleaned = re.sub(pattern, "", cleaned, flags=re.IGNORECASE).strip()

    cleaned = re.sub(r"\n{3,}", "\n\n", cleaned)
    return cleaned.strip()


def _stringify(value: object) -> str:
    if value is None:
        return ""
    if isinstance(value, (list, tuple, set)):
        return ", ".join(str(item) for item in value if str(item).strip())
    return str(value).strip()


def _fallback_advisory(module: str | None, data: dict | None, prompt: str) -> str:
    module_name = (module or "").strip().lower()
    payload = data or {}

    if module_name == "livestock":
        animal = _stringify(payload.get("animal") or payload.get("animal_type")) or "animal"
        symptoms = _stringify(payload.get("symptoms") or payload.get("voice_text") or payload.get("context"))
        return clean_advisory_text(
            f"For the {animal}, isolate the sick animal from the herd and keep it in a clean, dry area. "
            f"Give clean water and soft feed, and monitor temperature, breathing, and appetite twice today. "
            f"Symptoms noted: {symptoms or 'not provided'}. "
            "If there is high fever, repeated vomiting, severe diarrhea, blood in stool, or the animal stops eating, contact a veterinarian immediately. "
            "Do not start random antibiotics without veterinary guidance."
        )

    if module_name == "crop":
        crop = _stringify(payload.get("crop") or payload.get("crop_type")) or "crop"
        issue = _stringify(payload.get("issue") or payload.get("symptoms") or payload.get("voice_text") or payload.get("context"))
        return clean_advisory_text(
            f"Check the {crop} field closely and remove badly affected leaves or plants if the damage is spreading. "
            "Avoid spraying in the hottest part of the day, and do not over-irrigate stressed plants. "
            f"Observed issue: {issue or 'not provided'}. "
            "Inspect both sides of the leaves for spots, insects, or fungal growth and keep a sample photo for local agri officer review. "
            "If damage is increasing within 24 to 48 hours, use the recommended crop protection product for the diagnosed disease or pest."
        )

    if module_name == "machinery":
        machine = _stringify(payload.get("machine") or payload.get("equipment") or payload.get("machine_type")) or "machine"
        issue = _stringify(payload.get("issue") or payload.get("issue_type") or payload.get("voice_text") or payload.get("context"))
        return clean_advisory_text(
            f"Stop using the {machine} until the problem is checked. "
            "Inspect fuel level, engine oil, loose wiring, visible leaks, and unusual vibration before restarting. "
            f"Reported issue: {issue or 'not provided'}. "
            "Tighten loose connections, clean air filters, and check for blocked lines. "
            "If there is smoke, burning smell, or loud knocking noise, call a mechanic and avoid further operation."
        )

    if module_name == "residue":
        residue = _stringify(payload.get("residue_type") or payload.get("type")) or "crop residue"
        moisture = _stringify(payload.get("moisture") or payload.get("moisture_level")) or "unknown moisture"
        return clean_advisory_text(
            f"For {residue} with {moisture}, avoid open burning. "
            "Keep the material dry and separated for baling, composting, mulching, mushroom use, or sale based on local demand. "
            "If moisture is high, sun-dry first to improve storage and resale value. "
            "Check nearby buyers, fodder users, compost units, or biomass collection centers for the best return."
        )

    return clean_advisory_text(
        prompt
        or "Provide practical next steps, immediate precautions, and when to contact a local expert."
    ) or (
        "Check the situation carefully, take the safest immediate step, and contact a local agriculture or veterinary expert if the problem is severe."
    )


def offline_advisory(
    *,
    module: str | None,
    data: dict | None,
    prompt: str,
    language: str = "en",
) -> str:
    advice = _fallback_advisory(module, data, prompt)
    return clean_advisory_text(
        translation_service.translate(advice, language)
    )


async def generate(
    prompt: str,
    language: str = "en",
    *,
    module: str | None = None,
    data: dict | None = None,
) -> str:
    """Call Groq and fall back to practical offline advice if unavailable."""
    language = translation_service.normalize_language_code(language)
    try:
        response = await groq_service.generate_response(
            prompt,
            system_prompt=(
                "You are AgroBrain360, an agricultural advisor for Indian farmers. "
                "Respond in English. Give direct farm advice, not greetings. "
                "Do not say 'How can I assist you today'. "
                "Do not use markdown like **bold** or headings with #. "
                "Give specific actions the farmer should take now."
            ),
            language="en",
            module=module,
            context=data,
        )
        cleaned = clean_advisory_text(response["text"]) or (
            "Please consult your local Krishi Vigyan Kendra or agriculture "
            "extension officer for specific advice."
        )
        if language != "en":
            cleaned = translation_service.translate(cleaned, language)
        return clean_advisory_text(cleaned)
    except Exception as e:
        log.error("Groq advisory generation failed: %s", e)
        return offline_advisory(
            module=module,
            data=data,
            prompt=prompt,
            language=language,
        )


def create_realtime_session(module: str, data: dict, language: str = "en",
                            voice: str | None = None) -> dict:
    raise RuntimeError(
        "Realtime sessions are not used in the Groq and offline Coqui voice pipeline."
    )
