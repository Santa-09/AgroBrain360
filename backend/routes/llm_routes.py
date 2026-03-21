# backend/routes/llm_routes.py
from fastapi import APIRouter, HTTPException
from services import llm_service, response_service
from schemas.intent_schema import LLMAdviseRequest, RealtimeSessionRequest

router = APIRouter(prefix="/llm", tags=["LLM Advisory"])


@router.post("/advise")
async def get_llm_advice(body: LLMAdviseRequest):
    prompt   = llm_service.build_prompt(body.module, body.data)
    advice   = await llm_service.generate(
        prompt,
        language=body.language,
        module=body.module,
        data=body.data,
    )
    return response_service.build({"advice": advice}, lang=body.language)


@router.post("/realtime/session")
def create_realtime_session(body: RealtimeSessionRequest):
    try:
        session = llm_service.create_realtime_session(
            module=body.module,
            data=body.data,
            language=body.language,
            voice=body.voice,
        )
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e)) from e

    return response_service.build(session, lang=body.language)
