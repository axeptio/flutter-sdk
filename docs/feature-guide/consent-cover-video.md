# Consent Cover Video

The consent widget shows a muted, looping cover video. It starts it with
one `play()` call, without a user gesture.

The consent webview allows that on both platforms, so the cover plays
instead of rendering as an empty block. No integrator configuration is
needed.

- iOS, `AxeptioConsentWebView.swift`:
  - `allowsInlineMediaPlayback = true`
  - `mediaTypesRequiringUserActionForPlayback = []`
- Android, `lib/src/webview/axeptio_consent_view.dart`:
  - `setMediaPlaybackRequiresUserGesture(false)`, applied before load
