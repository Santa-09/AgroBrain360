import asyncio
import hashlib
import logging
import os
import subprocess
import threading
from pathlib import Path
from typing import Any

from config.settings import settings

log = logging.getLogger(__name__)

try:
    from TTS.api import TTS
except ImportError:
    TTS = None  # type: ignore[assignment]

_tts_model: Any = None
_tts_lock = threading.Lock()


class CoquiTTSServiceError(RuntimeError):
    pass


def _detect_gpu() -> bool:
    try:
        import torch

        return bool(torch.cuda.is_available())
    except Exception:
        return False


def _load_model() -> Any:
    if TTS is None:
        raise CoquiTTSServiceError(
            "Coqui TTS is not installed. Voice audio output is unavailable in this environment."
        )

    global _tts_model
    with _tts_lock:
        if _tts_model is None:
            _tts_model = TTS(
                model_name=settings.COQUI_TTS_MODEL,
                progress_bar=False,
                gpu=_detect_gpu(),
            )
        return _tts_model


def _worker_script_path() -> Path:
    return settings.BASE_DIR / "scripts" / "coqui_tts_worker.py"


def _external_python_path() -> Path | None:
    configured = (settings.COQUI_TTS_PYTHON or "").strip()
    if configured:
        candidate = Path(configured)
    else:
        candidate = settings.BASE_DIR / "tts_venv" / "Scripts" / "python.exe"
    return candidate if candidate.exists() else None


async def _run_external_tts(text: str, output_path: Path, *, preload_only: bool = False) -> None:
    python_path = _external_python_path()
    if python_path is None:
        raise CoquiTTSServiceError(
            "Coqui TTS is not installed. Set up backend/tts_venv or configure COQUI_TTS_PYTHON."
        )

    script_path = _worker_script_path()
    if not script_path.exists():
        raise CoquiTTSServiceError(f"Coqui worker script not found: {script_path}")

    cmd = [
        str(python_path),
        str(script_path),
        "--model",
        settings.COQUI_TTS_MODEL,
        "--speaker",
        settings.COQUI_TTS_SPEAKER,
        "--gpu",
        "1" if _detect_gpu() else "0",
    ]
    if preload_only:
        cmd.append("--preload")
    else:
        cmd.extend(["--text", text, "--output", str(output_path)])

    env = dict(os.environ)
    env.setdefault("PYTHONIOENCODING", "utf-8")
    user_profile = env.get("USERPROFILE") or str(Path.home())
    env.setdefault("LOCALAPPDATA", str(Path(user_profile) / "AppData" / "Local"))
    env.setdefault("APPDATA", str(Path(user_profile) / "AppData" / "Roaming"))
    tts_home = settings.BASE_DIR / "tts_cache"
    tts_home.mkdir(parents=True, exist_ok=True)
    env["TTS_HOME"] = str(tts_home)
    completed = await asyncio.to_thread(
        subprocess.run,
        cmd,
        capture_output=True,
        text=True,
        env=env,
        check=False,
    )
    if completed.returncode != 0:
        detail = (completed.stderr or completed.stdout).strip()
        raise CoquiTTSServiceError(detail or "External Coqui TTS process failed")


def preload() -> None:
    try:
        if TTS is not None:
            _load_model()
            return
        if _external_python_path() is not None:
            log.info("Coqui TTS external worker detected and will load on first synthesis request.")
            return
        raise CoquiTTSServiceError(
            "Coqui TTS is not installed. Set up backend/tts_venv or configure COQUI_TTS_PYTHON."
        )
    except CoquiTTSServiceError as exc:
        log.warning("Skipping Coqui TTS preload: %s", exc)


def _speaker_kwargs(tts: Any) -> dict[str, str]:
    speakers = getattr(tts, "speakers", None) or []
    if not speakers:
        return {}

    configured = (settings.COQUI_TTS_SPEAKER or "").strip()
    speaker = configured if configured in speakers else speakers[0]
    return {"speaker": speaker}


def _synthesize_to_file(text: str, output_path: Path) -> None:
    if not text.strip():
        raise CoquiTTSServiceError("Text input for TTS cannot be empty")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    tts = _load_model()
    kwargs = _speaker_kwargs(tts)
    tts.tts_to_file(text=text, file_path=str(output_path), **kwargs)


async def text_to_speech(text: str) -> dict[str, str]:
    if not text.strip():
        raise CoquiTTSServiceError("Text input for TTS cannot be empty")

    voice_dir = settings.STATIC_DIR / "voice"
    digest = hashlib.sha1(
        f"{settings.COQUI_TTS_MODEL}|{settings.COQUI_TTS_SPEAKER}|{text}".encode(
            "utf-8"
        )
    ).hexdigest()
    output_path = voice_dir / f"{digest}.wav"

    if not output_path.exists():
        if TTS is not None:
            await asyncio.to_thread(_synthesize_to_file, text, output_path)
        else:
            await _run_external_tts(text, output_path)

    return {
        "path": str(output_path),
        "filename": output_path.name,
        "audio_url": f"/static/voice/{output_path.name}",
    }
