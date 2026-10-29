# Android document-start injection

The Android consent page needs `window.axeptioAppSdk` and its
`localStorage` seed before its first script runs.

## Flow

1. `AxeptioConsentView` builds one script: `localStorage` seed plus the
   `axeptioAppSdk` polyfill.
2. Dart calls `addDocumentStartScript` on the `axeptio_sdk` channel with
   the WebView id, the script and the origin.
3. Native resolves the WebView through `WebViewFlutterAndroidExternalApi`
   and calls `WebViewCompat.addDocumentStartJavaScript`.
4. `loadRequest` runs once step 2 has returned.
5. When registered, `onPageStarted` and `onPageFinished` skip injection.

## Seeded keys

| Key                         | Value                          |
| --------------------------- | ------------------------------ |
| `_ax_app_sdk_mode`          | `true`                         |
| `_ax_user_cookies_duration` | `190`                          |
| `_ax_app_att_denied`        | `true`, only when ATT denied   |
| `_ax_tcstring`              | stored TC string, when present |

## Fallback

The channel replies `false`, or throws, when:

- the controller is not an `AndroidWebViewController`;
- `WebViewFeature.DOCUMENT_START_SCRIPT` is unsupported;
- the WebView cannot be resolved;
- `addDocumentStartJavaScript` rejects the origin rule.

The view then injects with `runJavaScript` at `onPageStarted` and retries
at `onPageFinished`.

## Origin rule

The script runs only on `https://<consent URL host>`, never on `*`.

## Dependencies

- `webview_flutter_android` in `pubspec.yaml`.
- `androidx.webkit:webkit` in `android/build.gradle`.
