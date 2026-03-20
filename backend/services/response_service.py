# backend/services/response_service.py
from typing import Any


def build(data: dict, lang: str = "en") -> dict:
    """Wrap prediction result in a standard API response envelope."""
    return {
        "success":  True,
        "language": lang,
        "data":     data,
    }


def error(message: str, code: int = 400) -> dict:
    return {
        "success": False,
        "error":   message,
        "code":    code,
    }