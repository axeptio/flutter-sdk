# axeptio_sdk_example

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
  --dart-define=TCF_PROJECT_ID=your-tcf-project-id \
  --dart-define=TCF_VERSION="google cmp partner program sandbox-en-EU"
```

Non-TCF version with custom values
```bash
flutter build apk \
  --dart-define=FLAVOR=brand \
  --dart-define=NON_TCF_PROJECT_ID=your-non-tcf-project-id \
  --dart-define=NON_TCF_VERSION="your-non-tcf-version"
```

Or just use flavor with defaults
```bash
flutter build apk --dart-define=FLAVOR=tcf
flutter build apk --dart-define=FLAVOR=brand
```
## Run

### Launch a simulator

List devices: `flutter devices`
Launch an iOS Simulator: `open -a Simulator`


For development
```bash
flutter run --dart-define=FLAVOR=tcf
flutter run --dart-define=FLAVOR=brand
```

Finally, run the projet by running : 
```shell
flutter run -d "iPhone 16"
```

If you have any trouble or want more information, check the [online documentation](https://docs.flutter.dev/)
