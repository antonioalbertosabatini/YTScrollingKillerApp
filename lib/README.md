# lib/ — Flutter application code

## Layout

```text
lib/
  main.dart                 # WidgetsFlutterBinding + runApp
  app.dart                  # Theme (Session cut) + YtScrollingKillerApp → SetupScreen
  core/
    short_url_parser.dart   # URL helpers (unit-tested; not used for playback)
  features/
    setup/setup_screen.dart # Enable Accessibility; status + sticky CTA
```

## Role

The Flutter app is a **setup companion** with a dark Session cut UI (coral accent, Space Grotesk / DM Sans, soft vignette). Shorts playback and blocking happen in the browser via the Android Accessibility service — not via an in-app player. On Short id change the service pauses playback, then shows the overlay.

On Android the Setup screen polls `isAccessibilityServiceEnabled` and refreshes when the app resumes, so the Shorts Guard Off/On status stays current after returning from system settings.

## Testing

- Parser tests: `test/short_url_parser_test.dart`
- Smoke UI: `test/widget_test.dart`
