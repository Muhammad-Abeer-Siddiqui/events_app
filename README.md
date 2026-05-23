# CampusLoop

CampusLoop is a Flutter MVP for discovering university events, joining a global
student chat, and finding people who are open to private chats.

## Run Preview

```bash
flutter pub get
flutter run -d windows
```

If Windows blocks the build inside Documents, use the cleaner copy:

```bash
cd /d C:\dev\events_app
flutter pub get
flutter run -d windows
```

## Firebase Login

The app has a login/signup screen. It uses Firebase Authentication when you pass
your Firebase Web API key at run/build time:

```bash
flutter run -d windows --dart-define=FIREBASE_WEB_API_KEY=YOUR_FIREBASE_WEB_API_KEY
```

For an Android APK:

```bash
flutter build apk --debug --dart-define=FIREBASE_WEB_API_KEY=YOUR_FIREBASE_WEB_API_KEY
```

In Firebase Console, create a project, add an app, copy the Web API key from
project settings, and enable Authentication > Sign-in method > Email/Password.
Without the key, the app keeps a local preview login so the demo still works.
