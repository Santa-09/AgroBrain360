import json
import mimetypes
from typing import Any

import httpx

from config.settings import settings
from services import translation_service


class GroqServiceError(RuntimeError):
    pass


_MODEL_ALIASES = {
    "llama3-8b-8192": "llama-3.1-8b-instant",
    "llama3-70b-8192": "llama-3.3-70b-versatile",
}


def _headers() -> dict[str, str]:
    if not settings.GROQ_API_KEY:
        raise GroqServiceError("GROQ_API_KEY is not configured")
    return {"Authorization": f"Bearer {settings.GROQ_API_KEY}"}


def _chat_model_name() -> str:
    configured = (settings.MODEL_NAME or "").strip()
    if not configured:
        return "llama-3.1-8b-instant"
    return _MODEL_ALIASES.get(configured, configured)


async def speech_to_text(
    audio: bytes,
    *,
    filename: str,
    content_type: str,
    language: str | None = None,
    prompt: str | None = None,
) -> dict[str, Any]:
    guessed_content_type, _ = mimetypes.guess_type(filename or "audio.webm")
    files = {
        "file": (
            filename or "audio.webm",
            audio,
            content_type
            if content_type and content_type != "application/octet-stream"
            else guessed_content_type or "audio/webm",
        ),
    }
    data = {
        "model": settings.GROQ_STT_MODEL,
    }
    stt_language = translation_service.stt_language_code(language)
    if stt_language:
        data["language"] = stt_language
    if prompt:
        data["prompt"] = prompt

    async with httpx.AsyncClient(timeout=60) as client:
        try:
            response = await client.post(
                f"{settings.GROQ_BASE_URL.rstrip('/')}/audio/transcriptions",
                headers=_headers(),
                data=data,
                files=files,
            )
            response.raise_for_status()
            payload = response.json()
        except httpx.HTTPStatusError as exc:
            detail = ""
            try:
                payload = response.json()
                detail = (
                    payload.get("error", {}).get("message")
                    or payload.get("message")
                    or response.text
                )
            except Exception:
                detail = response.text
            raise GroqServiceError(
                f"Groq transcription failed for model '{settings.GROQ_STT_MODEL}': "
                f"{response.status_code} {detail.strip()}"
            ) from exc
        except httpx.RequestError as exc:
            raise GroqServiceError(f"Groq transcription request failed: {exc}") from exc

    return {
        "text": (payload.get("text") or "").strip(),
        "language": payload.get("language") or stt_language or language,
        "source": f"groq:{settings.GROQ_STT_MODEL}",
        "raw": payload,
    }


async def generate_response(
    text: str,
    *,
    system_prompt: str | None = None,
    module: str | None = None,
    language: str = "en",
    context: dict[str, Any] | None = None,
) -> dict[str, Any]:
    language = translation_service.normalize_language_code(language)
    messages: list[dict[str, str]] = []

    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})

    user_parts = [
        f"Language: {language}",
    ]
    if module:
        user_parts.append(f"Module: {module}")
    if context:
        user_parts.append(f"Context: {json.dumps(context, ensure_ascii=False)}")
    user_parts.append(f"User request: {text}")

    messages.append({"role": "user", "content": "\n".join(user_parts)})

    model_name = _chat_model_name()
    async with httpx.AsyncClient(timeout=60) as client:
        try:
            response = await client.post(
                f"{settings.GROQ_BASE_URL.rstrip('/')}/chat/completions",
                headers={
                    **_headers(),
                    "Content-Type": "application/json",
                },
                json={
                    "model": model_name,
                    "messages": messages,
                    "temperature": 0.3,
                    "max_tokens": 600,
                },
            )
        except httpx.RequestError as exc:
            raise GroqServiceError(f"Groq chat request failed: {exc}") from exc
        try:
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            detail = ""
            try:
                payload = response.json()
                detail = (
                    payload.get("error", {}).get("message")
                    or payload.get("message")
                    or response.text
                )
            except Exception:
                detail = response.text
            raise GroqServiceError(
                f"Groq chat request failed for model '{model_name}': "
                f"{response.status_code} {detail.strip()}"
            ) from exc
        payload = response.json()

    choice = ((payload.get("choices") or [{}])[0]).get("message") or {}
    content = (choice.get("content") or "").strip()
    if not content:
        raise GroqServiceError("Groq returned an empty response")

    return {
        "text": content,
        "model": payload.get("model") or model_name,
        "source": "groq",
        "raw": payload,
    }
