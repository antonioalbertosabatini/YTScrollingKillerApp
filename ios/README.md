# ios/ — deferred for scroll-block

## Current status

Android implements browser Shorts scroll-blocking via Accessibility overlay.

iOS Safari scroll-block (watch in Safari, popup on next Short, close tab) is **not** implemented yet. Existing `SafariExtension/` sources targeted an older “open in app” approach and should be redesigned before reuse.

## Custom URL scheme

`Runner/Info.plist` may still declare `ytsk://` from earlier work. It is unused by the Android scroll-block product path.

## When implementing iOS later

Prefer: Safari Web Extension detects `/shorts/{id}` change → inject blocking UI or redirect away from the Shorts feed → leave the current Short watchable until that change.
