# backend/schemas/intent_schema.py
from pydantic import BaseModel
from typing import Optional, Dict, Any


class IntentRequest(BaseModel):
    query: str
    language: str = "en"


class IntentResponse(BaseModel):
    intent:     str
    confidence: float
    route:      str


class LLMAdviseRequest(BaseModel):
    module:   str
    data:     Dict[str, Any]
    language: str = "en"


class LLMAdviseResponse(BaseModel):
    advice: str


class RealtimeSessionRequest(BaseModel):
    module: str
    data: Dict[str, Any]
    language: str = "en"
    voice: str = "marin"


class RealtimeSessionResponse(BaseModel):
    session_id: str
    model: str
    voice: str
    client_secret: str
    expires_at: int | None = None
