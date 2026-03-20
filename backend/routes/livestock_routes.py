# backend/routes/livestock_routes.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database.connection import get_db
from database import crud
from services import livestock_service, response_service
from schemas.livestock_schema import LivestockDiagnoseRequest
from utils.auth import get_optional_user_id

router = APIRouter(prefix="/livestock", tags=["Livestock"])


@router.post("/diagnose")
def diagnose_livestock(
    body: LivestockDiagnoseRequest,
    db: Session = Depends(get_db),
    user_id=Depends(get_optional_user_id),
):
    result = livestock_service.diagnose(body.animal_type, body.symptoms)

    if user_id is not None:
        crud.create_livestock_rec(
            db, user_id=user_id,
            animal_type=body.animal_type,
            symptoms=body.symptoms,
            disease=result["disease"],
            risk_level=result["risk_level"],
            treatment=result["treatment"],
        )

    return response_service.build(result, lang=body.language)
