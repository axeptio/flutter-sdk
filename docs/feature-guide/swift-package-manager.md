# Swift Package Manager

The iOS plugin builds with Swift Package Manager or CocoaPods. Flutter
picks one per app.

## Layout

- `ios/axeptio_sdk/Package.swift`: package `axeptio_sdk`, product
  `axeptio-sdk`, iOS 15.
- `ios/axeptio_sdk/Sources/axeptio_sdk/`: plugin Swift sources.
- `ios/axeptio_sdk.podspec`: CocoaPods spec, `source_files` points at the
  sources above.

## Enable in an app

```bash
flutter config --enable-swift-package-manager
flutter build ios
```

Without the flag, Flutter keeps using CocoaPods and the podspec.
