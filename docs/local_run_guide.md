# Local Run Guide

This guide runs the current AgroBrain360 project locally with the FastAPI backend and Flutter mobile app wired together.

## Project Structure

```text
AgroBrain360/
|-- backend/        FastAPI backend, auth, ML, sync, voice, chat
|-- mobile_app/     Flutter Android app
|-- ml_models/      Trained models used by backend and app
|-- database/       Database schema and SQL assets
|-- docs/           Project documentation
```

## What Must Be Available

- Python virtual environment inside `backend/venv`
- Flutter SDK installed
- Android emulator or real Android device
- Working values in `backend/.env`

## Backend Setup

From repo root:

```powershell
cd d:\AgroBrain360\backend
venv\Scripts\pip.exe install -r requirements.txt
```

## Backend Environment

The backend reads:

- `backend/.env`
- repo-root `.env` if present

For local development use:

```env
APP_ENV=development
PRELOAD_MODELS=false
```

`PRELOAD_MODELS=false` keeps startup fast locally. Models load on first request instead.

## Start Backend

From `backend`:

```powershell
venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Check it:

```powershell
Invoke-WebRequest -Uri "http://127.0.0.1:8000/health" -UseBasicParsing
Invoke-WebRequest -Uri "http://127.0.0.1:8000/docs" -UseBasicParsing
```

## Mobile App Setup

From repo root:

```powershell
cd d:\AgroBrain360\mobile_app
flutter pub get
```

## Run Mobile App

### Android emulator

```powershell
flutter run
```

The app uses:

```text
http://10.0.2.2:8000
```

### Real Android device

Use your PC LAN IP:

```powershell
flutter run --dart-define=USE_LOCAL_API=true --dart-define=API_LOCAL_URL=http://YOUR_PC_IP:8000
```

Example:

```powershell
flutter run --dart-define=USE_LOCAL_API=true --dart-define=API_LOCAL_URL=http://192.168.1.5:8000
```

## Full Local Run Order

Open terminal 1:

```powershell
cd d:\AgroBrain360\backend
venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Open terminal 2:

```powershell
cd d:\AgroBrain360\mobile_app
flutter pub get
flutter run
```

## Features Expected To Work

- Auth and profile sync against Supabase-backed auth flow used by the app
- Crop disease prediction
- Crop recommendation
- Fertilizer recommendation
- Livestock diagnosis
- Residue analysis
- Farm Health Index
- Nearby services
- Offline sync endpoints
- AI case chat
- Voice transcription and voice pipeline, if AI keys are valid
- Offline TTS for AI voice replies, only when Coqui TTS is installed in a separate compatible environment

## Important Local Notes

- Emulator uses `10.0.2.2`, not `127.0.0.1`
- Real devices must use your computer IP address
- For real devices, the backend must be started with `--host 0.0.0.0`
- Chat and voice features require valid `GROQ_API_KEY`
- TTS voice output is optional. If Coqui TTS is not installed, the voice pipeline still returns text and skips audio generation.
- Password reset OTP requires valid SMTP settings
- Database-backed features require a reachable Postgres/Supabase database

## Offline Coqui TTS

The default backend setup no longer installs Coqui TTS because `TTS==0.22.0`
conflicts with the app's pinned `pandas==2.2.2`.

Without Coqui installed:

- the backend starts normally
- `/voice` still returns transcription and AI text
- `audio_url` is omitted and `tts_error` explains why

If you still want offline TTS locally, install it in a separate compatible
environment after relaxing the conflicting dependency pins.

Base backend dependencies:

```powershell
cd d:\AgroBrain360\backend
venv\Scripts\pip.exe install -r requirements.txt
```

The backend now uses offline Coqui TTS with:

```env
COQUI_TTS_MODEL=tts_models/en/vctk/vits
COQUI_TTS_SPEAKER=p225
```

Generated voice files are saved under:

```text
backend/static/voice/
```

Example backend usage:

```python
from services.coqui_tts_service import text_to_speech

result = await text_to_speech("Spray Mancozeb every seven days.")
print(result["audio_url"])
```

## Optional Production-Like Startup

If you want production-style warm startup later:

```env
APP_ENV=production
PRELOAD_MODELS=true
```

Only do that after production secrets are properly rotated and validated.
