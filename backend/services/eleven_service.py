from pathlib import Path
from uuid import uuid4

import httpx

from config.settings import settings


class ElevenLabsServiceError(RuntimeError):
    pass


async def text_to_speech(text: str) -> dict[str, str]:
    if not settings.ELEVENLABS_API_KEY or not settings.VOICE_ID:
        raise ElevenLabsServiceError(
            "ELEVENLABS_API_KEY or VOICE_ID is not configured"
        )

    voice_dir = settings.STATIC_DIR / "voice"
    voice_dir.mkdir(parents=True, exist_ok=True)
    output_path = voice_dir / f"output_{uuid4().hex}.mp3"

    async with httpx.AsyncClient(timeout=90) as client:
        response = await client.post(
            f"{settings.ELEVENLABS_BASE_URL.rstrip('/')}/text-to-speech/{settings.VOICE_ID}",
            headers={
                "xi-api-key": settings.ELEVENLABS_API_KEY,
                "Accept": "audio/mpeg",
                "Content-Type": "application/json",
            },
            json={
                "text": text,
                "model_id": settings.ELEVENLABS_MODEL_ID,
                "voice_settings": {
                    "stability": 0.45,
                    "similarity_boost": 0.75,
                },
            },
        )
        response.raise_for_status()
        audio_bytes = response.content

    Path(output_path).write_bytes(audio_bytes)
    return {
        "path": str(output_path),
        "filename": output_path.name,
        "audio_url": f"/static/voice/{output_path.name}",
    }
