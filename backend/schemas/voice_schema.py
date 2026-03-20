from pydantic import BaseModel


class VoiceTranscriptionResponse(BaseModel):
    text: str
    source: str
    language: str | None = None
    intent: str | None = None
    confidence: float | None = None
    route: str | None = None


class VoicePipelineResponse(BaseModel):
    user_text: str
    ai_response: str
    audio_url: str | None = None
    module: str
    language: str
    stt_source: str | None = None
    llm_source: str | None = None
    intent: str | None = None
    confidence: float | None = None
    route: str | None = None
    tts_error: str | None = None
