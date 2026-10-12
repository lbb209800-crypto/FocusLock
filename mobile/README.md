# FocusLock Mobile App

## Current application: scheduled focus lock

The default entry point is now a local schedule app (title, date/time, five- or
ten-minute lock), with Korean/English selection. It does not require Firebase or
the backend. See [scheduled lock setup and limitations](../docs/SCHEDULE_LOCK.md).

The sections below describe the earlier AI/auth prototype, which is retained as
legacy code rather than the current application flow.

Flutter-based AI-powered smartphone lock screen management application.

## Prerequisites

- Flutter SDK (>= 3.0.0)
- Dart SDK (included with Flutter)
- Android Studio / Xcode (for emulator/device development)
- Firebase account and project

## Setup

### 1. Install Dependencies

```bash
cd mobile
flutter pub get
```

### 2. Configure Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android and iOS apps to your Firebase project
3. Download and place configuration files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`
4. Update `lib/firebase_options.dart` with your Firebase credentials

### 3. Update Backend URL

Edit `lib/services/ai_service.dart` and update `_baseUrl` to your backend server URL.

## Running the App

### Local UI preview (without Firebase login)

From this folder on Windows:

```powershell
$env:PUB_CACHE = "$PWD\..\.tools\pub-cache"
..\.tools\flutter\bin\flutter.bat run -d web-server --web-hostname 127.0.0.1 --web-port 8080 -t lib/preview.dart
```

Open http://127.0.0.1:8080 in a browser. This preview reuses the lock screen and
focus timer screens without initializing Firebase. The AI preview still requires
the backend on port 3000 and currently returns mock data. It does not lock the
device or implement authentication or saving.

### Android

```bash
flutter run -d android
```

### iOS

```bash
flutter run -d ios
```

### Web (Development)

```bash
flutter run -d chrome
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── auth/
│   │   └── login_screen.dart
│   └── home/
│       ├── home_screen.dart
│       ├── lock_screen_setup.dart
│       └── focus_mode_screen.dart
└── services/                 # Business logic
    ├── auth_service.dart
    └── ai_service.dart
```

## Features

- 🤖 AI-generated custom lock screens
- ⏱️ 3-5 minute focus mode
- 🔐 Biometric code generation
- 👤 User authentication
- 📊 Focus statistics

## Development Notes

- Make sure your backend server is running before testing AI features
- Firebase must be properly configured for authentication to work
- Test on both iOS and Android devices for best results

## Troubleshooting

### Firebase connection fails
- Check internet connection
- Verify Firebase credentials in `firebase_options.dart`
- Ensure Firebase project is active

### AI service returns errors
- Verify backend server is running
- Check backend URL in `ai_service.dart`
- Ensure mood input is not empty

## Next Steps

- [ ] Implement persistent local storage
- [ ] Add notification system
- [ ] Implement lock screen preview
- [ ] Add statistics dashboard
- [ ] Multi-language support
