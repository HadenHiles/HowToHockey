# Copilot Development Reference

Internal implementation, local-machine setup, validation, and release notes
for Copilot while building How To Hockey. This is not public onboarding
documentation. Read [Current Status](../ROADMAP.md#-current-status) first;
the roadmap remains the source of truth for scope and decisions.

## Development Notes

### UX-first app development

The normal app now opens the Player shell (Train, Progress, Team, Me), not the
old standalone Appearance screen. Use the existing **Live**, **Emulators**,
**iPhone (Live)**, or **Samsung S24 (Live)** launch configuration. There is no
separate preview app or `UX_PREVIEW` flag.

These are the app's actual screens and routes in [lib/app/](../lib/app/).
Firebase startup, anonymous sign-in, App Check, and telemetry configuration
retain their existing behavior. Local Riverpod providers currently supply
sample content and in-memory training state; persistence and server features
will be connected to these same screens as the roadmap resumes. Appearance
and per-drill rest settings already persist on the device. Workouts are not yet
saved to history or published to teams, and purchases remain unimplemented.

The first slice includes Train home, setup/focus, routine detail, drill
library/detail, all six logging styles, real countdown controls, optional rest,
and summary. Setup/focus choices do not yet generate/filter the sample routine.
Media illustrations remain labeled placeholders. Progress now includes a sample
skill radar, personal-best cards, lifetime totals, session detail, and a
share-card preview; these are representative fixtures, not saved workout
history or a working share flow. Team now includes member/no-team/locked
states, sample homework, locker-room posts with local stick taps, weekly
standings, discovery, and join/invite entry points. Joining, invite sharing,
and real team activity remain unconnected. Me includes device-persisted
appearance, local sample-profile switching, and role/account/subscription
sheets. Profile selection only changes the Me sample header; it does not
switch account-wide data. Parent/Coach selection, account linking/deletion,
and purchases/restore explicitly disclose that they are unavailable.
Parent is the next slice, followed by Coach, account, commerce, and programs in the ordered
[UX-first milestone](../ROADMAP.md#ux-first--actual-app-screens-current-priority).
Building a screen does not mark its unimplemented backend criteria complete.

The revised visual direction uses an ice-tinted light canvas, a dark navigation
rail, charcoal rink-illustrated hero cards, and skill-colored data marks. Player
skills are Accuracy, Hands, Power, Passing, Speed/Strength, and Endurance;
Accuracy and Power are shot-focused. Keep the locked How To Hockey logo, brand
red/cream, Inter type, accessible contrast, and light/dark appearance setting
intact when extending the screens.

The active workout is a single draggable panel owned by the shared Player
shell, not by the Train branch. After a workout starts, its collapsed header
remains visible above navigation on Train, Progress, Team, and Me, with logs,
draft inputs, and drill selection retained across tab changes. Reserve the
header's height below the main screen content so it cannot cover the last
controls. Pushed detail routes cover the shell; Player modal detail/settings
sheets use `useRootNavigator: true` so the panel cannot cover those sheets.
Finishing the workout dismisses the panel but preserves data for the summary;
starting another workout creates a fresh panel.
Keep the sheet
bounded above the app navigation; its red status header is a dedicated drag
surface so the sheet can always collapse even while its body is scrolled.
Move the app navigation in sync with the sheet extent: it slides down while
the sheet expands and returns as the sheet collapses. Keep the shared sheet
scroll controller on the vertical content—do not add a competing drag
recognizer inside the scroll body. Only the red status header (handle and
elapsed/active/set metrics) stays pinned; the workout title, the portrait
drill preview carousel, optional rest controls, the active drill or **Workout
overview**, and the Log action all scroll together in the sheet body, with the
Log action as the last item in that scroll. The shell uses `extendBody` so the
panel's viewport is the full screen (including the navigation slot):
`minChildSize` is the status header plus navigation height, so collapsing
parks the red header directly on top of the opaque navigation bar, and
`maxChildSize` stops below the status bar, covering the vacated navigation
slot. Do not overflow the panel past its parent with negative offsets—those
areas are not hit-testable. The drill body height is computed so the title
row, previews, drill controls, and Log action fit one screen without scrolling;
keep that header/body compact (no redundant captions).
The preview carousel is one horizontal row of exact 9:16 cards within the
vertical content, with five visible at normal text size and four at large
text size. Never wrap it into stacked rows. Swiping the logging pages changes
the active drill, highlights its preview, and scrolls the carousel to keep
that preview visible. Tapping a preview card switches to that drill.
Carousel motion respects Reduce Motion. Timed drill inputs pause when the
panel collapses, retaining the remaining time for explicit resume.
Instruction/media stays on the separate `/session-drills/:id` screen, reached
from the **Drill details** action inside the active drill, backed by the
current session's drills (including custom routine templates), without changing
the active drill or starting a new workout. Keep media and coach's cues out of
the logging body. Logging a set stays on that drill; sets can be completed out
of order. Draft inputs survive swiping, opening the overview, and returning
from details; timed drill inputs pause when leaving the drill or viewing
details and must be explicitly resumed. Finish the workout once all sets are
logged to open the summary. The fixed header uses pointer vertical deltas
directly, not synthesized axis-constrained drag details; diagonal and canceled
drags must settle safely.
The Train app bar has a centered How To Hockey wordmark. The bottom navigation
uses animated selection and tap feedback; respect **Reduce Motion**.
The workout-opening route is nested under `/train` at `/train/session`;
`/session` redirects there for compatibility. All session-start actions use
`context.go('/train/session')`, not `push`: pushing back into the Player shell
from a root-level preview already pushed above it can duplicate the shell's
page key. Starting a workout replaces the preview/setup stack with Train and
its transparent session-opening route. That route does not draw another
Train page or own the panel. Back returns to Train and collapses the shared
panel rather than removing the active workout. Returning to Train through
tab navigation also leaves the panel collapsed. Observe the router delegate's
canonical configuration for opening/collapsing, including `/session` and
`/rest` redirects; cached shell-builder state can lag behind a route pop.

**Routine management** is available from Train through **Manage routines**.
The local routine library supports creating/editing routines from preset styles,
adding catalog drills, and adding preset skill-template drills with adjustable
sets/reps. Names and drill titles are selected templates, not player free-text
inputs. Routines and custom template drills are currently device-local via
SharedPreferences; cloud sync and entitlement checks are not implemented.
Keep the `TODO(RevenueCat)` at routine save as the future Phase 5 integration
point for the three-saved-routine free-tier cap and Player Pro entitlement.
RevenueCat setup belongs to the monetization process in the public README;
do not add paywall UI until that roadmap work is approved.

**Drill settings** is available in the session and drill detail. Rest is off
by default. Enable it per drill and select 15–600 seconds; this preference is
saved for that drill on this device, not synced to an account. Enabled rest
starts an inline countdown after logging a set, with `−15s`, `+15s`, and
**Skip rest** controls. It never blocks logging or navigation and is omitted
after the final workout set.

Elapsed time includes rest and is fixed when the final set is logged. Active
training totals use the logged timer duration for timed sets and the catalog's
estimate for untimed sets, explicitly labeled as estimated when applicable.
These local UX totals are not production history or leaderboard metrics.

Run host-only unit/widget validation with `flutter test test`. Do not use an
unscoped test runner that also discovers `integration_test/`, as it may select
a connected physical phone.

Test the normal Firebase-backed entrypoint and Player flow on an explicitly
selected emulator/simulator. Do not use physical devices unless the user
explicitly requests one:

```sh
flutter test integration_test/player_flow_test.dart -d <emulator-or-simulator-id>
```

Add `--dart-define=USE_EMULATORS=true` when running against the local Firebase
suite.

### Android and iOS emulators together (live Firebase)

Select **Android + iOS Emulators (Live)** in VS Code's Run and Debug panel and
press **F5**. The compound first runs **Prepare Android + iOS emulators**,
which boots Android and then iOS and waits for both to be ready before
starting either Flutter debug session. The individual profiles retain their
own boot checks when launched separately:

- **Android Emulator (Live):** boots/reuses `Medium_Phone_API_36.0` on
  `emulator-5554` and waits for Android to finish booting.
- **iOS Simulator (Live):** boots/reuses the configured iPhone 16 Plus and opens
  Simulator. Its build uses the process-scoped SwiftPM Git-policy exception
  described below.

Both apps use **live Firebase**, not the local Firebase Emulator Suite.
No Firebase emulator process is started. Debug App Check tokens for these
virtual devices may need registering in the Firebase console before accessing
App Check-protected services. Stopping either debug session stops both; the
virtual devices stay open for the next launch.

The device-specific profiles also work individually. This setup requires macOS,
Xcode, Flutter, and the existing Android AVD. The boot tasks are in
[.vscode/tasks.json](../.vscode/tasks.json), with checks in
[tool/boot_mobile_emulator.sh](../tool/boot_mobile_emulator.sh). Android SDK discovery
uses `ANDROID_HOME`, then `ANDROID_SDK_ROOT`, then the standard macOS SDK path.
If another AVD occupies `emulator-5554`, the task fails explicitly rather than
launching on the wrong device. If you recreate the iPhone Simulator, update its
UUID in both the boot script and [.vscode/launch.json](../.vscode/launch.json).

The existing **Emulators** profile still means a selected mobile device backed
by the separately started local Firebase Emulator Suite.

If Problems lists deleted files under `lib/preview/` or the old
`integration_test/ux_preview_test.dart`, close those obsolete editor tabs
without saving them, then run **Dart: Restart Analysis Server** from the Command
Palette. If diagnostics remain, use **Developer: Reload Window**. Do not
recreate the deleted preview files or exclude current app code from analysis.
The Debug Console may retain failed hot-reload output from earlier edits;
check the output from a fresh launch before treating it as a current failure.
App Check debug-token registration messages and Gradle compatibility warnings
alone do not mean the app failed to launch.

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

### Continuous integration and rules tests

The GitHub Actions workflow runs on every pull request and push to `master`:

- Flutter analysis, unit/widget tests, and an Android debug APK build.
- Functions lint, unit tests, and TypeScript build with Node 24.
- Firestore and Storage rules tests with Node 24 and Java 21.

Device-only App Check integration tests are intentionally not part of the
headless Flutter test job. CI does not deploy anything or need Firebase secrets.

Run the same checks locally:

```sh
flutter analyze
flutter test test
flutter build apk --debug
npm ci --prefix functions
npm --prefix functions run lint
npm --prefix functions test
npm --prefix functions run build
npm ci --prefix rules_test
npm --prefix rules_test test
```

The rules runner starts only Firestore and Storage emulators and shuts them down
after testing. It uses `demo-how-to-hockey`, never the live Firebase project.
The test harness rejects missing or non-local emulator addresses. Tests seed
existing resources, then verify that all client access remains denied for
unauthenticated users, anonymous users, owners, other players, coaches, and admin
claims. This baseline must evolve alongside rules as features introduce access.

The rules-test package has scoped dependency overrides for patched gRPC, FTP,
and UUID versions. These are development tooling only, not app or Functions
dependencies. Firebase CLI 15.32.1 still brings in an OpenTelemetry baggage
allocation advisory through its Pub/Sub dependency (three moderate audit
entries); the rules runner does not use Pub/Sub. Revisit this when updating the
CLI rather than forcing an incompatible telemetry major version.

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
