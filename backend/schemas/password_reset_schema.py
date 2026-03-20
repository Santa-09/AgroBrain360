from pydantic import BaseModel, EmailStr, Field


class PasswordResetRequestOTP(BaseModel):
    email: EmailStr


class PasswordResetVerifyOTP(BaseModel):
    email: EmailStr
    otp: str = Field(..., min_length=6, max_length=6)


class PasswordResetConfirm(BaseModel):
    email: EmailStr
    reset_token: str = Field(..., min_length=20)
    new_password: str = Field(..., min_length=8)
