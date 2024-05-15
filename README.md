# axeptio_sdk

This repository demonstrates how to implement the Axeptio Flutter SDK in your mobile applications.

## Setup

### Installation

```shell
flutter pub add axeptio_sdk
```

### Android setup
- Min sdk 26
- Add maven github repository and credentials in your app's `android/build.gradle`
```groovy
repositories {
    maven {
        url = uri("https://maven.pkg.github.com/axeptio/tcf-android-sdk")
        credentials {
           username = "[GITHUB_USERNAME]"
           password = "[GITHUB_TOKEN]"
        }
   }
}
```
### iOS

We support iOS versions >= 15.
The sdk do not manage App Tracking Transparency, you can find more information [there](#app-tracking-transparency-att).

## Example

You can find a basic usage of the Axeptio SDK in the `example` folder.

## Usage
### Initialize the SDK on app start up:
```dart
final axeptioSdkPlugin = AxeptioSdk();
await axeptioSdkPlugin.initialize(  
  [your_client_id],  
  [your_cookies_version],  
  [optional_consent_token],
);
await axeptioSdkPlugin.setupUI()
```

### App Tracking Transparency (ATT)

To manage App Tracking Transparency, you can use the [app_tracking_transparency](https://pub.dev/packages/app_tracking_transparency) widget.

First, install it
```shell
flutter pub add app_tracking_transparency
```

Add `NSUserTrackingUsageDescription` to your Info.plist add file

```xml
<key>NSUserTrackingUsageDescription</key>
<string>Explain why you need user tracking</string>
```

You can now manage ATT popup before setup UI

```dart
try {
  TrackingStatus status =
      await AppTrackingTransparency.trackingAuthorizationStatus;
  // If the system can show an authorization request dialog
  if (status == TrackingStatus.notDetermined) {
    // Request system's tracking authorization dialog
    status = await AppTrackingTransparency.requestTrackingAuthorization();
  }

  if (status == TrackingStatus.denied) {
    // Call setUserDeniedTracking 
    await _axeptioSdkPlugin.setUserDeniedTracking();
  } else {
    // Run setupUI if accepted
    await _axeptioSdkPlugin.setupUI();
  }
} on PlatformException {
  // Run setupUI on android
  await _axeptioSdkPlugin.setupUI();
}
```

### Show consent popup on demand

Additionally, you can request the consent popup to open on demand.
```dart
axeptioSdk.showConsentScreen();
```

### Sharing consents with other web views
The SDK provides a helper function to append the `axeptio_token` query param to any URL.  
You can precise a custom user token or use the one currently stored in the SDK.

```dart  
final token = await axeptioSdk.axeptioToken;
final url = await axeptioSdk.appendAxeptioTokenURL(  
  "https://myurl.com",  
  token,  
); 
```  
Will return `https://myurl.com?axeptio_token=[token]`

### Clear user's consent choices

```dart  
axeptioSdk.clearConsent();
```

### Events

The Axeptio SDK triggers various events to notify you that the user has taken some action.

We provide an `AxeptioEventListener` class that can be use to catch events. Don't forget to add this listener to AxeptioSdk, as below.

```dart
var listener = AxeptioEventListener();
listener.onPopupClosedEvent = () {
  // The CMP notice is being hidden
  // Do something
};
listener.onConsentChanged = () {
  // The consent of the user changed
  // Do something
};
listener.onGoogleConsentModeUpdate = (consents) {
  // The Google Consent V2 status
  // Do something
};

// Add and remove listener as with the available methods
var axeptioSdk = AxeptioSdk()
axeptioSdkPlugin.addEventListerner(listener);
axeptioSdkPlugin.removeEventListener(listener);
```
