# Build Release APK Guide for AgroBrain360

This guide explains how to generate a proper Android release build for the Flutter app in `mobile_app/`.

## Current status in this repo

The project now expects a real release keystore and package name:

- `applicationId = "com.agrobrain360.app"`
- release builds require `mobile_app/android/key.properties`

Without `key.properties`, production release builds should fail intentionally so the app is not debug-signed by mistake.

## Step 1: Verify prerequisites

Make sure these are installed:

1. Flutter SDK
2. Android Studio or Android command-line tools
3. Java 17
4. An Android device or emulator for testing

Then run:

```powershell
flutter doctor
```

## Step 2: Open the Flutter app directory

```powershell
cd d:\AgroBrain360\mobile_app
```

## Step 3: Download Flutter dependencies

```powershell
flutter pub get
```

## Step 4: Set the production backend URL

Open [api_constants.dart](d:\AgroBrain360\mobile_app\lib\core\constants\api_constants.dart) and confirm:

1. `ApiK.base` points to your real deployed backend URL.
2. `ApiK.useLocal` is `false` for release builds.

Current production default in the repo:

```dart
static const String base = String.fromEnvironment(...);
static bool useLocal = const bool.fromEnvironment(...);
```

If your Render backend URL is different, prefer passing it at build time:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://your-render-url.onrender.com
```

## Step 5: Create a release keystore

Run this from a terminal:

```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Store `upload-keystore.jks` in a safe place. A common project location is:

```text
mobile_app/android/upload-keystore.jks
```

Do not commit the real keystore to public Git history.

## Step 6: Create `key.properties`

Copy the example file:

- `mobile_app/android/key.properties.example` -> `mobile_app/android/key.properties`

Put your real values in it:

```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=upload
storeFile=upload-keystore.jks
```

If the keystore is inside `mobile_app/android/`, the `storeFile` above is enough.

## Step 7: Update Android signing configuration

The repo is already wired to load `key.properties` and use a dedicated `release` signing config in [build.gradle.kts](d:\AgroBrain360\mobile_app\android\app\build.gradle.kts).

## Step 8: Replace the placeholder application ID

The app now uses:

```kotlin
applicationId = "com.agrobrain360.app"
```

Important:

1. Pick this carefully before Play Store publishing.
2. Once published, changing package name creates a different app listing.

## Step 9: Increase app version before each release

Update the version in [pubspec.yaml](d:\AgroBrain360\mobile_app\pubspec.yaml):

```yaml
version: 1.0.0+1
```

Rules:

1. `1.0.0` is the user-visible version name.
2. `+1` is the Android version code.
3. Increase the version code for every Play Store upload.

Example:

```yaml
version: 1.0.1+2
```

## Step 10: Build the release APK

Run:

```powershell
flutter build apk --release
```

Or with explicit production backend:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://your-render-url.onrender.com
```

The output APK will be generated at:

```text
mobile_app/build/app/outputs/flutter-apk/app-release.apk
```

## Step 11: Recommended Play Store build

For Play Store upload, prefer App Bundle format:

```powershell
flutter build appbundle --release
```

The output will be:

```text
mobile_app/build/app/outputs/bundle/release/app-release.aab
```

## Step 12: Test the release build

Before distribution:

1. Install the APK on a real Android device.
2. Test login.
3. Test API-powered screens.
4. Test offline screens.
5. Test camera and image picker permissions.
6. Test microphone and speech features.
7. Test location-based services.

## Step 13: Prepare Play Store publishing assets

Before uploading to Google Play, make sure you also have:

1. app name
2. app icon
3. screenshots
4. privacy policy URL
5. app description
6. support contact details

## Common release issues

### Release build still signs with debug key

Cause:

- `build.gradle.kts` was not updated from the default Flutter template

Fix:

1. add a real release signing config
2. point `buildTypes.release` to it

### App connects to localhost instead of production

Cause:

- `ApiK.useLocal` is true
- or `ApiK.base` still points to the wrong backend

Fix:

1. set `useLocal = false`
2. confirm the deployed backend URL
3. rebuild the APK

### Play Store rejects the package setup

Common causes:

- placeholder `applicationId`
- version code not incremented
- unsigned or debug-signed release

## Final checklist before release

1. Backend is deployed and working.
2. `ApiK.base` points to the live backend.
3. `ApiK.useLocal` is false.
4. `applicationId` matches your final package name.
5. `key.properties` exists and points to a real keystore.
6. `pubspec.yaml` version is updated.
7. APK or AAB builds successfully.
8. The release build is tested on a real device.
