from uuid import UUID

from sqlalchemy.orm import Session

from datetime import datetime

from database.models import (
    CropScan,
    HealthIndex,
    LivestockRec,
    PasswordResetOTP,
    Profile,
    ScanHistory,
    SyncQueue,
)


def get_profile_by_id(db: Session, user_id: UUID | str) -> Profile | None:
    return db.query(Profile).filter(Profile.id == user_id).first()


def get_profile_by_phone(db: Session, phone: str) -> Profile | None:
    return db.query(Profile).filter(Profile.phone == phone).first()


def upsert_profile(
    db: Session,
    user_id: UUID | str,
    name: str,
    language: str = "en",
    phone: str | None = None,
    email: str | None = None,
    region: str | None = None,
    is_active: bool = True,
) -> Profile:
    profile = get_profile_by_id(db, user_id)
    if profile is None:
        profile = Profile(
            id=user_id,
            name=name,
            phone=phone,
            email=email,
            language=language,
            region=region,
            is_active=is_active,
        )
        db.add(profile)
    else:
        profile.name = name
        profile.phone = phone
        profile.email = email
        profile.language = language
        profile.region = region
        profile.is_active = is_active

    db.commit()
    db.refresh(profile)
    return profile


def update_profile_feedback(
    db: Session,
    *,
    user_id: UUID | str,
    rating: int,
    feedback: str | None = None,
) -> Profile:
    profile = get_profile_by_id(db, user_id)
    if profile is None:
        raise ValueError("Profile not found")

    profile.app_rating = rating
    profile.app_feedback = feedback.strip() if feedback else None
    profile.app_feedback_updated_at = datetime.utcnow()
    db.commit()
    db.refresh(profile)
    return profile


def create_crop_scan(
    db: Session,
    user_id: UUID | str,
    disease: str,
    confidence: float,
    crop_type: str | None = None,
    severity: str | None = None,
    treatment: str | None = None,
    image_path: str | None = None,
) -> CropScan:
    scan = CropScan(
        user_id=user_id,
        disease=disease,
        confidence=confidence,
        crop_type=crop_type,
        severity=severity,
        treatment=treatment,
        image_path=image_path,
    )
    db.add(scan)
    db.commit()
    db.refresh(scan)
    return scan


def get_user_crop_scans(db: Session, user_id: UUID | str, limit: int = 20) -> list[CropScan]:
    return (
        db.query(CropScan)
        .filter(CropScan.user_id == user_id)
        .order_by(CropScan.created_at.desc())
        .limit(limit)
        .all()
    )


def create_livestock_rec(
    db: Session,
    user_id: UUID | str,
    animal_type: str,
    symptoms: str,
    disease: str | None = None,
    risk_level: str | None = None,
    treatment: str | None = None,
) -> LivestockRec:
    rec = LivestockRec(
        user_id=user_id,
        animal_type=animal_type,
        symptoms=symptoms,
        disease=disease,
        risk_level=risk_level,
        treatment=treatment,
    )
    db.add(rec)
    db.commit()
    db.refresh(rec)
    return rec


def create_health_index(
    db: Session,
    user_id: UUID | str,
    crop_score: float,
    soil_score: float,
    water_score: float,
    livestock_score: float,
    machinery_score: float,
    fhi_score: float,
) -> HealthIndex:
    record = HealthIndex(
        user_id=user_id,
        crop_score=crop_score,
        soil_score=soil_score,
        water_score=water_score,
        livestock_score=livestock_score,
        machinery_score=machinery_score,
        fhi_score=fhi_score,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def _parse_scan_ts(value: str | datetime | None) -> datetime:
    if isinstance(value, datetime):
        return value
    if isinstance(value, str) and value.strip():
        normalized = value.strip().replace("Z", "+00:00")
        try:
            return datetime.fromisoformat(normalized)
        except ValueError:
            pass
    return datetime.utcnow()


def create_or_update_scan_history(
    db: Session,
    *,
    user_id: UUID | str,
    scan_key: str,
    type: str,
    title: str,
    result: str | None = None,
    source: str | None = None,
    ts: str | datetime | None = None,
    payload: dict | None = None,
) -> ScanHistory:
    record = (
        db.query(ScanHistory)
        .filter(ScanHistory.user_id == user_id, ScanHistory.scan_key == scan_key)
        .first()
    )
    parsed_ts = _parse_scan_ts(ts)
    if record is None:
        record = ScanHistory(
            user_id=user_id,
            scan_key=scan_key,
            type=type,
            title=title,
            result=result,
            source=source,
            ts=parsed_ts,
            payload=payload or {},
        )
        db.add(record)
    else:
        record.type = type
        record.title = title
        record.result = result
        record.source = source
        record.ts = parsed_ts
        record.payload = payload or {}

    db.commit()
    db.refresh(record)
    return record


def get_user_scan_history(db: Session, user_id: UUID | str, limit: int = 200) -> list[ScanHistory]:
    return (
        db.query(ScanHistory)
        .filter(ScanHistory.user_id == user_id)
        .order_by(ScanHistory.ts.desc(), ScanHistory.id.desc())
        .limit(limit)
        .all()
    )


def get_latest_health_index(db: Session, user_id: UUID | str) -> HealthIndex | None:
    return (
        db.query(HealthIndex)
        .filter(HealthIndex.user_id == user_id)
        .order_by(HealthIndex.created_at.desc())
        .first()
    )


def add_to_sync_queue(db: Session, user_id: UUID | str, module: str, payload: dict) -> SyncQueue:
    item = SyncQueue(user_id=user_id, module=module, payload=payload)
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def get_pending_sync_items(db: Session, user_id: UUID | str) -> list[SyncQueue]:
    return (
        db.query(SyncQueue)
        .filter(SyncQueue.user_id == user_id, SyncQueue.synced.is_(False))
        .all()
    )


def mark_synced(db: Session, item_id: int) -> None:
    item = db.query(SyncQueue).filter(SyncQueue.id == item_id).first()
    if item is not None:
        item.synced = True
        db.commit()


def get_profile_by_email(db: Session, email: str) -> Profile | None:
    return db.query(Profile).filter(Profile.email == email).first()


def get_latest_password_reset_otp(
    db: Session,
    email: str,
    include_completed: bool = False,
) -> PasswordResetOTP | None:
    query = db.query(PasswordResetOTP).filter(PasswordResetOTP.email == email)
    if not include_completed:
        query = query.filter(PasswordResetOTP.completed_at.is_(None))
    return query.order_by(PasswordResetOTP.created_at.desc()).first()


def delete_password_reset_otps(db: Session, email: str) -> None:
    db.query(PasswordResetOTP).filter(PasswordResetOTP.email == email).delete()
    db.commit()


def create_password_reset_otp(
    db: Session,
    *,
    email: str,
    user_id,
    otp_hash: str,
    expires_at: datetime,
    resend_available_at: datetime,
) -> PasswordResetOTP:
    record = PasswordResetOTP(
        email=email,
        user_id=user_id,
        otp_hash=otp_hash,
        expires_at=expires_at,
        resend_available_at=resend_available_at,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def save_password_reset_verification(
    db: Session,
    record_id: int,
    *,
    verified_at: datetime,
    reset_token_hash: str,
    reset_token_expires_at: datetime,
) -> PasswordResetOTP | None:
    record = db.query(PasswordResetOTP).filter(PasswordResetOTP.id == record_id).first()
    if record is None:
        return None
    record.verified_at = verified_at
    record.reset_token_hash = reset_token_hash
    record.reset_token_expires_at = reset_token_expires_at
    db.commit()
    db.refresh(record)
    return record


def mark_password_reset_completed(db: Session, record_id: int, completed_at: datetime) -> None:
    record = db.query(PasswordResetOTP).filter(PasswordResetOTP.id == record_id).first()
    if record is None:
        return
    record.completed_at = completed_at
    db.commit()
