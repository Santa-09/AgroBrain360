from fastapi import APIRouter

from schemas.fertilizer_schema import FertilizerPredictRequest
from services import crop_service, response_service

router = APIRouter(prefix="/fertilizer", tags=["Fertilizer Recommendation"])


@router.post("/predict")
def predict_fertilizer(request: FertilizerPredictRequest, lang: str = "en"):
    result = crop_service.recommend_fertilizer(request.to_model_features())
    return response_service.build(result, lang=lang)
