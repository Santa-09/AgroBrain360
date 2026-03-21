from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from sqlalchemy.orm import Session

from database.connection import get_db
from database import crud
from services import crop_service, response_service, roi_service
from services import ml_service
from schemas.crop_schema import CropRecommendationRequest
from utils.auth import get_optional_user_id

router = APIRouter(prefix="/crop", tags=["Crop Section"])

ALLOWED_IMAGE_TYPES = {
    "image/jpeg",
    "image/png",
    "image/jpg",
    "image/webp",
}
ALLOWED_IMAGE_EXTENSIONS = {
    ".jpeg",
    ".jpg",
    ".png",
    ".webp",
}


def _is_allowed_image_upload(file: UploadFile) -> bool:
    if file.content_type in ALLOWED_IMAGE_TYPES:
        return True

    filename = (file.filename or "").lower()
    return any(filename.endswith(ext) for ext in ALLOWED_IMAGE_EXTENSIONS)


@router.post("/predict")
async def predict_crop_disease(
    file: UploadFile = File(...),
    crop_type: str = None,
    area_acres: float = 1.0,
    lang: str = "en",
    db: Session = Depends(get_db),
    user_id=Depends(get_optional_user_id),
):
    if not _is_allowed_image_upload(file):
        raise HTTPException(
            status_code=400,
            detail="Only JPEG, PNG, or WEBP images are accepted",
        )

    image_bytes = await file.read()
    result      = crop_service.analyze_disease(image_bytes, language=lang)
    roi         = roi_service.calculate_roi(result["disease"], crop_type, area_acres)

    if user_id is not None:
        crud.create_crop_scan(
            db, user_id=user_id,
            disease=result["disease"],
            confidence=result["confidence"],
            crop_type=crop_type,
            severity=result.get("severity"),
            treatment=result.get("treatment"),
        )

    return response_service.build({**result, "roi": roi}, lang=lang)


@router.post("/recommend")
def recommend_crop(body: CropRecommendationRequest, lang: str = "en"):
    features = ml_service.build_crop_recommendation_features(
        nitrogen=body.nitrogen,
        phosphorous=body.phosphorous,
        potassium=body.potassium,
        temperature=body.temperature,
        humidity=body.humidity,
        ph=body.ph,
        rainfall=body.rainfall,
    )
    result = ml_service.predict_crop_recommendation(features)
    return response_service.build(result, lang=lang)
