from typing import Any

from pydantic import BaseModel


class CaseChatRequest(BaseModel):
    module: str
    question: str
    context: dict[str, Any] = {}
    language: str = "en"


class CaseChatResponse(BaseModel):
    ai_response: str
    module: str
    source: str
