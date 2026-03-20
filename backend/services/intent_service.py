# backend/services/intent_service.py
from services import ml_service


def classify_intent(query: str) -> dict:
    return ml_service.predict_intent(query)