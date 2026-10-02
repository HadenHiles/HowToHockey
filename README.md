# how_to_hockey

A new Flutter project.

## Getting Started

### Local testing on the Samsung S24

Select **Samsung S24 (Live)** in VS Code's Run and Debug panel and press **F5**.
This runs a debug build on the connected phone against live Firebase, without
starting Firebase emulators or publishing to Google Play.

Alternatively, run from the repository root:

```sh
flutter run --debug -d R3CX20HFZJL --dart-define=USE_EMULATORS=false
```

Debug builds use the App Check debug provider; this Samsung's debug token is
already registered in Firebase. No upload keystore, Play Console release, or
DeviceCheck private key is needed for this Android debug workflow. Leave
`VERIFY_APP_CHECK` unset: it is only for explicit production-attestation checks.
Production signing, provider verification, and store setup below are deferred
until release preparation and do not block local development.

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## iOS builds with restricted bare Git repositories

Xcode's Swift Package Manager uses bare Git repositories for dependency caches.
When Git is configured with `safe.bareRepository=explicit`, package resolution
can fail with `Couldn't get the list of tags`. Use a process-scoped exception
from the repository root rather than changing the global Git policy:

```sh
GIT_CONFIG_COUNT=1 \
GIT_CONFIG_KEY_0=safe.bareRepository \
GIT_CONFIG_VALUE_0=all \
flutter build ios --no-codesign
```

This permits bare-repository access only for that build and its child processes.
Use it only with trusted project dependencies. The resulting app is unsigned;
installing on an iPhone requires Apple provisioning and code signing. For a
signed live-device debug run, use the same environment prefix with
`flutter run -d <iphone-device-id> --dart-define=USE_EMULATORS=false`.

Production App Check remains pending real-device verification. App Attest is
configured in Firebase and the iOS target, but DeviceCheck fallback requires an
Apple DeviceCheck key registered securely in Firebase. Do not commit private keys
or enable enforcement until both mobile platforms have been verified.

## Production App Check setup

App Attest is registered for Apple team `A3T2KUV3B5` and has passed a fresh-token
exchange on a signed physical iPhone. App Check enforcement is not enabled by
this setup. Complete the remaining steps below before enabling it.

### Apple DeviceCheck fallback

1. Sign in to [Apple Developer](https://developer.apple.com/account/) as an
   Account Holder or Admin for team `A3T2KUV3B5`.
2. Open **Certificates, Identifiers & Profiles > Keys**, click **+**, name the key
   `How To Hockey DeviceCheck`, and enable **DeviceCheck**.
3. Register the key, download its `.p8` file, and record its **Key ID**. Apple
   permits the private-key download only once. Keep a secure backup outside this
   repository; never paste the key into chat or commit it.
4. Open [Firebase App Check](https://console.firebase.google.com/project/how-to-hockey/appcheck).
   In **Apps**, select the iOS app `com.howtohockey.app` and configure
   **DeviceCheck** with that file, Key ID, and Team ID `A3T2KUV3B5`. Keep the
   one-hour token TTL and retain the existing App Attest configuration.
5. With a physical iPhone unlocked and connected, run the DeviceCheck test below.
   It deliberately selects DeviceCheck rather than relying on automatic fallback.

```sh
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all \
flutter drive --profile \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_check_test.dart \
  --dart-define=VERIFY_DEVICE_CHECK=true \
  -d <iphone-device-id>
```

Omit `--dart-define=VERIFY_DEVICE_CHECK=true` to verify App Attest separately.
The test requires a fresh, nonempty token and never prints it. Debug-provider
success is not production verification.

### Android upload signing and Play Integrity

1. In [Play Console](https://play.google.com/console), choose **Create app**:
   name `How To Hockey`, select the appropriate default language, **App**, and
   **Free** (subscriptions/IAP can still be added later). Complete the required
   declarations. The bundle's permanent application ID is `com.howtohockey.app`.
2. Generate an **upload key** outside the repository. If you already have a
   suitable upload key, use it instead; do not overwrite or rotate existing keys.
   This command prompts for passwords so they do not enter shell history:

   ```sh
   keytool -genkeypair -v \
     -keystore "$HOME/how-to-hockey-upload.jks" \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   Store the keystore and its passwords securely with a backup.
3. Create `android/key.properties` locally (already excluded from Git). Fill in
   the actual values; `storeFile` must be an absolute path:

   ```properties
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=/absolute/path/to/how-to-hockey-upload.jks
   ```

   Release builds now fail explicitly without this configuration; they no longer
   use the development debug key. Debug/profile builds keep development signing.
4. Build a verification bundle:

   ```sh
   flutter build appbundle --release \
     --dart-define=USE_EMULATORS=false \
     --dart-define=VERIFY_APP_CHECK=true
   ```

5. In Play Console, create an **Internal testing** release, enroll in **Play App
   Signing** (Google-managed app signing is the usual option), and upload
   `build/app/outputs/bundle/release/app-release.aab`. Complete any required
   account/app setup shown by Play Console.
6. Open **App integrity > Play Integrity API** (usually under **Test and
   release/Release**), choose **Link Cloud project**, and link **how-to-hockey**,
   project number **591675097325**.
7. On **App integrity > App signing**, copy the **SHA-256** fingerprint under
   **App signing key certificate**, not just the upload certificate. Google
   signs the app delivered to users with this app signing key.
8. In [Firebase project settings](https://console.firebase.google.com/project/how-to-hockey/settings/general),
   select the Android app and **Add fingerprint** using that SHA-256. In
   **App Check > Apps**, register/save **Play Integrity** for this Android app.
   Keep the one-hour TTL and require Play-recognized app versions; do not
   weaken attestation requirements merely to accept a sideloaded APK.
9. Add your Samsung's Google account to the internal tester list, roll out the
   internal release, and use its opt-in link to install **from Google Play**.
   A locally installed debug/profile APK does not verify Play recognition.
   Because the signing key differs, you may need to uninstall the development
   app first; doing so removes its local preferences and anonymous session.
10. Launch the Play-installed verification build and inspect the connected
    device's Flutter logs (Android Studio Logcat or
    `flutter logs -d R3CX20HFZJL`). Success reports:
    `App Check verification passed using production attestation.`
    A missing/invalid token fails startup instead of reporting success. Do not
    share raw tokens or private credentials.

Use a higher `--build-number` for each subsequent Play upload. After verification,
build the normal app without `VERIFY_APP_CHECK`; its regular startup does not
force an extra token exchange.

### Enforcement gate

Verify App Attest, DeviceCheck, and the Play-installed Android app; inspect valid
request metrics in Firebase App Check; then enable enforcement deliberately for
each supported backend service. Do not treat a debug token or a successful
unsigned build as production attestation.

References: [Firebase Play Integrity setup](https://firebase.google.com/docs/app-check/android/play-integrity-provider),
[Firebase DeviceCheck setup](https://firebase.google.com/docs/app-check/ios/devicecheck-provider),
and [Apple DeviceCheck keys](https://developer.apple.com/help/account/capabilities/create-a-devicecheck-private-key/).
