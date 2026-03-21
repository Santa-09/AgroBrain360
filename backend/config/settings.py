# backend/config/settings.py
from pathlib import Path
from typing import List

from pydantic import computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    BASE_DIR: Path = Path(__file__).resolve().parents[1]
    STATIC_DIR: Path = BASE_DIR / "static"
    DATABASE_URL: str = ""
    SUPABASE_DB_POOLER_URL: str = ""
    SECRET_KEY: str = "changeme"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    ALLOWED_ORIGINS: str | List[str] = "http://localhost:3000,http://localhost:8000"
    SUPABASE_URL: str = ""
    SUPABASE_ANON_KEY: str = ""
    SUPABASE_LEGACY_ANON_JWT: str = ""
    SUPABASE_SECRET_KEY: str = ""
    SUPABASE_JWT_AUDIENCE: str = "authenticated"
    OTP_EXPIRY_MINUTES: int = 5
    OTP_RESEND_COOLDOWN_SECONDS: int = 60
    PASSWORD_RESET_TOKEN_EXPIRE_MINUTES: int = 10
    SMTP_HOST: str | None = None
    SMTP_PORT: int = 587
    SMTP_USERNAME: str | None = None
    SMTP_PASSWORD: str | None = None
    SMTP_FROM_EMAIL: str | None = None
    SMTP_FROM_NAME: str = "AgroBrain 360"
    SMTP_USE_TLS: bool = True
    GROQ_API_KEY: str = ""
    GROQ_BASE_URL: str = "https://api.groq.com/openai/v1"
    GROQ_STT_MODEL: str = "whisper-large-v3"
    MODEL_NAME: str = "llama-3.1-8b-instant"
    COQUI_TTS_MODEL: str = "tts_models/en/vctk/vits"
    COQUI_TTS_SPEAKER: str = "p225"
    COQUI_TTS_PYTHON: str = ""
    APP_ENV: str = "development"
    PRELOAD_MODELS: bool = False

    model_config = SettingsConfigDict(
        env_file=(
            str(Path(__file__).resolve().parents[1] / ".env"),
            str(Path(__file__).resolve().parents[2] / ".env"),
        ),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @computed_field  # type: ignore[prop-decorator]
    @property
    def allowed_origins_list(self) -> List[str]:
        value = self.ALLOWED_ORIGINS
        if isinstance(value, list):
            return value
        return [item.strip() for item in value.split(",") if item.strip()]

    @property
    def is_production(self) -> bool:
        return self.APP_ENV.strip().lower() == "production"

    @property
    def sqlalchemy_database_url(self) -> str:
        value = (self.SUPABASE_DB_POOLER_URL or self.DATABASE_URL).strip()
        if value.startswith("postgres://"):
            value = "postgresql://" + value[len("postgres://") :]
        if value.startswith("postgresql://") and "sslmode=" not in value:
            separator = "&" if "?" in value else "?"
            value = f"{value}{separator}sslmode=require"
        return value

    def validate_production_config(self) -> None:
        if not self.is_production:
            return

        required_values = {
            "DATABASE_URL": self.SUPABASE_DB_POOLER_URL or self.DATABASE_URL,
            "SECRET_KEY": self.SECRET_KEY,
            "SUPABASE_URL": self.SUPABASE_URL,
            "SUPABASE_SECRET_KEY": self.SUPABASE_SECRET_KEY,
            "GROQ_API_KEY": self.GROQ_API_KEY,
            "SMTP_PASSWORD": self.SMTP_PASSWORD or "",
        }
        missing = [key for key, value in required_values.items() if not str(value).strip()]
        if missing:
            raise RuntimeError(
                "Missing required production configuration values: "
                + ", ".join(sorted(missing))
            )

        if self.SECRET_KEY == "changeme":
            raise RuntimeError("SECRET_KEY must not use the default placeholder in production")


settings = Settings()
