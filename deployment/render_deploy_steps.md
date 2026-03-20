# Render Deployment Guide for AgroBrain360 Backend

This guide explains how to deploy the FastAPI backend in `backend/` to Render.

## What this deployment covers

- Backend framework: FastAPI
- Entry point: `backend/main.py`
- App object: `app`
- Recommended Render service type: Web Service
- Database expected by the backend: PostgreSQL
- Current mobile app production API URL: `https://agrobrain-backend.onrender.com`

## Before you start

Make sure you have:

1. A GitHub repository containing this project.
2. A Render account.
3. A PostgreSQL database connection string.
4. SMTP credentials if you want forgot-password email OTP to work.
5. The ML model files committed in this repository under `ml_models/`, because the backend loads models during startup.

## Important warnings before deployment

1. The repo currently contains hardcoded secrets in [settings.py](d:\AgroBrain360\backend\config\settings.py). Replace them with environment variables in Render.
2. If those secrets were real production secrets, rotate them before going live.
3. The backend loads ML models during startup. First deploy can take longer than a minimal FastAPI app.
4. TensorFlow and speech/LLM dependencies make the build heavier, so expect longer install times on Render.
## Step 1: Push the latest code

Commit and push your current code to GitHub so Render can pull it.

## Step 2: Create a new Web Service on Render

1. Log in to Render.
2. Click `New +`.
3. Choose `Web Service`.
4. Connect your GitHub account if needed.
5. Select the AgroBrain360 repository.

## Step 3: Fill in the Render service settings

Use these values:

- Name: `agrobrain-backend`
- Root Directory: `backend`
- Runtime: `Python 3`
- Python Version: `3.11.9`
- Build Command: `pip install -r requirements.txt`
- Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`

Why `backend` as the root directory:

- `requirements.txt` is inside `backend/`
- `main.py` is inside `backend/`
- `runtime.txt` is inside `backend/` and pins Python to `3.11.9`
- the import paths in the app are written relative to the `backend` folder

## Step 4: Add environment variables in Render

Create the environment variables listed in [environment_variables.md](d:\AgroBrain360\deployment\environment_variables.md).

At minimum, set:

- `DATABASE_URL`
- `SECRET_KEY`
- `ALLOWED_ORIGINS`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_LEGACY_ANON_JWT`
- `SUPABASE_SECRET_KEY`

Important for Supabase:

- Use the Supabase pooler connection string for `DATABASE_URL` on Render
- Avoid the direct database host `db.<project-ref>.supabase.co:5432` if Render logs show `Network is unreachable`
- The pooler URI is available in the Supabase dashboard under `Project Settings -> Database -> Connection string`

Add SMTP values too if you need password reset emails:

- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `SMTP_FROM_EMAIL`
- `SMTP_FROM_NAME`
- `SMTP_USE_TLS`

## Step 5: Deploy the service

1. Click `Create Web Service`.
2. Wait for Render to install dependencies.
3. Wait for the app to start.
4. Open the generated Render URL once the deploy succeeds.

## Step 6: Verify the backend after deployment

Open these endpoints in the browser or with Postman:

1. `https://YOUR-RENDER-URL/`
2. `https://YOUR-RENDER-URL/health`
3. `https://YOUR-RENDER-URL/docs`

Expected checks:

- `/` should return a JSON status payload
- `/health` should return `{"status":"ok"}`
- `/docs` should open FastAPI Swagger UI

## Step 7: Confirm database startup succeeds

The backend runs `init_db()` during startup from [connection.py](d:\AgroBrain360\backend\database\connection.py).

That means on startup it will:

1. Connect to PostgreSQL.
2. Create SQLAlchemy tables if needed.
3. Apply the `profiles` table column/constraint patch in code.

After deployment:

1. Open the Render logs.
2. Check that the service starts without database connection errors.
3. If startup fails, verify `DATABASE_URL` first.
4. If the logs show an IPv6 `Network is unreachable` error, replace the direct Supabase DB URL with the Supabase pooler URL.

## Step 8: Point the mobile app to the deployed backend

The Flutter app currently uses this production base URL in [api_constants.dart](d:\AgroBrain360\mobile_app\lib\core\constants\api_constants.dart):

- `https://agrobrain-backend.onrender.com`

If your Render service uses a different URL:

1. Update `ApiK.base`.
2. rebuild the APK or app bundle.

## Step 9: Test the main API flows

After deployment, test these important flows:

1. Login and profile endpoints.
2. Forgot password OTP request.
3. Crop recommendation.
4. Fertilizer prediction.
5. Livestock diagnosis.
6. Residue analysis.
7. Voice transcription.
8. LLM advice endpoint.

## Common Render issues and fixes

### Build fails during dependency install

Possible causes:

- large Python dependencies such as TensorFlow
- timeout during build
- incompatible Python version

What to do:

1. Retry the deploy once.
2. Check the exact failing package in logs.
3. Confirm the service `Root Directory` is set to `backend` so Render can read `backend/runtime.txt`.
4. If Render still selects a newer Python version, add `PYTHON_VERSION=3.11.9` in the service environment variables.

### Service starts but some AI features fail

Possible causes:

- model files missing from `ml_models/`
- insufficient memory
- optional local-only services not available in Render

What to do:

1. Confirm required model files exist in the repository.
2. Check startup logs for model loading failures.
3. Confirm `GROQ_API_KEY`, `ELEVENLABS_API_KEY`, and `VOICE_ID` are set in Render because voice features now depend on those managed APIs.

### Password reset emails fail

What to check:

1. `SMTP_HOST`
2. `SMTP_PORT`
3. `SMTP_USERNAME`
4. `SMTP_PASSWORD`
5. `SMTP_FROM_EMAIL`
6. Database connectivity, because OTP requests are also stored in PostgreSQL before the email is sent

### CORS errors from frontend

Set `ALLOWED_ORIGINS` to a comma-separated list that includes every frontend origin that should call the backend.

Example:

```env
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000,https://your-frontend-domain.com
```

## Recommended post-deployment checklist

1. Rotate any secrets that were previously committed to the repo.
2. Confirm `/health` responds successfully.
3. Confirm the mobile app can log in against production.
4. Test forgot-password end to end.
5. Watch Render logs for model-loading or memory errors.
6. Rebuild the mobile release if the backend URL changed.
