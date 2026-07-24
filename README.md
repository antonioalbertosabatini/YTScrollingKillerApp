# YTScrollingKiller

Mobile companion that lets you watch **one YouTube Short in the browser**, then **blocks scrolling** to more Shorts with a full-screen popup and closes the tab.

> Local testing only. Android scroll-block is the active path. The native YouTube app is out of scope.

## What it does (Android)

1. You open a Short in Chrome (or another supported browser) — playback stays in the browser; this app does not take over.
2. You can watch that Short normally (including to the end).
3. If you try to go to another Short (swipe, related, or autoplay), a blocking overlay appears: **“Scrolling blocked”**.
4. The only action is **Close tab** (best-effort close; falls back to YouTube Home).

## How it works

```text
Browser Shorts URL (silent watch)
        │
        ▼
 Accessibility service remembers short id
        │
        ▼
 Short id changes (swipe / related / autoplay)
        │
        ▼
 Full-screen accessibility overlay
        │
        ▼
 "Close tab" → close browser tab (or YouTube Home)
```

**Limitations**

- Does **not** intercept the YouTube native app.
- Android first; iOS Safari scroll-block is not active yet.
- Closing the tab depends on browser Accessibility nodes; if that fails, the service navigates to `https://www.youtube.com/`.

## How to use (Android)

1. Install and open the app.
2. Tap **Open Accessibility settings** and enable **YTScrollingKiller Shorts Guard**.
3. Open a Short in Chrome — watch normally.
4. Swipe (or related / autoplay) → overlay → **Close tab**.

## Install / run locally

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable)
- Android Studio / Android SDK
- A phone or emulator

### Open in Android Studio (phone testing)

```bash
./scripts/open_android_studio.sh
```

Then select your device and press Run. Enable the Accessibility service from the Setup screen.

### CLI

```bash
flutter pub get
flutter test
flutter run
```

## Stack

- Flutter Setup companion UI (English)
- Android Accessibility Service + `TYPE_ACCESSIBILITY_OVERLAY`

## Documentation for contributors / AI agents

| File | Purpose |
|------|---------|
| [AGENTS.md](AGENTS.md) | Repo map and change guidelines for AI agents |
| [lib/README.md](lib/README.md) | Dart app structure |
| [android/README.md](android/README.md) | Android Accessibility scroll-block |
| [ios/README.md](ios/README.md) | iOS notes (deferred for scroll-block) |
| [.cursor/rules/project.mdc](.cursor/rules/project.mdc) | Cursor always-on project rule |

## License

Private / unpublished — local development.
