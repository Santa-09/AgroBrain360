from fastapi import APIRouter

from schemas.chat_schema import CaseChatRequest
from services import chat_service, response_service

router = APIRouter(prefix="/chat", tags=["AI Chat"])


@router.post("/case", response_model=dict)
async def case_chat(body: CaseChatRequest):
    result = await chat_service.chat_case(
        module=body.module,
        question=body.question,
        context=body.context,
        language=body.language,
    )
    return response_service.build(result, lang=body.language)
