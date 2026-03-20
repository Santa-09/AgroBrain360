from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class ProfileUpsertRequest(BaseModel):
    name: str
    language: str = "en"
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    region: Optional[str] = None
    is_active: bool = True


class ProfileResponse(BaseModel):
    user_id: UUID
    name: str
    language: str
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    region: Optional[str] = None
    is_active: bool
    app_rating: Optional[int] = None
    app_feedback: Optional[str] = None
    app_feedback_updated_at: Optional[datetime] = None


class ProfileFeedbackRequest(BaseModel):
    rating: int = Field(..., ge=1, le=5)
    feedback: Optional[str] = Field(default=None, max_length=1000)
