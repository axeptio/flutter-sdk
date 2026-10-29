# Consent Upload Tests

## Uploader

`test/network/axeptio_uploader_test.dart`, with `MockClient` and 20 ms
intervals.

| Test                                      | Proves                           |
| ----------------------------------------- | -------------------------------- |
| posts consent:saved payload to the app... | Proof URL, headers and body      |
| ignores a payload without a config...     | Malformed proof is not sent      |
| keeps the proof and retries until...      | 5xx and errors retry             |
| replays a persisted proof on start        | Proof survives a restart         |
| cancel stops retries and drops the...     | Withdrawal deletes the proof     |
| a newer proof supersedes the pending one  | Only the latest proof is pending |
| posts queued events as a JSON array...    | Events wait, then go as an array |
| ignores null events                       | Null payload is not queued       |
| sends batches of 20                       | Batches hold at most 20 events   |
| keeps unsent batches queued and retries   | Only acknowledged batches leave  |
| persists the queue and flushes it on...   | Queue survives a restart         |
| caps the persisted queue by dropping...   | Queue never exceeds 1000         |
| a concurrent flush is a no-op             | No double send                   |
| concurrent enqueues keep every event      | No event lost on interleaving    |

## SDK wiring

`test/webview/webview_axeptio_sdk_test.dart`.

| Test                                      | Proves                           |
| ----------------------------------------- | -------------------------------- |
| google consent maps every granted key...  | `"granted"` maps to `true`       |
| does nothing when brands consent already  | Brands reads `axeptio_cookies`   |
| does not accept a TC string as consent... | TC string ignored for brands     |
| shows consent for brands when...          | Empty brands consent shows UI    |
| consent:saved posts the proof until...    | Event reaches consents endpoint  |
| initialize replays a pending proof        | Restart resends the proof        |
| clearConsent cancels the pending proof    | Withdrawal deletes the proof     |
| analytics:collect queues the event        | Event is queued                  |
| analytics:collect is dropped when...      | No queueing when tracking denied |
| analytics:collect tags the event with...  | `sdk-app-*` becomes `sdk-<os>-*` |
| analytics:collect keeps a source it...    | Other sources pass unchanged     |
| consent:saved persists the page token     | Top-level `token` is stored      |

## Storage

`test/webview/tcf_storage_test.dart`.

| Test                                      | Proves                           |
| ----------------------------------------- | -------------------------------- |
| stores the top level token sent by the... | `token` feeds `AX_CLIENT_TOKEN`  |
| stores the token nested in the brands...  | `$$token` in a JSON string       |
| stores the nested token when cookies...   | `$$token` in a map               |
| prefers axeptio_token over the other...   | `axeptio_token` wins             |
| stores no token when the cookies payload  | No `$$token`, or not JSON        |
| stores the token nested in axeptio_coo... | `axeptio:cookies` stores token   |

Tests tagged `// test: regression` fail on 3.0.0 (MSK-301).
