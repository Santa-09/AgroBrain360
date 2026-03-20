# backend/schemas/health_schema.py
from pydantic import BaseModel, Field


class HealthScoreRequest(BaseModel):
    crop_score:      float = Field(..., ge=0, le=100)
    soil_score:      float = Field(..., ge=0, le=100)
    water_score:     float = Field(..., ge=0, le=100)
    livestock_score: float = Field(..., ge=0, le=100)
    machinery_score: float = Field(..., ge=0, le=100)


class HealthScoreResponse(BaseModel):
    fhi_score:       float
    crop_score:      float
    soil_score:      float
    water_score:     float
    livestock_score: float
    machinery_score: float
    label:           str    # Excellent / Good / Fair / Poor