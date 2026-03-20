import json
from typing import Any

from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from services import response_service, voice_service

router = APIRouter(tags=["Voice"])

ALLOWED_AUDIO_TYPES = {
    "audio/mpeg",
    "audio/mp3",
    "audio/mp4",
    "audio/m4a",
    "audio/x-m4a",
    "audio/aac",
    "audio/wav",
    "audio/x-wav",
    "audio/webm",
    "audio/ogg",
    "video/webm",
}
ALLOWED_AUDIO_EXTENSIONS = {
    ".mp3",
    ".mp4",
    ".m4a",
    ".aac",
    ".wav",
    ".webm",
    ".ogg",
}


def _is_allowed_audio_upload(file: UploadFile) -> bool:
    if file.content_type in ALLOWED_AUDIO_TYPES:
        return True

    filename = (file.filename or "").lower()
    return any(filename.endswith(ext) for ext in ALLOWED_AUDIO_EXTENSIONS)


def _parse_context(raw_context: str | None) -> dict[str, Any]:
    if not raw_context:
        return {}
    try:
        parsed = json.loads(raw_context)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=400, detail="context must be valid JSON") from exc
    if not isinstance(parsed, dict):
        raise HTTPException(status_code=400, detail="context must be a JSON object")
    return parsed


@router.post("/voice", response_model=dict)
async def voice_pipeline(
    file: UploadFile = File(...),
    module: str = Form(...),
    language: str = Form(default="en"),
    prompt: str | None = Form(default=None),
    context: str | None = Form(default=None),
    detect_intent: bool = Form(default=True),
):
    if not _is_allowed_audio_upload(file):
        raise HTTPException(status_code=400, detail="Only audio uploads are accepted")

    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="Uploaded audio file is empty")

    result = await voice_service.run_voice_pipeline(
        filename=file.filename or "audio.webm",
        content=content,
        content_type=file.content_type or "application/octet-stream",
        module=module,
        language=language,
        prompt=prompt,
        context=_parse_context(context),
        detect_intent=detect_intent,
    )
    return response_service.build(result, lang=language)


@router.post("/voice/transcribe", response_model=dict)
async def transcribe_voice(
    file: UploadFile = File(...),
    language: str | None = Form(default=None),
    prompt: str | None = Form(default=None),
    detect_intent: bool = Form(default=False),
):
    if not _is_allowed_audio_upload(file):
        raise HTTPException(status_code=400, detail="Only audio uploads are accepted")

    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="Uploaded audio file is empty")

    result = await voice_service.transcribe_audio(
        filename=file.filename or "audio.webm",
        content=content,
        content_type=file.content_type or "application/octet-stream",
        language=language,
        prompt=prompt,
        detect_intent=detect_intent,
    )
    return response_service.build(result, lang=language or "en")
