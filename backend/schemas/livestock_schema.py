# backend/schemas/livestock_schema.py
from pydantic import BaseModel
from typing import Optional


class LivestockDiagnoseRequest(BaseModel):
    animal_type: str
    symptoms: str
    language: str = "en"


class LivestockDiagnoseResponse(BaseModel):
    disease: str
    risk_level: str
    treatment: str
    first_aid: Optional[str] = None