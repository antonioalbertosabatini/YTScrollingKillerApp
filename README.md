# YTScrollingKiller

Mobile app (iOS + Android) that intercepts **YouTube Shorts opened in a browser**, plays **one short only** (no endless Shorts feed), and sends you back to **YouTube Home** with a button.

> Local testing only for now. The native YouTube app is out of scope.

## What it does

1. Detects when you open a YouTube Short in a supported mobile browser.
2. Opens this app with that video.
3. Plays it through the official YouTube IFrame embed (single video — no Shorts scrolling UI).
4. Offers **Go to YouTube Home**, which opens `https://www.youtube.com/` in the system browser.

## How it works

```text
Browser Shorts URL
        │
        ▼
 Platform intercept
  • Android: Accessibility Service reads the browser URL bar
  • iOS: Safari Web Extension redirects Shorts pages
        │
        ▼
 ytsk://short/{videoId}
        │
        ▼
 Flutter app → single IFrame player
        │
        ▼
 "Go to YouTube Home" → youtube.com
```

**Limitations**

- Does **not** intercept the YouTube native app.
- On iOS, only **Safari** is covered (Chrome on iOS does not load Safari extensions).
- Age-restricted or unavailable videos may fail in the public embed.

## How to use

### Android

1. Install and open the app.
2. Tap **Open Accessibility settings** and enable **YTScrollingKiller Shorts Intercept**.
3. Open a Short in Chrome (or another supported browser).
4. The app should open and play that single short.
5. Tap **Go to YouTube Home** when you want to leave.

You can also paste a Shorts URL on the setup screen for a manual test, or use “Open with” on a `youtube.com/shorts/...` link.

### iOS (Safari)

1. Install the app (with the Safari Web Extension target).
2. Settings → Apps → Safari → Extensions → enable **YTScrollingKiller** and allow `youtube.com`.
3. Open a Short in Safari — the extension redirects to the app.
4. Tap **Go to YouTube Home** when you want to leave.

Deep link format for manual tests: `ytsk://short/{videoId}`.

## Install / run locally

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable)
- Android Studio / Android SDK (for Android)
- **Full Xcode** (not only Command Line Tools) for iOS / Safari extension builds
- A device or emulator/simulator

### Get dependencies

```bash
cd "YTScrollingKiller App"
flutter pub get
```

### Run tests

```bash
flutter test
```

### Run on Android

```bash
flutter run -d android
```

Then enable the Accessibility service from the in-app Setup screen.

Verified locally: `flutter build apk --debug` succeeds.

### Run on iOS

Requires a full Xcode install (`xcode-select -s /Applications/Xcode.app/Contents/Developer`).

```bash
flutter run -d ios
```

In Xcode, confirm the **SafariExtension** target is embedded in **Runner**, then enable the extension in Safari settings on the simulator/device.

### Manual deep-link smoke test

```text
ytsk://short/dQw4w9WgXcQ
```

On Android you can also:

```bash
adb shell am start -a android.intent.action.VIEW -d "ytsk://short/dQw4w9WgXcQ"
```

## Stack

- Flutter (shared UI + player)
- YouTube IFrame API (`youtube-nocookie.com`)
- Android Accessibility Service
- iOS Safari Web Extension
- Deep links via `app_links` (`ytsk://`)

## Documentation for contributors / AI agents

| File | Purpose |
|------|---------|
| [AGENTS.md](AGENTS.md) | Repo map and change guidelines for AI agents |
| [lib/README.md](lib/README.md) | Dart app structure |
| [android/README.md](android/README.md) | Android intercept details |
| [ios/README.md](ios/README.md) | iOS URL scheme + Safari extension |
| [.cursor/rules/project.mdc](.cursor/rules/project.mdc) | Cursor always-on project rule |

## License

Private / unpublished — local development.
