# GitHub Push Guide for AgroBrain360

Use this checklist before pushing the project to GitHub.

## What should not be committed

- `backend/.env`
- any rotated secret files
- `mobile_app/android/key.properties`
- any `.jks` or `.keystore` file
- `mobile_app/build/`
- `backend/static/voice/`
- local database or cache files

The root [.gitignore](d:\AgroBrain360\.gitignore) is configured for these already.

## Safe push steps

1. Initialize git if this folder is not already a repository:

```powershell
cd d:\AgroBrain360
git init
```

2. Add the remote:

```powershell
git remote add origin https://github.com/YOUR_USERNAME/AgroBrain360.git
```

3. Review files before staging:

```powershell
git status
```

4. Stage everything safe:

```powershell
git add .
```

5. Confirm secrets are not staged:

```powershell
git status
```

6. Create the first commit:

```powershell
git commit -m "Prepare AgroBrain360 for production deployment"
```

7. Push to GitHub:

```powershell
git branch -M main
git push -u origin main
```

## Final check before public push

Rotate these if they were ever committed previously:

- database credentials
- SMTP credentials
- `GROQ_API_KEY`
- `ELEVENLABS_API_KEY`
- Supabase service credentials
