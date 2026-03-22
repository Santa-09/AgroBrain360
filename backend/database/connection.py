# backend/database/connection.py
import logging

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import declarative_base, sessionmaker

from config.settings import settings

log = logging.getLogger(__name__)

_engine: Engine | None = None
SessionLocal = sessionmaker(autocommit=False, autoflush=False)
Base = declarative_base()


def get_engine() -> Engine:
    global _engine
    if _engine is not None:
        return _engine

    database_url = settings.sqlalchemy_database_url
    if not database_url:
        raise RuntimeError("DATABASE_URL is not configured")

    _engine = create_engine(
        database_url,
        pool_pre_ping=True,
        pool_size=10,
        max_overflow=20,
    )
    SessionLocal.configure(bind=_engine)
    return _engine


def init_db() -> None:
    """Verify the configured database is reachable and ensure required tables/columns exist."""
    try:
        engine = get_engine()
        with engine.connect() as connection:
            connection.execute(text("select 1"))
        from database import models  # noqa: F401

        Base.metadata.create_all(bind=engine)
        with engine.begin() as connection:
            connection.execute(
                text(
                    """
                    alter table if exists profiles
                      add column if not exists app_rating integer,
                      add column if not exists app_feedback text,
                      add column if not exists app_feedback_updated_at timestamptz
                    """
                )
            )
            connection.execute(
                text(
                    """
                    do $$
                    begin
                      if not exists (
                        select 1
                        from pg_constraint
                        where conname = 'profiles_app_rating_check'
                      ) then
                        alter table profiles
                          add constraint profiles_app_rating_check
                          check (app_rating between 1 and 5 or app_rating is null);
                      end if;
                    end
                    $$;
                    """
                )
            )
        log.info("Database connection verified")
    except Exception as exc:
        if settings.is_production:
            raise RuntimeError(f"Database connection failed in production: {exc}") from exc
        log.warning("Database connection check skipped: %s", exc)


def get_db():
    """FastAPI dependency that yields a database session and always closes it."""
    engine = get_engine()
    SessionLocal.configure(bind=engine)
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
