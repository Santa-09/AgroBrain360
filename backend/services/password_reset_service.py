import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone

import httpx
from fastapi import HTTPException
from sqlalchemy.orm import Session

from config.settings import settings
from database import crud
from services.email_service import send_password_reset_otp_email


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _hash_value(value: str) -> str:
    return hmac.new(
        settings.SECRET_KEY.encode("utf-8"),
        value.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


def _validate_strong_password(password: str) -> None:
    if len(password) < 8:
        raise HTTPException(status_code=400, detail="Password must be at least 8 characters long")
    if not any(ch.isupper() for ch in password):
        raise HTTPException(status_code=400, detail="Password must contain an uppercase letter")
    if not any(ch.islower() for ch in password):
        raise HTTPException(status_code=400, detail="Password must contain a lowercase letter")
    if not any(ch.isdigit() for ch in password):
        raise HTTPException(status_code=400, detail="Password must contain a digit")
    if not any(not ch.isalnum() for ch in password):
        raise HTTPException(status_code=400, detail="Password must contain a special character")


def _get_supabase_user_id_by_email(email: str) -> str | None:
    supabase_url = settings.SUPABASE_URL.rstrip("/")
    headers = {
        "apikey": settings.SUPABASE_SECRET_KEY,
        "Authorization": f"Bearer {settings.SUPABASE_SECRET_KEY}",
    }
    with httpx.Client(timeout=20.0) as client:
        response = client.get(
            f"{supabase_url}/auth/v1/admin/users",
            headers=headers,
            params={"page": 1, "per_page": 1000},
        )
    if response.status_code >= 400:
        return None

    body = response.json()
    users = body.get("users", []) if isinstance(body, dict) else []
    for user in users:
        if user.get("email", "").strip().lower() == email:
            return user.get("id")
    return None


def request_password_reset_otp(db: Session, email: str) -> dict:
    normalized_email = email.strip().lower()
    existing = crud.get_latest_password_reset_otp(db, normalized_email)
    now = _utcnow()

    if existing and existing.resend_available_at > now:
        seconds_left = int((existing.resend_available_at - now).total_seconds())
        raise HTTPException(
            status_code=429,
            detail=f"Please wait {seconds_left}s before requesting another OTP",
        )

    profile = crud.get_profile_by_email(db, normalized_email)
    user_id = profile.id if profile is not None else _get_supabase_user_id_by_email(normalized_email)
    if user_id is None:
        raise HTTPException(status_code=404, detail="No account found for this email")

    crud.delete_password_reset_otps(db, normalized_email)
    otp = f"{secrets.randbelow(1000000):06d}"
    expires_at = now + timedelta(minutes=settings.OTP_EXPIRY_MINUTES)
    resend_available_at = now + timedelta(seconds=settings.OTP_RESEND_COOLDOWN_SECONDS)

    crud.create_password_reset_otp(
        db,
        email=normalized_email,
        user_id=user_id,
        otp_hash=_hash_value(otp),
        expires_at=expires_at,
        resend_available_at=resend_available_at,
    )
    try:
        send_password_reset_otp_email(to_email=normalized_email, otp=otp)
    except RuntimeError as exc:
        crud.delete_password_reset_otps(db, normalized_email)
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    return {
        "email": normalized_email,
        "expires_in_seconds": settings.OTP_EXPIRY_MINUTES * 60,
        "resend_cooldown_seconds": settings.OTP_RESEND_COOLDOWN_SECONDS,
    }


def verify_password_reset_otp(db: Session, email: str, otp: str) -> dict:
    normalized_email = email.strip().lower()
    record = crud.get_latest_password_reset_otp(db, normalized_email)
    now = _utcnow()

    if record is None or record.completed_at is not None:
        raise HTTPException(status_code=400, detail="Invalid OTP")
    if record.expires_at < now:
        raise HTTPException(status_code=400, detail="OTP has expired")
    if record.verified_at is not None:
        raise HTTPException(status_code=400, detail="OTP already used")
    if record.otp_hash != _hash_value(otp):
        raise HTTPException(status_code=400, detail="Invalid OTP")

    reset_token = secrets.token_urlsafe(32)
    crud.save_password_reset_verification(
        db,
        record.id,
        verified_at=now,
        reset_token_hash=_hash_value(reset_token),
        reset_token_expires_at=now + timedelta(minutes=settings.PASSWORD_RESET_TOKEN_EXPIRE_MINUTES),
    )
    return {
        "email": normalized_email,
        "reset_token": reset_token,
        "expires_in_seconds": settings.PASSWORD_RESET_TOKEN_EXPIRE_MINUTES * 60,
    }


def reset_password(db: Session, email: str, reset_token: str, new_password: str) -> dict:
    normalized_email = email.strip().lower()
    record = crud.get_latest_password_reset_otp(db, normalized_email)
    now = _utcnow()

    if record is None or record.completed_at is not None:
        raise HTTPException(status_code=400, detail="Invalid or expired reset session")
    if record.verified_at is None or not record.reset_token_hash:
        raise HTTPException(status_code=400, detail="OTP verification required")
    if not record.reset_token_expires_at or record.reset_token_expires_at < now:
        raise HTTPException(status_code=400, detail="Reset session has expired")
    if record.reset_token_hash != _hash_value(reset_token):
        raise HTTPException(status_code=400, detail="Invalid reset session")

    _validate_strong_password(new_password)

    profile = crud.get_profile_by_email(db, normalized_email)
    user_id = str(profile.id) if profile is not None else _get_supabase_user_id_by_email(normalized_email)
    if user_id is None:
        raise HTTPException(status_code=404, detail="No account found for this email")

    supabase_url = settings.SUPABASE_URL.rstrip("/")
    headers = {
        "apikey": settings.SUPABASE_SECRET_KEY,
        "Authorization": f"Bearer {settings.SUPABASE_SECRET_KEY}",
        "Content-Type": "application/json",
    }
    with httpx.Client(timeout=20.0) as client:
        response = client.put(
            f"{supabase_url}/auth/v1/admin/users/{user_id}",
            headers=headers,
            json={"password": new_password},
        )
    if response.status_code >= 400:
        raise HTTPException(status_code=502, detail="Failed to update password in Supabase")

    crud.mark_password_reset_completed(db, record.id, now)
    crud.delete_password_reset_otps(db, normalized_email)
    return {"email": normalized_email, "message": "Password updated successfully"}
