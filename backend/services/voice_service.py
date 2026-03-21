import logging
from typing import Any

from services import (
    coqui_tts_service,
    groq_service,
    intent_service,
    llm_service,
    translation_service,
)

log = logging.getLogger(__name__)


async def transcribe_audio(
    *,
    filename: str,
    content: bytes,
    content_type: str,
    language: str | None = None,
    prompt: str | None = None,
    detect_intent: bool = False,
) -> dict[str, Any]:
    language = translation_service.normalize_language_code(language)
    result = await groq_service.speech_to_text(
        content,
        filename=filename,
        content_type=content_type,
        language=language,
        prompt=prompt,
    )
    payload: dict[str, Any] = {
        "text": result["text"],
        "source": result["source"],
        "language": result.get("language") or language,
    }
    if detect_intent and payload["text"]:
        try:
            payload.update(intent_service.classify_intent(payload["text"]))
        except Exception as exc:
            log.warning("Intent detection failed for voice transcript: %s", exc)
    return payload


def build_voice_prompt(
    *,
    module: str,
    transcript: str,
    context: dict[str, Any] | None = None,
) -> str:
    merged_context = {"voice_text": transcript, "context": transcript}
    if context:
        merged_context.update(context)
    module_prompt = llm_service.build_prompt(module, merged_context)
    return (
        f"{module_prompt}\n\n"
        f"Farmer voice input: {transcript}\n"
        "Answer with direct, practical steps. Use short paragraphs or bullets only when useful."
    )


async def run_voice_pipeline(
    *,
    filename: str,
    content: bytes,
    content_type: str,
    module: str,
    language: str = "en",
    prompt: str | None = None,
    context: dict[str, Any] | None = None,
    detect_intent: bool = True,
) -> dict[str, Any]:
    language = translation_service.normalize_language_code(language)
    transcription = await transcribe_audio(
        filename=filename,
        content=content,
        content_type=content_type,
        language=language,
        prompt=prompt,
        detect_intent=detect_intent,
    )
    user_text = (transcription.get("text") or "").strip()
    if not user_text:
        raise RuntimeError("No speech detected in uploaded audio")

    voice_prompt = build_voice_prompt(
        module=module,
        transcript=user_text,
        context=context,
    )

    llm_source = None
    try:
        ai = await groq_service.generate_response(
            voice_prompt,
            system_prompt=(
                "You are AgroBrain360, an agricultural voice assistant for Indian farmers. "
                f"Respond in {language}. Be practical, calm, and action-oriented."
            ),
            module=module,
            language=language,
            context=context,
        )
        llm_source = ai.get("model")
        ai_text = llm_service.clean_advisory_text(ai["text"].strip())
    except Exception as exc:
        log.warning("Primary voice LLM call failed, using fallback text response: %s", exc)
        ai_text = llm_service.clean_advisory_text(
            await llm_service.generate(
                voice_prompt,
                language=language,
                module=module,
                data={"voice_text": user_text, **(context or {})},
            )
        )
        llm_source = "fallback"

    ai_response = ai_text

    audio_url: str | None = None
    tts_error: str | None = None
    try:
        tts = await coqui_tts_service.text_to_speech(ai_response)
        audio_url = tts["audio_url"]
    except Exception as exc:
        tts_error = str(exc)
        log.warning("Offline Coqui TTS failed, returning text-only response: %s", exc)

    payload: dict[str, Any] = {
        "user_text": user_text,
        "ai_response": ai_response,
        "audio_url": audio_url,
        "module": module,
        "language": language,
        "stt_source": transcription.get("source"),
        "llm_source": llm_source,
        "intent": transcription.get("intent"),
        "confidence": transcription.get("confidence"),
        "route": transcription.get("route"),
    }
    if tts_error:
        payload["tts_error"] = tts_error
    return payload
