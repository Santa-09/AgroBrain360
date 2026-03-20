# backend/schemas/crop_schema.py
from pydantic import BaseModel
from typing import Optional


class CropPredictResponse(BaseModel):
    disease: str
    confidence: float
    severity: Optional[str] = None
    treatment: Optional[str] = None
    prevention: Optional[str] = None
    risk_level: Optional[str] = None


class CropRecommendationRequest(BaseModel):
    nitrogen: float
    phosphorous: float
    potassium: float
    temperature: float
    humidity: float
    ph: float
    rainfall: float


class CropRecommendationResponse(BaseModel):
    crop: str
    confidence: float
