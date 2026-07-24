#!/usr/bin/env bash
# Open this Flutter project in Android Studio for device testing.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STUDIO_APP="${ANDROID_STUDIO_APP:-/Applications/Android Studio.app}"

if [[ ! -d "$STUDIO_APP" ]]; then
  echo "Android Studio not found at: $STUDIO_APP" >&2
  echo "Install it, or set ANDROID_STUDIO_APP to the .app path." >&2
  exit 1
fi

cd "$ROOT"

if command -v flutter >/dev/null 2>&1; then
  echo "Running flutter pub get..."
  flutter pub get
  echo
  echo "Connected devices:"
  flutter devices || true
  echo
else
  echo "Warning: flutter not on PATH; opening Android Studio anyway." >&2
fi

echo "Opening Android Studio with:"
echo "  $ROOT"
echo
echo "On your phone:"
echo "  1. Enable Developer options + USB debugging"
echo "  2. Connect USB (or use Wireless debugging)"
echo "  3. Accept the debug authorization prompt"
echo "  4. In Android Studio: select your device → Run (▶)"
echo

open -a "$STUDIO_APP" "$ROOT"
