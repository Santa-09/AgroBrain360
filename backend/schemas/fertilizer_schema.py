from pydantic import BaseModel, Field


class FertilizerPredictRequest(BaseModel):
    temperature: float = Field(..., alias="Temparature")
    humidity: float = Field(..., alias="Humidity")
    moisture: float = Field(..., alias="Moisture")
    soil_type: str = Field(..., alias="Soil Type")
    crop_type: str = Field(..., alias="Crop Type")
    nitrogen: float = Field(..., alias="Nitrogen")
    potassium: float = Field(..., alias="Potassium")
    phosphorous: float = Field(..., alias="Phosphorous")

    model_config = {
        "populate_by_name": True,
        "json_schema_extra": {
            "example": {
                "temperature": 26,
                "humidity": 52,
                "moisture": 38,
                "soil_type": "Sandy",
                "crop_type": "Maize",
                "nitrogen": 37,
                "potassium": 0,
                "phosphorous": 0,
            }
        },
    }

    def to_model_features(self) -> dict:
        return {
            "Temparature": self.temperature,
            "Humidity ": self.humidity,
            "Moisture": self.moisture,
            "Soil Type": self.soil_type,
            "Crop Type": self.crop_type,
            "Nitrogen": self.nitrogen,
            "Potassium": self.potassium,
            "Phosphorous": self.phosphorous,
        }


class FertilizerRecommendationItem(BaseModel):
    fertilizer: str
    confidence: float


class FertilizerPredictResponse(BaseModel):
    fertilizer: str
    confidence: float
    summary: str
    application_tip: str
    top_recommendations: list[FertilizerRecommendationItem]
