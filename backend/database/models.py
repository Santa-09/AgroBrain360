from datetime import datetime
from uuid import UUID as UUIDType

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Index, Integer, String, Text, text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database.connection import Base


class Profile(Base):
    __tablename__ = "profiles"

    id: Mapped[UUIDType] = mapped_column(UUID(as_uuid=True), primary_key=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(15), unique=True, index=True, nullable=True)
    email: Mapped[str | None] = mapped_column(String(150), unique=True, index=True, nullable=True)
    language: Mapped[str] = mapped_column(String(5), server_default=text("'en'"))
    region: Mapped[str | None] = mapped_column(String(100), nullable=True)
    app_rating: Mapped[int | None] = mapped_column(Integer, nullable=True)
    app_feedback: Mapped[str | None] = mapped_column(Text, nullable=True)
    app_feedback_updated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=text("now()"))
    is_active: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))

    crop_scans: Mapped[list["CropScan"]] = relationship(back_populates="profile")
    livestock_recs: Mapped[list["LivestockRec"]] = relationship(back_populates="profile")
    health_indices: Mapped[list["HealthIndex"]] = relationship(back_populates="profile")
    scan_history: Mapped[list["ScanHistory"]] = relationship(back_populates="profile")
    sync_queue: Mapped[list["SyncQueue"]] = relationship(back_populates="profile")


class CropScan(Base):
    __tablename__ = "crop_scans"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[UUIDType] = mapped_column(UUID(as_uuid=True), ForeignKey("profiles.id"), nullable=False)
    disease: Mapped[str] = mapped_column(String(100), nullable=False)
    confidence: Mapped[float] = mapped_column(Float, nullable=False)
    crop_type: Mapped[str | None] = mapped_column(String(100), nullable=True)
    severity: Mapped[str | None] = mapped_column(String(20), nullable=True)
    treatment: Mapped[str | None] = mapped_column(Text, nullable=True)
    image_path: Mapped[str | None] = mapped_column(Text, nullable=True)
    synced: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=text("now()"))

    profile: Mapped[Profile] = relationship(back_populates="crop_scans")


class LivestockRec(Base):
    __tablename__ = "livestock_recs"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[UUIDType] = mapped_column(UUID(as_uuid=True), ForeignKey("profiles.id"), nullable=False)
    animal_type: Mapped[str] = mapped_column(String(50), nullable=False)
    symptoms: Mapped[str] = mapped_column(Text, nullable=False)
    disease: Mapped[str | None] = mapped_column(String(100), nullable=True)
    risk_level: Mapped[str | None] = mapped_column(String(20), nullable=True)
    treatment: Mapped[str | None] = mapped_column(Text, nullable=True)
    synced: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=text("now()"))

    profile: Mapped[Profile] = relationship(back_populates="livestock_recs")


class HealthIndex(Base):
    __tablename__ = "health_index"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[UUIDType] = mapped_column(UUID(as_uuid=True), ForeignKey("profiles.id"), nullable=False)
    crop_score: Mapped[float] = mapped_column(Float, nullable=False)
    soil_score: Mapped[float] = mapped_column(Float, nullable=False)
    water_score: Mapped[float] = mapped_column(Float, nullable=False)
    livestock_score: Mapped[float] = mapped_column(Float, nullable=False)
    machinery_score: Mapped[float] = mapped_column(Float, nullable=False)
    fhi_score: Mapped[float] = mapped_column(Float, nullable=False)
    synced: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=text("now()"))

    profile: Mapped[Profile] = relationship(back_populates="health_indices")


class ScanHistory(Base):
    __tablename__ = "scan_history"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[UUIDType] = mapped_column(UUID(as_uuid=True), ForeignKey("profiles.id"), nullable=False)
    scan_key: Mapped[str] = mapped_column(String(120), nullable=False)
    type: Mapped[str] = mapped_column(String(50), nullable=False)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    result: Mapped[str | None] = mapped_column(String(200), nullable=True)
    source: Mapped[str | None] = mapped_column(String(50), nullable=True)
    payload: Mapped[dict] = mapped_column(JSONB, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=text("now()"))
    ts: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=text("now()"))

    profile: Mapped[Profile] = relationship(back_populates="scan_history")


class SyncQueue(Base):
    __tablename__ = "sync_queue"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[UUIDType] = mapped_column(UUID(as_uuid=True), ForeignKey("profiles.id"), nullable=False)
    module: Mapped[str] = mapped_column(String(50), nullable=False)
    payload: Mapped[dict] = mapped_column(JSONB, nullable=False)
    synced: Mapped[bool] = mapped_column(Boolean, server_default=text("false"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=text("now()"))

    profile: Mapped[Profile] = relationship(back_populates="sync_queue")


class PasswordResetOTP(Base):
    __tablename__ = "password_reset_otps"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(150), index=True, nullable=False)
    user_id: Mapped[UUIDType | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("profiles.id"), nullable=True
    )
    otp_hash: Mapped[str] = mapped_column(String(128), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    resend_available_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    reset_token_hash: Mapped[str | None] = mapped_column(String(128), nullable=True)
    reset_token_expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=text("now()"))


Index("idx_password_reset_otps_email", PasswordResetOTP.email)


Index("idx_crop_scans_user_id", CropScan.user_id)
Index("idx_livestock_recs_user_id", LivestockRec.user_id)
Index("idx_health_index_user_id", HealthIndex.user_id)
Index("idx_scan_history_user_id", ScanHistory.user_id)
Index("idx_scan_history_user_id_scan_key", ScanHistory.user_id, ScanHistory.scan_key, unique=True)
Index("idx_sync_queue_user_id", SyncQueue.user_id)
