# Consent Upload

The hosted page runs in `appSDKMode`: it neither saves consent nor sends
analytics. The SDK does both from the WebView bridge events.

## Uploads

Host `https://api.axept.io`. Headers `Content-Type: application/json` and
`User-Agent: AxeptioFlutterSDK (<os>; <os version>)`. Timeout 30 s.

| Event               | Path                                   | Cadence     |
| ------------------- | -------------------------------------- | ----------- |
| `consent:saved`     | `/v1/app/consents/{client}/cookies/ID` | Retry 300 s |
| `analytics:collect` | `/v1/analytics/evts`                   | 60 s, by 20 |

- `client` is the client id; `ID` is `preferences.config.identifier`.
- The proof body is the event payload as-is; it retries until 2xx.
- The analytics body is a JSON array of events.
- Event `source` `sdk-app-*` is sent as `sdk-ios-*` or `sdk-android-*`.

## Persistence

| SharedPreferences key           | Holds                   | Cleared on       |
| ------------------------------- | ----------------------- | ---------------- |
| `axeptio_pending_consent_proof` | Unacknowledged proof    | 2xx, withdrawal  |
| `axeptio_analytics_queue`       | Unsent events, max 1000 | 2xx per batch    |

`initialize()` replays a pending proof and flushes the queue in the
background.

## Rules

| Case                                  | Behaviour                         |
| ------------------------------------- | --------------------------------- |
| Proof without config identifier       | Not uploaded                      |
| New proof while one is pending        | Replaces it                       |
| `clearConsent()`                      | Stops retries, deletes the proof  |
| After `setUserDeniedTracking()`       | Analytics events are not queued   |

## Token

`AX_CLIENT_TOKEN` takes the first present of `axeptio_token`, `token`
(`consent:saved`) and `$$token` inside `axeptio_cookies`.

## Google Consent Mode

`google:consent-mode-v2-update` sends `"granted"` or `"denied"`. `"granted"`
maps to `true` in `ConsentsV2`, anything else to `false`. Optional keys such
as `functionality_storage` are ignored.

## Consent gating in setupUI

| Service      | Consent present when           |
| ------------ | ------------------------------ |
| `brands`     | `axeptio_cookies` is non-empty |
| `publishers` | `IABTCF_TCString` is non-empty |

Without consent, `setupUI()` calls `showConsentScreen()`.
