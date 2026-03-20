# backend/routes/health_routes.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database.connection import get_db
from database import crud
from services.health_index_service import compute_fhi
from services import response_service
from schemas.health_schema import HealthScoreRequest
from utils.auth import get_current_user_id, get_optional_user_id

router = APIRouter(prefix="/health", tags=["Farm Health Index"])


@router.post("/score")
def compute_health_score(
    body: HealthScoreRequest,
    lang: str = "en",
    db: Session = Depends(get_db),
    user_id=Depends(get_optional_user_id),
):
    result = compute_fhi(
        body.crop_score, body.soil_score, body.water_score,
        body.livestock_score, body.machinery_score,
    )
    if user_id is not None:
        crud.create_health_index(db, user_id=user_id, **result)

    return response_service.build(result, lang=lang)


@router.get("/score/latest")
def get_latest_score(
    db: Session = Depends(get_db),
    user_id=Depends(get_current_user_id),
):
    record = crud.get_latest_health_index(db, user_id)
    if not record:
        return response_service.build({"message": "No health index found"})
    return response_service.build({
        "fhi_score":       record.fhi_score,
        "crop_score":      record.crop_score,
        "soil_score":      record.soil_score,
        "water_score":     record.water_score,
        "livestock_score": record.livestock_score,
        "machinery_score": record.machinery_score,
        "created_at":      str(record.created_at),
    })
