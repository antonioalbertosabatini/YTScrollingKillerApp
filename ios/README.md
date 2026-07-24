# ios/ — URL scheme + Safari Web Extension

## Purpose

On iOS, path-level Shorts detection in **Safari** is done with a Safari Web Extension. The extension redirects to the app custom scheme. Chrome on iOS is **not** supported by this path.

## Custom URL scheme

Registered in `Runner/Info.plist` as `CFBundleURLTypes`:

```text
ytsk://short/{videoId}
```

Handled in Flutter by `app_links` → `DeepLinkService`.

## Safari Web Extension

Sources live in `SafariExtension/`:

```text
SafariExtension/
  Info.plist
  SafariWebExtensionHandler.swift
  Resources/
    manifest.json
    background.js          # tabs.onUpdated → ytsk://
    content.js             # /shorts/ + best-effort Shorts UI → ytsk://
    _locales/en/messages.json
    images/icon-*.png
```

The **SafariExtension** app-extension target is part of `Runner.xcodeproj` and should be embedded under Runner (“Embed Foundation Extensions”).

Bundle id pattern: `com.ytscrollingkiller.ytscrollingKiller.SafariExtension`.

## Enable for local testing

1. `flutter run -d ios` (or open `ios/Runner.xcworkspace` in Xcode and run).
2. On the simulator/device: Settings → Apps → Safari → Extensions.
3. Enable **YTScrollingKiller** and grant permission for YouTube.
4. Open a Short in Safari and confirm redirect into the app.

## Known limits

- Safari only (not Chrome iOS).
- `content.js` treats `/shorts/{id}` as authoritative.
- Opening `App-prefs:` from the Setup screen is best-effort and may be ignored by the Simulator.
- Full **Xcode.app** is required for `flutter build ios` / `flutter run -d ios` (Command Line Tools alone are not enough).
- The SafariExtension target uses a **Copy Safari Extension Resources** script phase so `manifest.json`, scripts, `_locales`, and `images` land at the appex root.
