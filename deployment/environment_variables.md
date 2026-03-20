# Environment Variables for AgroBrain360 Backend

This file lists the environment variables used by the FastAPI backend in [settings.py](d:\AgroBrain360\backend\config\settings.py).

## Required variables

Set these in Render before production deployment.

```env
DATABASE_URL=postgresql://USER:PASSWORD@HOST:5432/DATABASE
SECRET_KEY=replace-with-a-long-random-secret
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000,https://your-frontend-domain.com
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_LEGACY_ANON_JWT=your-supabase-legacy-anon-jwt
SUPABASE_SECRET_KEY=your-supabase-service-role-or-secret-key
```

## Optional but recommended variables

These already have defaults in code, but you can still set them explicitly.

```env
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
SUPABASE_JWT_AUDIENCE=authenticated
OTP_EXPIRY_MINUTES=5
OTP_RESEND_COOLDOWN_SECONDS=60
PASSWORD_RESET_TOKEN_EXPIRE_MINUTES=10
```

## Email / SMTP variables

Set these if you want forgot-password OTP email delivery to work.

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@example.com
SMTP_PASSWORD=your-app-password-or-smtp-password
SMTP_FROM_EMAIL=your-email@example.com
SMTP_FROM_NAME=AgroBrain 360
SMTP_USE_TLS=true
```

If SMTP values are missing, the email service will not work.

## Optional AI service variables

The backend also defines these variables:

```env
OLLAMA_BASE_URL=http://127.0.0.1:11434
OLLAMA_MODEL=gemma2:2b
WHISPER_MODEL_SIZE=small
WHISPER_DEVICE=cpu
WHISPER_COMPUTE_TYPE=int8
```

Notes:

1. `OLLAMA_BASE_URL=http://127.0.0.1:11434` only works if Ollama is running on the same machine as the backend.
2. On Render, a local Ollama service usually will not exist unless you build a separate compatible setup.
3. `faster-whisper` settings are safe to keep on CPU unless you have a different runtime environment.

## What each variable does

- `DATABASE_URL`: PostgreSQL connection string used by SQLAlchemy.
- `SECRET_KEY`: used for password reset tokens and other signed security flows.
- `ALLOWED_ORIGINS`: comma-separated list of allowed frontend origins for CORS.
- `SUPABASE_URL`: Supabase project base URL.
- `SUPABASE_ANON_KEY`: public client key used in some auth flows.
- `SUPABASE_LEGACY_ANON_JWT`: legacy anon JWT fallback used by the app.
- `SUPABASE_SECRET_KEY`: privileged Supabase key used by backend server-side operations.
- `SUPABASE_JWT_AUDIENCE`: expected JWT audience.
- `SMTP_*`: SMTP configuration for email delivery.
- `OLLAMA_*`: local or remote Ollama model service settings.
- `WHISPER_*`: speech-to-text runtime behavior.

## Production example

```env
DATABASE_URL=postgresql://postgres:strong-password@db.example.supabase.co:5432/postgres
SECRET_KEY=9f2c9a6f0d9848f0b2b2a1d4ef1d6b4f6f0e6e3a8a11b5e1
ALLOWED_ORIGINS=https://agrobrain-web.example.com
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=sb_publishable_xxxxx
SUPABASE_LEGACY_ANON_JWT=eyJhbGciOi...
SUPABASE_SECRET_KEY=sb_secret_xxxxx
SUPABASE_JWT_AUDIENCE=authenticated
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=agrobrain@example.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_EMAIL=agrobrain@example.com
SMTP_FROM_NAME=AgroBrain 360
SMTP_USE_TLS=true
OLLAMA_MODEL=gemma2:2b
WHISPER_MODEL_SIZE=small
WHISPER_DEVICE=cpu
WHISPER_COMPUTE_TYPE=int8
```

## Security notes

1. Do not commit real production secrets into Git.
2. Do not keep real `DATABASE_URL`, `SUPABASE_SECRET_KEY`, or `SECRET_KEY` values hardcoded in source files.
3. If secrets were already committed, rotate them before production use.
4. Store production secrets only in Render environment variables or another secure secret manager.
