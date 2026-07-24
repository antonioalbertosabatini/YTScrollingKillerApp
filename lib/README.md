# lib/ — Flutter application code

## Layout

```text
lib/
  main.dart                 # WidgetsFlutterBinding + runApp
  app.dart                  # YtScrollingKillerApp → SetupScreen
  core/
    short_url_parser.dart   # URL helpers (unit-tested; not used for playback)
  features/
    setup/setup_screen.dart # Enable Accessibility; explain scroll-block
```

## Role

The Flutter app is a **setup companion** with a dark Session cut UI. Shorts playback and blocking happen in the browser via the Android Accessibility service — not via an in-app player. On Short id change the service pauses playback, then shows the overlay.

## Testing

- Parser tests: `test/short_url_parser_test.dart`
- Smoke UI: `test/widget_test.dart`
