# how_to_hockey

A new Flutter project.

## Getting Started

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
