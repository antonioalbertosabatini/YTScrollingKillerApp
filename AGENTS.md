# AGENTS.md — YTScrollingKiller

Guidance for AI coding agents working in this repository.

## Product summary

Flutter app that intercepts YouTube Shorts **in mobile browsers** (not the YouTube app), plays a **single** short via YouTube IFrame embed, blocks Shorts-to-Shorts scrolling, and opens **YouTube Home** on demand.

UI language: **English**. Distribution: **local testing only**.

## Stack

- Flutter / Dart (`lib/`)
- `webview_flutter` — IFrame player
- `url_launcher` — YouTube Home
- `app_links` — `ytsk://short/{id}` and https Shorts intents
- Android: `ShortsAccessibilityService`
- iOS: Safari Web Extension under `ios/SafariExtension/`

## Repo map

```text
lib/
  main.dart, app.dart          # entry + MaterialApp + deep-link routing
  core/                        # ShortUrlParser, DeepLinkService
  features/setup/              # Setup / enablement screen
  features/player/             # Single-short WebView player
assets/youtube_embed.html      # Reference embed HTML (player inlines HTML too)
android/.../ShortsAccessibilityService.kt
ios/SafariExtension/           # Safari Web Extension sources
test/                          # unit + widget tests
```

## Where to change what

| Goal | Location |
|------|----------|
| Parse Shorts / deep-link URLs | `lib/core/short_url_parser.dart` |
| Deep link listening | `lib/core/deep_links.dart`, `lib/app.dart` |
| Player / Home button | `lib/features/player/player_screen.dart` |
| Setup copy / platform instructions | `lib/features/setup/setup_screen.dart` |
| Android browser packages / URL bars | `android/.../ShortsAccessibilityService.kt` |
| Android intents / service registration | `android/app/src/main/AndroidManifest.xml` |
| iOS URL scheme | `ios/Runner/Info.plist` (`CFBundleURLTypes`) |
| Safari redirect logic | `ios/SafariExtension/Resources/content.js`, `background.js` |

## Do / don’t

**Do**

- Keep UI strings in English.
- Prefer `/shorts/{id}` detection; treat watch-page Shorts as best-effort.
- Keep the player as a **single** embed (no Shorts feed UI).
- Update directory READMEs when moving native intercept code.

**Don’t**

- Add MITM / decrypting VPN to inspect HTTPS paths.
- Intercept the YouTube **native app** (out of scope).
- Assume Chrome on iOS can use the Safari extension (it cannot).
- Commit secrets or store credentials.

## Commands

```bash
flutter pub get
flutter test
flutter analyze
flutter run -d android
flutter run -d ios
```

## Further reading

- Human product docs: [README.md](README.md)
- Dart layout: [lib/README.md](lib/README.md)
- Android: [android/README.md](android/README.md)
- iOS: [ios/README.md](ios/README.md)
