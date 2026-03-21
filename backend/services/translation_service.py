# backend/services/translation_service.py
import logging
log = logging.getLogger(__name__)

SUPPORTED = {"en", "hi", "od", "ta", "te"}

LANG_MAP = {
    "hi": "hi",
    "od": "or",   # Odia ISO code
    "ta": "ta",
    "te": "te",
}


def normalize_language_code(code: str | None) -> str:
    normalized = (code or "en").strip().lower()
    aliases = {
        "en-us": "en",
        "en-in": "en",
        "english": "en",
        "hindi": "hi",
        "odia": "od",
        "oriya": "od",
        "or": "od",
        "or-in": "od",
        "tamil": "ta",
        "telugu": "te",
    }
    normalized = aliases.get(normalized, normalized)
    return normalized if normalized in SUPPORTED else "en"


def stt_language_code(code: str | None) -> str | None:
    normalized = normalize_language_code(code)
    if normalized == "en":
        return "en"
    return LANG_MAP.get(normalized, normalized)


def translate(text: str, target_lang: str) -> str:
    target_lang = normalize_language_code(target_lang)
    if target_lang == "en" or target_lang not in SUPPORTED:
        return text
    try:
        from deep_translator import GoogleTranslator
        dest = LANG_MAP.get(target_lang, "hi")
        return GoogleTranslator(source="en", target=dest).translate(text)
    except Exception as e:
        log.warning(f"Translation failed ({target_lang}): {e}")
        return text


def maybe_translate_from_english(
    text: str,
    target_lang: str,
    *,
    source_lang: str | None = "en",
) -> str:
    normalized_source = normalize_language_code(source_lang)
    normalized_target = normalize_language_code(target_lang)
    if normalized_source != "en":
      return text
    return translate(text, normalized_target)
