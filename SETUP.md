# NutriSense Frontend — Setup Guide

This Flutter app is now wired to a real backend, real Firebase Auth, and
a real camera. Here's everything you need to do to get it running.

## 1. Merge these files into your project

Copy everything from this `lib/` folder into your existing project's
`lib/` folder, overwriting the old files. Also replace your
`pubspec.yaml` with the one included here (it adds `google_sign_in`
and confirms `image_picker`, `firebase_auth`, etc. are present).

```bash
flutter pub get
```

## 2. Connect Firebase (FlutterFire CLI)

The file `lib/firebase_options.dart` included here is a **placeholder**
that intentionally throws an error if used as-is. You must generate
the real one:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=your-firebase-project-id
```

This command:
- Logs you into Firebase (browser prompt)
- Lets you pick which platforms to support (Android, iOS, etc.)
- Registers the app with your Firebase project if not already done
- **Overwrites** `lib/firebase_options.dart` with real working config
- Drops `google-services.json` (Android) and `GoogleService-Info.plist`
  (iOS) into the right native folders automatically

Run this from the root of your Flutter project (where `pubspec.yaml`
lives).

## 3. Enable sign-in methods in Firebase Console

In Firebase Console → Authentication → Sign-in method:
- Enable **Email/Password**
- Enable **Google** (needed for the "Continue with Google" button).
  When you enable Google sign-in, Firebase shows you a Web Client ID —
  you don't need to copy this anywhere manually if you used
  `flutterfire configure`, since the CLI already wires it up.

## 4. Android permissions (camera + photo library)

Open `android/app/src/main/AndroidManifest.xml` and add these inside
the `<manifest>` tag, above `<application>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
```

Also confirm `android/app/build.gradle` has `minSdkVersion 21` or
higher (required by `firebase_auth` and `image_picker`):

```gradle
android {
    defaultConfig {
        minSdkVersion 21
        ...
    }
}
```

## 5. iOS permissions (camera + photo library)

Open `ios/Runner/Info.plist` and add these entries (these are the
strings shown to the user when iOS asks for permission):

```xml
<key>NSCameraUsageDescription</key>
<string>NutriSense needs camera access to scan your food.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>NutriSense needs photo library access to scan food from your photos.</string>
```

Also make sure your iOS deployment target is 13.0+ in
`ios/Podfile` (uncomment and set):
```ruby
platform :ios, '13.0'
```

Then run:
```bash
cd ios && pod install && cd ..
```

## 6. Point the app at your deployed backend

Once you've deployed the backend to Render (see
`nutrisense-backend/README.md`), update:

`lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = 'https://YOUR-ACTUAL-RENDER-URL.onrender.com/api/v1';
```

## 7. Run it

```bash
flutter analyze     # should show 0 issues — fix any before running
flutter run
```

The real, working flow is now:

1. **Splash screen** → checks if you're signed in to Firebase, and if
   so, asks the backend whether you've completed onboarding.
2. **Auth screen** (if not signed in) → real Firebase email/password
   sign up & sign in, plus Google sign-in, plus password reset emails.
3. **Onboarding** (if signed in but no backend profile yet) → collects
   your stats, then calls `POST /users/onboarding`, which computes
   your real BMR/TDEE/calorie targets server-side and creates your
   profile in Supabase.
4. **Home / scanner / diary / etc.** → all backed by real API calls:
   - The camera button opens your actual camera (or photo gallery),
     compresses the image, sends it to `/scan`, which runs it through
     Gemini + Open Food Facts and returns a real result.
   - Logging food, water, and weight all call the backend and persist
     to Supabase.
   - The AI Coach chat calls `/ai/coach/chat`, which is genuinely
     powered by Gemini with your real daily data as context.

## What's still mocked / not wired up

Being upfront about what wasn't part of this pass:

- **Barcode scanning** — the scanner only does photo-based identification
  right now; a dedicated barcode reader (e.g. `mobile_scanner` package)
  is V2 per the original spec.
- **Step tracking sync** — `ApiService.syncSteps()` exists and the
  backend route is ready, but the actual Health Connect / HealthKit
  native integration (reading real step data off the device) isn't
  wired into a screen yet. The `health` package is in `pubspec.yaml`
  ready for this.
- **Push notifications** — `firebase_messaging` is in `pubspec.yaml`
  but no notification handling code or backend FCM-sending code exists
  yet.
- **Analytics/achievements screens** — currently still read from local
  mock data (the `weeklyCalories`/`weeklyScore` arrays in
  `analytics_screen.dart`) rather than calling
  `GET /analytics/weekly` and `GET /achievements`. The backend routes
  are fully built and ready; wiring the screen is a smaller follow-up
  if you want it.
- **Offline support** — no local caching/queueing if the network is
  down; API calls will simply show an error.

## Debugging tips

- If `flutterfire configure` fails with a permissions error, make sure
  you're logged into the Google account that actually owns the
  Firebase project (`firebase login` via the Firebase CLI, if you have
  it, can help verify).
- If sign-up succeeds but onboarding's final "Finish" button shows an
  error, check that your Render backend is actually awake (free tier
  spins down after inactivity — the first request can take 30-50s) and
  that `SUPABASE_SERVICE_ROLE_KEY` / `FIREBASE_SERVICE_ACCOUNT_JSON`
  are set correctly on Render.
- If the camera button does nothing on a physical device, double-check
  the AndroidManifest/Info.plist permissions above were actually saved
  and you did a full rebuild (`flutter clean && flutter run`), not just
  hot reload — permission manifest changes need a fresh build.
