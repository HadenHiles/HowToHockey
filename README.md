# How To Hockey

How To Hockey is an iOS and Android training app designed to help hockey
players build better habits and develop their skills on and off the ice.

The app brings guided drills, structured workouts, and progress tracking
together, with planned tools for parents and coaches to support players
and teams.

**Currently in development.** The app's screens and training flows are being
built with sample data and placeholder media; some features are not connected
to backend services yet.

## Development Setup

The mobile app uses Flutter and Dart, with a Firebase backend and Cloud
Functions written in TypeScript.

1. Install the Flutter SDK and Android development tools. For iOS, use macOS
   with Xcode.
2. Install Node.js 24 and the Firebase CLI for backend development.
3. Fetch dependencies:

   ```sh
   flutter pub get
   npm ci --prefix functions
   ```

4. Configure access to the development Firebase project or start the local
   Firebase Emulator Suite, then run on an iOS or Android device:

   ```sh
   flutter run
   ```

   For local Firebase services, use
   `flutter run --dart-define=USE_EMULATORS=true`. VS Code launch profiles are
   also provided, including a combined Android/iOS virtual-device launch.

## Checks

```sh
flutter analyze
flutter test test/
```
