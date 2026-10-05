#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  android)
    sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
    adb="$sdk/platform-tools/adb"
    avd="Medium_Phone_API_36.0"
    serial="emulator-5554"
    if [[ ! -x "$adb" ]]; then
      echo "Android adb not found at $adb. Set ANDROID_HOME to your SDK directory." >&2
      exit 1
    fi
    if "$adb" -s "$serial" get-state >/dev/null 2>&1; then
      current_avd="$("$adb" -s "$serial" emu avd name | tr -d '\r' | head -n 1)"
      if [[ "$current_avd" != "$avd" ]]; then
        echo "$serial is running $current_avd, not $avd. Free port 5554 or update the launch target." >&2
        exit 1
      fi
    else
      flutter emulators --launch "$avd"
    fi
    deadline=$((SECONDS + 180))
    while [[ "$("$adb" -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]]; do
      if (( SECONDS >= deadline )); then
        echo "Timed out waiting for $avd on $serial. Check the Android emulator window." >&2
        exit 1
      fi
      sleep 2
    done
    current_avd="$("$adb" -s "$serial" emu avd name | tr -d '\r' | head -n 1)"
    if [[ "$current_avd" != "$avd" ]]; then
      echo "Expected $avd on $serial, but found $current_avd. Update the launch target." >&2
      exit 1
    fi
    echo "$avd is ready on $serial."
    ;;
  ios)
    simulator="57C6D957-4A0B-40FD-B10F-73364BDF931B"
    if ! xcrun simctl list devices booted | grep -Fq "$simulator"; then
      xcrun simctl boot "$simulator"
    fi
    xcrun simctl bootstatus "$simulator" -b
    open -a Simulator
    echo "iPhone 16 Plus is ready on $simulator."
    ;;
  *)
    echo "Usage: bash tool/boot_mobile_emulator.sh android|ios" >&2
    exit 1
    ;;
esac
