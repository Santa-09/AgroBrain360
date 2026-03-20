import logging
import os

from config.settings import settings
from services import groq_service

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


async def generate(prompt: str, language: str = "en") -> str:
    """Call Groq and fall back to canned advice if unavailable."""
    try:
        response = await groq_service.generate_response(
            prompt,
            system_prompt=(
                "You are AgroBrain360, an agricultural advisor for Indian farmers. "
                f"Respond in {language}. Keep guidance practical, concise, and safe."
            ),
            language=language,
        )
        return response["text"] or (
            "Please consult your local Krishi Vigyan Kendra or agriculture "
            "extension officer for specific advice."
        )
    except Exception as e:
        log.error("Groq advisory generation failed: %s", e)
        return "Advisory service temporarily unavailable. Please try again later."


def create_realtime_session(module: str, data: dict, language: str = "en",
                            voice: str | None = None) -> dict:
    raise RuntimeError(
        "Realtime sessions are not used in the Groq and ElevenLabs voice pipeline."
    )
