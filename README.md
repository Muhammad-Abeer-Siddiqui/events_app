# CampusLoop

CampusLoop is a Flutter MVP for discovering university events, joining campus
chats, requesting event listings, and finding students across Karachi
universities.

## Run Preview

Use the cleaner folder if Windows blocks builds inside Documents:

```bash
cd /d C:\dev\events_app
flutter pub get
flutter run -d windows
```

## Firebase Setup

The app uses Firebase Auth and Cloud Firestore only. It avoids Firebase Storage,
Cloud Functions, phone auth, and server cleanup so the course MVP can stay on
free-tier usage.

In Firebase Console:

1. Enable Authentication > Sign-in method > Email/Password.
2. Enable Cloud Firestore.
3. Open Project settings > General.
4. Copy these values from your Firebase app config:
   - `apiKey`
   - `projectId`
   - `appId`
   - `messagingSenderId`

Run Windows preview:

```bash
flutter run -d windows --dart-define=FIREBASE_WEB_API_KEY=YOUR_API_KEY --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID --dart-define=FIREBASE_APP_ID=YOUR_APP_ID --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_MESSAGING_SENDER_ID
```

Build Android APK:

```bash
flutter build apk --debug --dart-define=FIREBASE_WEB_API_KEY=YOUR_API_KEY --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID --dart-define=FIREBASE_APP_ID=YOUR_APP_ID --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_MESSAGING_SENDER_ID
```

Admin panel access is limited in the app UI to:

```text
abeersiddiki2k18@gmail.com
```
