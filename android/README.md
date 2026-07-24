# android/ — Shorts scroll-block

## Purpose

Allow one YouTube Short in a mobile browser. When the Shorts video id changes (swipe / related / autoplay), pause playback, show a full-screen Accessibility overlay, and close the tab.

## Key files

| File | Role |
|------|------|
| `app/src/main/kotlin/.../ShortsAccessibilityService.kt` | State machine + pause + overlay + close tab |
| `app/src/main/res/layout/scroll_block_overlay.xml` | Blocking UI |
| `app/src/main/res/drawable/scroll_block_*.xml` | Panel / button shapes |
| `app/src/main/res/values/strings.xml` | English copy + service description |
| `app/src/main/kotlin/.../MainActivity.kt` | MethodChannel `openAccessibilitySettings` |
| `app/src/main/AndroidManifest.xml` | Service registration |
| `app/src/main/res/xml/shorts_accessibility_service.xml` | Accessibility service config (`canPerformGestures`) |

## State machine

1. **Idle** → URL is `/shorts/{id}` → **Watching** (silent; remember id).
2. **Watching** → same id → stay watching.
3. **Watching** → different Shorts id → **Blocked** (pause playback, then show overlay).
4. **Watching** → left Shorts → **Idle**.
5. **Blocked** → user taps **Close tab** → close tab (or YouTube Home fallback) → **Idle**.

## Pause on block

Before the overlay is shown:

1. Try Accessibility click on Pause controls.
2. Fallback: center-screen tap gesture (`dispatchGesture`).
3. Backup: transient audio focus request to interrupt browser media audio.

The overlay is shown only after pause attempts settle, so gestures hit the browser — not the overlay.

## Overlay

Uses `WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY`. Not dismissible except via **Close tab**. Fade + slide-in animation on show.

## Watched browsers

Configured in `ShortsAccessibilityService.WATCHED_PACKAGES`.

## How to rebuild / test

```bash
./scripts/open_android_studio.sh
# or: flutter run
```

1. Enable **YTScrollingKiller Shorts Guard** in Accessibility settings.
2. Open one Short in Chrome — stays in Chrome.
3. Swipe / related / autoplay → pause + overlay.
4. Tap **Close tab**.

## MethodChannel

- Name: `com.ytscrollingkiller.ytscrolling_killer/accessibility`
- Method: `openAccessibilitySettings`
