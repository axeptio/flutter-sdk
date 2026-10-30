# Consent View Tests

File: `test/webview/axeptio_consent_view_test.dart`.

- `Android media playback` / `lets the cover video autoplay before the
  page loads`: the Android controller gets
  `setMediaPlaybackRequiresUserGesture(false)` before `loadRequest`, and
  document-start script registration still runs.

The test swaps `WebViewPlatform.instance` for a recording
`AndroidWebViewController` fake that mixes in `MockPlatformInterfaceMixin`.
