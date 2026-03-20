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


def translate(text: str, target_lang: str) -> str:
    if target_lang == "en" or target_lang not in SUPPORTED:
        return text
    try:
        from deep_translator import GoogleTranslator
        dest = LANG_MAP.get(target_lang, "hi")
        return GoogleTranslator(source="en", target=dest).translate(text)
    except Exception as e:
        log.warning(f"Translation failed ({target_lang}): {e}")
        return text