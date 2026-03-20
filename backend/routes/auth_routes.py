from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import crud
from database.connection import get_db
from schemas.password_reset_schema import (
    PasswordResetConfirm,
    PasswordResetRequestOTP,
    PasswordResetVerifyOTP,
)
from schemas.user_schema import ProfileFeedbackRequest, ProfileResponse, ProfileUpsertRequest
from services import password_reset_service, response_service
from utils.auth import get_current_user_id

router = APIRouter(prefix="/auth", tags=["Auth"])


def _to_profile_response(profile) -> ProfileResponse:
    return ProfileResponse(
        user_id=profile.id,
        name=profile.name,
        language=profile.language,
        phone=profile.phone,
        email=profile.email,
        region=profile.region,
        is_active=profile.is_active,
        app_rating=profile.app_rating,
        app_feedback=profile.app_feedback,
        app_feedback_updated_at=profile.app_feedback_updated_at,
    )


@router.post("/profile", response_model=ProfileResponse, status_code=201)
def upsert_profile(
    body: ProfileUpsertRequest,
    db: Session = Depends(get_db),
    user_id=Depends(get_current_user_id),
):
    profile = crud.upsert_profile(
        db,
        user_id=user_id,
        name=body.name,
        language=body.language,
        phone=body.phone,
        email=body.email,
        region=body.region,
        is_active=body.is_active,
    )
    return _to_profile_response(profile)


@router.get("/profile/me", response_model=ProfileResponse)
def get_profile(
    db: Session = Depends(get_db),
    user_id=Depends(get_current_user_id),
):
    profile = crud.get_profile_by_id(db, user_id)
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    return _to_profile_response(profile)


@router.post("/profile/feedback", response_model=ProfileResponse)
def update_profile_feedback(
    body: ProfileFeedbackRequest,
    db: Session = Depends(get_db),
    user_id=Depends(get_current_user_id),
):
    profile = crud.update_profile_feedback(
        db,
        user_id=user_id,
        rating=body.rating,
        feedback=body.feedback,
    )
    return _to_profile_response(profile)


@router.post("/forgot-password/request-otp")
def request_otp(
    body: PasswordResetRequestOTP,
    db: Session = Depends(get_db),
):
    payload = password_reset_service.request_password_reset_otp(db, body.email)
    return response_service.build(payload)


@router.post("/forgot-password/verify-otp")
def verify_otp(
    body: PasswordResetVerifyOTP,
    db: Session = Depends(get_db),
):
    payload = password_reset_service.verify_password_reset_otp(db, body.email, body.otp)
    return response_service.build(payload)


@router.post("/forgot-password/reset")
def reset_password(
    body: PasswordResetConfirm,
    db: Session = Depends(get_db),
):
    payload = password_reset_service.reset_password(
        db,
        body.email,
        body.reset_token,
        body.new_password,
    )
    return response_service.build(payload)
