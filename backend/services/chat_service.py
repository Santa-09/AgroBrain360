from typing import Any

from services import groq_service


def _system_prompt(language: str, module: str) -> str:
    return (
        "You are AgroBrain360, a practical farm advisor for Indian farmers. "
        f"Respond in {language}. The user is asking a follow-up question about the "
        f"{module} module. Use the supplied case context. Explain the likely problem, "
        "what the farmer should do now, what to monitor next, and when expert help is needed. "
        "Be concise, clear, and action-oriented. Avoid unsafe certainty."
    )


async def chat_case(
    *,
    module: str,
    question: str,
    context: dict[str, Any] | None = None,
    language: str = "en",
) -> dict[str, Any]:
    response = await groq_service.generate_response(
        question,
        system_prompt=_system_prompt(language, module),
        module=module,
        language=language,
        context=context or {},
    )
    return {
        "ai_response": response["text"],
        "module": module,
        "source": response.get("source", "groq"),
    }
