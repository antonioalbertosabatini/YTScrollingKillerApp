# AGENTS.md — YTScrollingKiller

Guidance for AI coding agents working in this repository.

## Product summary

Android-first companion: the user watches **one** YouTube Short **in the browser**. Changing to another Short (swipe / related / autoplay) shows a blocking Accessibility overlay with a single **Close tab** action. No in-app video player takeover.

UI language: **English**. Distribution: **local testing only**.

## Stack

- Flutter / Dart (`lib/`) — Setup screen only on Android path
- Android: `ShortsAccessibilityService` + overlay layout
- iOS Safari scroll-block: deferred

## Repo map

```text
lib/
  main.dart, app.dart          # entry + MaterialApp → SetupScreen
  core/short_url_parser.dart   # shared URL helpers / unit tests
  features/setup/              # enable Accessibility; explain behavior
android/.../ShortsAccessibilityService.kt
android/.../res/layout/scroll_block_overlay.xml
ios/SafariExtension/           # legacy / future iOS work
test/
scripts/open_android_studio.sh
```

## Where to change what

| Goal | Location |
|------|----------|
| Silent watch / id-change block | `android/.../ShortsAccessibilityService.kt` |
| Overlay UI copy / button | `res/layout/scroll_block_overlay.xml`, `res/values/strings.xml` |
| Close-tab heuristics | `CLOSE_TAB_*` in `ShortsAccessibilityService.kt` |
| Setup copy | `lib/features/setup/setup_screen.dart` |
| URL parsing helpers | `lib/core/short_url_parser.dart` |

## Do / don’t

**Do**

- Keep Shorts playback in the browser.
- Block only when the Shorts **video id changes**.
- Keep overlay non-dismissible except **Close tab**.
- Keep UI strings in English.

**Don’t**

- Reintroduce in-app Shorts player takeover on Android.
- Add MITM / decrypting VPN.
- Intercept the YouTube **native app**.
- Allow “keep watching” after the block popup.

## Commands

```bash
flutter pub get
flutter test
flutter analyze
./scripts/open_android_studio.sh
flutter run
```

## Further reading

- Human product docs: [README.md](README.md)
- Dart layout: [lib/README.md](lib/README.md)
- Android: [android/README.md](android/README.md)
- iOS: [ios/README.md](ios/README.md)
