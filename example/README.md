# Axeptio Flutter SDK Example App

This project demonstrates the basic usage of the axeptio_sdk plugin.

## Getting Started

First, be sure you have Flutter installed. If not follow these [instructions](https://docs.flutter.dev/get-started/install).

Then, install dependencies by running :
```shell
flutter pub get
```
## Build

TCF version with custom values
```bash
flutter build apk \
  --dart-define=FLAVOR=tcf \
  --dart-define=PROJECT_ID=your-tcf-project-id \
  --dart-define=VERSION="google cmp partner program sandbox-en-EU"
```

Non-TCF version with custom values
```bash
flutter build apk \
  --dart-define=FLAVOR=brand \
  --dart-define=PROJECT_ID=your-non-tcf-project-id \
  --dart-define=VERSION="your-non-tcf-version"
```

Or just use flavor with defaults
```bash
flutter build apk --dart-define=FLAVOR=publishers
flutter build apk --dart-define=FLAVOR=brands
```
## Run

### Launch a simulator

- List devices: `flutter devices`<br>
- List emulators: `flutter emulators`<br>
- List Android: `emulator -list-avds`<br>
- Launch an iOS Simulator: `open -a Simulator` or `flutter emulators --launch ios`<br>
- Launch an Android Simulator: `flutter emulators --launch Pixel_9` or `flutter emulators --launch android`<br>

### Launch the app

For development
```bash
flutter run --dart-define=FLAVOR=publishers
flutter run --dart-define=FLAVOR=brands
```

Finally, run the projet by running, default flavor is brands
```shell
flutter run -d "iPhone 16"
```

### Uninstall the app

```shell
flutter install --uninstall-only
```

If you have any trouble or want more information, check the [online documentation](https://docs.flutter.dev/)
