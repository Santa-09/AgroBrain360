# 🌾 AgroBrain360

> **AI-powered farm intelligence — offline-first, voice-enabled, built for the field.**

AgroBrain360 is a hybrid offline-first platform that gives farmers practical digital tools for crop care, livestock health, machinery support, residue monetization, hyperlocal services, and a unified Farm Health Index — all from a single mobile app.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform: Android](https://img.shields.io/badge/Platform-Android-blue.svg)]()
[![Backend: FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688.svg)]()
[![Flutter](https://img.shields.io/badge/Mobile-Flutter-02569B.svg)]()

---

## Table of Contents

- [Project Vision](#project-vision)
- [Key Features](#key-features)
- [Modules](#modules)
- [Architecture Overview](#architecture-overview)
- [Technology Stack](#technology-stack)
- [Offline-First Design](#offline-first-design)
- [Machine Learning Models](#machine-learning-models)
- [Database Overview](#database-overview)
- [Backend API Overview](#backend-api-overview)
- [Supported Languages](#supported-languages)
- [Repository Structure](#repository-structure)
- [Setup Guide](#setup-guide)
- [Environment Variables](#environment-variables)
- [Running the Project](#running-the-project)
- [Deployment](#deployment)
- [Future Scope](#future-scope)
- [License](#license)

---

## Project Vision

AgroBrain360 is designed for rural and semi-rural farming workflows where connectivity is weak, expert access is limited, and users may prefer voice and regional language interaction over text-heavy interfaces.

The platform gives farmers **one place** to:

- Detect crop diseases from leaf images
- Get crop and fertilizer recommendations
- Assess livestock health
- Estimate machinery needs and maintenance urgency
- Analyze crop residue for income opportunities
- Find nearby agricultural services
- Monitor a unified Farm Health Index
- Save activity locally and sync it later
- Ask AI questions with full voice support

---

## Key Features

### 🔌 Offline-First Mobile Experience
Core app flows work with poor or no internet. On-device AI handles crop, fertilizer, livestock, and recommendation workflows. Scan history, Farm Health Index, and sync queue are stored locally, with automatic background sync when connectivity returns.

### 🌿 AI-Powered Crop Intelligence
- Crop disease detection from leaf images
- Crop detection scan mode
- Crop recommendation from soil and environmental inputs (NPK, pH, rainfall, humidity, temperature)
- Fertilizer recommendation with ranked suggestions
- Confidence-driven result screens with treatment and advisory context

### 🛡️ Smart Image Validation
Images are validated before any prediction. The system rejects blurry, too dark, too bright, or low-quality inputs, and uses model confidence rules to prevent unreliable results from unrelated images.

### 🐄 Livestock Health Support
- Image-assisted livestock disease screening
- Symptom-based diagnosis workflow
- Rule-based fallback when model confidence is low
- Risk scoring, first-response care guidance, and nearest vet suggestions

### 🚜 Machinery Assistance
- Machine recommendation by crop type and land size
- Maintenance risk scoring based on service date and usage
- Operating cost estimation and nearby rental discovery
- AR-style guided repair flow with voice notes and AI advisory

### 🌾 Residue Income Analysis
- Crop residue analysis from photo and residue type
- Moisture-aware quantity estimation
- Best income option recommendation with projected earnings
- Voice-assisted residue note capture

### 📍 Hyperlocal Service Discovery
Locate nearby vets, input dealers, repair centers, and mandis — with category filtering, search, and distance sorting. Offline fallback uses bundled local service data.

### 📊 Farm Health Index
Combines crop, soil, water, livestock, and machinery sub-scores into a single farm score. Results are saved locally and remotely and feed the dashboard and notifications.

### 🎙️ Voice & AI Assistant
- Speech-to-text for field input; text-to-speech for response playback
- Backend voice pipeline (Whisper-style transcription)
- Case-based AI help center with session message history
- Realtime cloud-assisted advisory via LLM routes

### 👤 Account, Profile & Recovery
- Supabase-backed login, signup, and language preference management
- Forgot password flow with OTP request, verification, and reset
- Profile sync with local persistence and remote history restoration

---

## Modules

| Module | Description |
|---|---|
| **Crop** | Disease detection, crop recommendation, fertilizer recommendation |
| **Livestock** | Symptom entry, image upload, offline/cloud diagnosis, risk scoring |
| **Machinery** | Recommendation, maintenance assessment, repair guide, rental discovery |
| **Residue** | Residue photo analysis, earning projections, reuse suggestions |
| **Services** | Vet, input dealer, repair shop, and mandi discovery |
| **Farm Health** | Overall farm score, sub-scores, dashboard integration |
| **AI Help Center** | Case-based Q&A, voice input, cloud-assisted advisory |

---

## Architecture Overview

```
Flutter Mobile App
  ├── On-device TFLite models
  ├── Hive local storage
  ├── Offline session + sync queue
  ├── Voice input / TTS
  └── Weather + location
          │
          ▼
FastAPI Backend
  ├── Auth / profile APIs
  ├── Crop / livestock / fertilizer / residue / health / services APIs
  ├── Sync + history restore APIs
  ├── Voice transcription + module voice pipeline
  └── LLM advisory + AI case chat
          │
          ▼
Supabase / PostgreSQL
  ├── profiles
  ├── crop_scans
  ├── livestock_recs
  ├── health_index
  └── sync_queue
```

---

## Technology Stack

### Mobile App
| Package | Purpose |
|---|---|
| Flutter | Cross-platform Android-first UI |
| Hive | Local offline storage |
| Supabase Flutter | Auth and remote sync |
| TFLite Flutter | On-device model inference |
| Geolocator | Location for weather and services |
| Speech to Text / Flutter TTS | Voice input and playback |

### Backend
| Package | Purpose |
|---|---|
| FastAPI + Uvicorn | API server |
| SQLAlchemy + PostgreSQL | ORM and database |
| TensorFlow / Scikit-learn | Cloud-side model inference |
| Pillow | Image processing |
| Pydantic Settings | Config management |

### AI / ML
- TensorFlow / Keras and TensorFlow Lite
- Scikit-learn pipelines with rule-based fallbacks
- Groq-backed cloud voice and LLM flows
- ElevenLabs-backed voice output

---

## Offline-First Design

Offline-first behavior is a core architectural commitment, not an afterthought.

**Local storage handles:**
- User session and profile snapshot
- Scan history and sync queue
- Latest Farm Health Index
- Notification read and dismissed state

**Offline capabilities:**
- Local user session fallback
- On-device model inference (no network required)
- History-first UI behavior
- Background sync when internet returns
- Remote history restore after login

---

## Machine Learning Models

| Model | Location | Purpose |
|---|---|---|
| Crop Disease Detection | `ml_models/crop_disease/` | Disease detection from leaf images |
| Crop Recommendation | `ml_models/crop_recommendation/` | Recommend crop from soil/env inputs |
| Fertilizer Recommendation | `ml_models/fertilizer_recommendation/` | Fertilizer suggestions by crop and soil |
| Livestock Classification | `ml_models/livestock/` | Livestock disease prediction |
| Intent Detection | `ml_models/intent_detection/` | Voice and intent routing |

- Backend loads models at startup
- Mobile app uses bundled TFLite models for offline inference
- Some workflows fall back to heuristics or rule logic if needed

---

## Database Overview

| Table | Description |
|---|---|
| `profiles` | User accounts and preferences |
| `crop_scans` | Crop disease and recommendation records |
| `livestock_recs` | Livestock diagnosis records |
| `health_index` | Farm Health Index snapshots |
| `sync_queue` | Queued records pending sync |

**Database features:** row-level security (RLS), profile auto-create trigger from `auth.users`, indexed scan and health tables, sync-ready record structure.

---

## Backend API Overview

### Root and Health
```
GET  /
GET  /health
```

### Auth and Profile
```
POST  /auth/profile
GET   /auth/profile/me
POST  /auth/profile/feedback
POST  /auth/forgot-password/request-otp
POST  /auth/forgot-password/verify-otp
POST  /auth/forgot-password/reset
```

### Crop and Fertilizer
```
POST  /crop/predict
POST  /crop/recommend
POST  /fertilizer/predict
```

### Livestock
```
POST  /livestock/diagnose
```

### Residue
```
POST  /residue/analyze
GET   /residue/crops
GET   /residue/recommendations/{crop}
GET   /residue/recommendations/{crop}/{option_id}
GET   /residue/schemes
```

### Farm Health Index
```
POST  /health/score
GET   /health/score/latest
```

### Services
```
GET  /services/nearby
```

### Voice and AI
```
POST  /voice
POST  /voice/transcribe
POST  /chat/case
POST  /llm/advise
POST  /llm/realtime/session
```

### Sync
```
POST  /sync
POST  /sync/history
GET   /sync/history
```

> **Swagger UI:** `http://127.0.0.1:8000/docs`

---

## Supported Languages

| Code | Language |
|---|---|
| `en` | English |
| `hi` | Hindi |
| `od` | Odia |
| `ta` | Tamil |
| `te` | Telugu |

---

## Repository Structure

```
AgroBrain360/
├── backend/              FastAPI backend — routes, services, schemas, config
├── mobile_app/           Flutter app
├── ml_models/            Trained models, TFLite exports, training scripts
├── database/             Supabase schema, seed SQL, ER diagram
├── deployment/           Render and environment setup docs
├── docs/                 API docs, user flow, architecture, presentation assets
├── datasets/             Training and reference datasets
├── render.yaml           Render deployment config
└── AGRIBRAIN360_BLUEPRINT.md   Full product blueprint and extended scope
```

---

## Setup Guide

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd AgroBrain360
```

### 2. Backend setup

```bash
cd backend
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # macOS / Linux
pip install -r requirements.txt
copy .env.example .env       # then fill in your credentials
```

### 3. Database setup

Create a Supabase/PostgreSQL project, then apply:

```bash
# Apply schema
psql -f database/supabase_schema.sql

# Optional seed data
psql -f database/seed_data.sql
```

### 4. Mobile app setup

```bash
cd mobile_app
flutter pub get
```

To use a local backend instead of the hosted one:

```bash
flutter run \
  --dart-define=USE_LOCAL_API=true \
  --dart-define=API_LOCAL_URL=http://10.0.2.2:8000
```

---

## Environment Variables

Create `backend/.env` from `.env.example` and fill in the following:

```env
# App
APP_ENV=development
SECRET_KEY=replace_with_a_long_random_secret
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000

# Database
DATABASE_URL=postgresql://user:password@host:5432/database

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SECRET_KEY=your_supabase_service_role_key

# Email (OTP)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your_email@example.com
SMTP_PASSWORD=your_smtp_password

# AI Services
GROQ_API_KEY=your_groq_api_key
ELEVENLABS_API_KEY=your_elevenlabs_api_key
VOICE_ID=your_voice_id
```

See also:
- `backend/.env.example`
- `deployment/environment_variables.md`

---

## Running the Project

### Backend

```bash
cd backend
uvicorn main:app --reload
```

Available at: `http://127.0.0.1:8000`
Swagger docs: `http://127.0.0.1:8000/docs`

### Mobile App

```bash
cd mobile_app
flutter run
```

---

## Deployment

The repository includes a ready-to-use Render configuration in `render.yaml`.

| Setting | Value |
|---|---|
| Platform | Render |
| Service type | Python web service |
| Root directory | `backend` |
| Start command | `uvicorn main:app --host 0.0.0.0 --port $PORT` |

**Deployment docs included in the repo:**

- `deployment/render_deploy_steps.md`
- `deployment/environment_variables.md`
- `deployment/build_release_apk.md`
- `deployment/github_push_steps.md`

---

## Documentation

| File | Description |
|---|---|
| `AGRIBRAIN360_BLUEPRINT.md` | Full product blueprint and feature vision |
| `docs/api_documentation.md` | API endpoint notes |
| `docs/system_architecture.png` | Architecture visual |
| `docs/user_flow.png` | User journey diagram |
| `docs/problem_statement.pdf` | Problem framing |
| `docs/pitch_script.txt` | Demo/pitch support material |

---

## Future Scope

- Admin dashboards and richer analytics
- Improved AR machinery guidance
- More regional service data
- Weather-aware and district-aware advisories
- Community outbreak reporting and alerts
- Additional models for pests, yield, and soil insights
- Model monitoring and drift detection

---

## License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.#
