import json
from typing import Any

import httpx

from config.settings import settings


class GroqServiceError(RuntimeError):
    pass


def _headers() -> dict[str, str]:
    if not settings.GROQ_API_KEY:
        raise GroqServiceError("GROQ_API_KEY is not configured")
    return {"Authorization": f"Bearer {settings.GROQ_API_KEY}"}


async def speech_to_text(
    audio: bytes,
    *,
    filename: str,
    content_type: str,
    language: str | None = None,
    prompt: str | None = None,
) -> dict[str, Any]:
    files = {
        "file": (filename or "audio.webm", audio, content_type or "audio/webm"),
    }
    data = {
        "model": settings.GROQ_STT_MODEL,
    }
    if language:
        data["language"] = language
    if prompt:
        data["prompt"] = prompt

    async with httpx.AsyncClient(timeout=60) as client:
        response = await client.post(
            f"{settings.GROQ_BASE_URL.rstrip('/')}/audio/transcriptions",
            headers=_headers(),
            data=data,
            files=files,
        )
        response.raise_for_status()
        payload = response.json()

    return {
        "text": (payload.get("text") or "").strip(),
        "language": payload.get("language") or language,
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

    async with httpx.AsyncClient(timeout=60) as client:
        response = await client.post(
            f"{settings.GROQ_BASE_URL.rstrip('/')}/chat/completions",
            headers={
                **_headers(),
                "Content-Type": "application/json",
            },
            json={
                "model": settings.MODEL_NAME,
                "messages": messages,
                "temperature": 0.3,
                "max_tokens": 600,
            },
        )
        response.raise_for_status()
        payload = response.json()

    choice = ((payload.get("choices") or [{}])[0]).get("message") or {}
    content = (choice.get("content") or "").strip()
    if not content:
        raise GroqServiceError("Groq returned an empty response")

    return {
        "text": content,
        "model": payload.get("model") or settings.MODEL_NAME,
        "source": "groq",
        "raw": payload,
    }
