# Consent view document-start tests

Suite: `test/webview/axeptio_consent_view_test.dart`.

## Android document-start injection

- **registers bridge and localStorage before loadRequest**: one
  registration before `loadRequest`, origin `https://<host>`, script holds
  every seed key and the polyfill.
- **skips runJavaScript injection when registered**: no `runJavaScript`
  on `onPageStarted` or `onPageFinished`.
- **falls back to runJavaScript when unsupported**: registrar `false`
  still loads and injects.
- **falls back to runJavaScript when registration throws**: loads,
  injects, reports no error.
- **does not load when disposed during registration**: no `loadRequest`
  after dispose.
- **default registrar returns false for non-Android controller**: the
  channel is never reached.

## addDocumentStartScriptOnNative

- **sends webview id, script and origin to the plugin**: method name and
  arguments.
- **treats a null reply as unsupported**: `null` maps to `false`.

## Changed

- **loadRequest is called with consent URL**: pumps once, since
  `loadRequest` now follows registration.

## Kotlin

`android/src/test/kotlin/io/axept/axeptio_sdk/AxeptioSdkPluginTest.kt`:

- **onMethodCall_addDocumentStartScript_withoutEngine_returnsFalse**: no
  engine attached replies `false`.
