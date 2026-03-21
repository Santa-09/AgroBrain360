# AgroBrain360 Mobile App

This mobile app is now configured to run against the local backend by default.

## Current Local Setup

- default API root: `http://10.0.2.2:8000`
- `USE_LOCAL_API`: enabled by default in code
- production Render URL is no longer the default path

## Run Locally

### Android Emulator

Use:

```bash
flutter run
```

The app will call:

```text
http://10.0.2.2:8000
```

### Physical Android Device

If you run on a real device, replace `10.0.2.2` with your computer's LAN IP:

```bash
flutter run --dart-define=API_LOCAL_URL=http://YOUR_PC_IP:8000 --dart-define=USE_LOCAL_API=true
```

Example:

```bash
flutter run --dart-define=API_LOCAL_URL=http://192.168.1.5:8000 --dart-define=USE_LOCAL_API=true
```

## File Controlling This

- `lib/core/constants/api_constants.dart`

## Notes

- Supabase auth is still used by the app.
- The backend should be running locally on port `8000`.
- For emulator use, `10.0.2.2` is correct.
- For a real phone, use your machine's local IP.
