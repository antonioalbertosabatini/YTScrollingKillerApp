# android/ — Shorts intercept

## Purpose

Detect YouTube Shorts URLs inside mobile browsers and open the Flutter app via `ytsk://short/{videoId}`.

## Key files

| File | Role |
|------|------|
| `app/src/main/kotlin/.../ShortsAccessibilityService.kt` | Reads browser URL bar / tree; launches deep link |
| `app/src/main/kotlin/.../MainActivity.kt` | MethodChannel `openAccessibilitySettings` |
| `app/src/main/AndroidManifest.xml` | Service + `ytsk` + https `/shorts/` intent filters |
| `app/src/main/res/xml/shorts_accessibility_service.xml` | Accessibility service config |
| `app/src/main/res/values/strings.xml` | Service description shown in system settings |

## Watched browsers

Configured in `ShortsAccessibilityService.WATCHED_PACKAGES` (Chrome, Firefox, Edge, Brave, Opera, Samsung Internet, etc.).

URL bar view IDs are listed in `URL_BAR_IDS`. There is a recursive text fallback for Shorts URLs.

## Debounce

Launches for the same video id are debounced (~2.5s) to avoid reopen loops while the browser still shows the Shorts URL.

## How to rebuild / test

### Open Android Studio (recommended for a physical phone)

From the repo root:

```bash
./scripts/open_android_studio.sh
```

This runs `flutter pub get`, lists devices, and opens the Flutter project in Android Studio. Select your phone and press Run.

### CLI

```bash
flutter devices
flutter run -d <device_id>
```

1. Open the app → **Open Accessibility settings**.
2. Enable **YTScrollingKiller Shorts Intercept**.
3. Open `https://m.youtube.com/shorts/<id>` in Chrome.
4. Confirm the app opens the single-short player.

Manual alternatives: paste URL on Setup screen, or “Open with” on a Shorts link (intent filter).

## MethodChannel

- Name: `com.ytscrollingkiller.ytscrolling_killer/accessibility`
- Method: `openAccessibilitySettings`
