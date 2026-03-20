# backend/main.py
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from config.settings import settings
from utils.error_handler import register_error_handlers
from routes.auth_routes import router as auth_router
from routes.crop_routes import router as crop_router
from routes.fertilizer_routes import router as fertilizer_router
from routes.livestock_routes import router as livestock_router
from routes.residue_routes import router as residue_router
from routes.health_routes import router as health_router
from routes.chat_routes import router as chat_router
from routes.llm_routes import router as llm_router
from routes.sync_routes import router as sync_router
from routes.service_routes import router as service_router
from routes.voice_route import router as voice_router
from services.ml_service import load_all_models
from database.connection import init_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load ML models once when the API starts."""
    settings.validate_production_config()
    init_db()
    load_all_models()
    yield

app = FastAPI(
    title="AgroBrain360 API",
    version="1.0.0",
    description="Hybrid Offline-First 5-in-1 AI Farm Intelligence Platform",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

register_error_handlers(app)
settings.STATIC_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/static", StaticFiles(directory=settings.STATIC_DIR), name="static")

# Include all routers
app.include_router(auth_router)
app.include_router(crop_router)
app.include_router(fertilizer_router)
app.include_router(livestock_router)
app.include_router(residue_router)
app.include_router(health_router)
app.include_router(chat_router)
app.include_router(llm_router)
app.include_router(sync_router)
app.include_router(service_router)
app.include_router(voice_router)


@app.get("/", tags=["Root"])
def root():
    return {"status": "AgroBrain360 API running", "version": "1.0.0"}


@app.get("/health", tags=["Root"])
def health_check():
    return {"status": "ok"}
