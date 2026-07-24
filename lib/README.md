# lib/ — Flutter application code

## Layout

```text
lib/
  main.dart                 # WidgetsFlutterBinding + runApp
  app.dart                  # YtScrollingKillerApp: navigator + deep-link → PlayerScreen
  core/
    short_url_parser.dart   # URL → video id; isShortsUrl / extractShortsVideoId
    deep_links.dart         # AppLinks subscription → Stream<videoId>
  features/
    setup/setup_screen.dart # Enable Accessibility / Safari extension; manual URL open
    player/player_screen.dart # WebView IFrame single video + YouTube Home CTA
```

## Navigation flow

1. App starts on `SetupScreen`.
2. `DeepLinkService` emits video ids from `ytsk://short/{id}` or Shorts https links.
3. `YtScrollingKillerApp` pushes `PlayerScreen(videoId:)`.
4. **Go to YouTube Home** launches `https://www.youtube.com/` externally and pops to root.

## Player notes

- Embed HTML is inlined in `PlayerScreen` (IFrame API + `youtube-nocookie.com`).
- Reference asset: `assets/youtube_embed.html`.
- Scroll/touchmove is blocked in the embed page; related Shorts navigations are prevented when possible.

## Testing

- Parser tests: `test/short_url_parser_test.dart`
- Smoke UI: `test/widget_test.dart`
