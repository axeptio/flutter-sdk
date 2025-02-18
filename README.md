# axeptio_sdk

This repository demonstrates how to implement the Axeptio Flutter SDK in your mobile applications.

This module can be build with `brands` or `publishers` given your requirements.

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
        url = uri("https://maven.pkg.github.com/axeptio/axeptio-android-sdk")
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

## Sample

You can find a basic usage of the Axeptio SDK in the `example` folder.
Read the specific [documentation](./example/README.md).

## Usage
### Initialize the SDK on app start up:

The SDK can be configured for either brands or publishers via the AxeptioService enum during initialization.

```dart
final axeptioSdkPlugin = AxeptioSdk();
await axeptioSdkPlugin.initialize(  
   AxeptioService.brands, // or  AxeptioService.publishers
  [your_client_id],  
  [your_cookies_version],  
  [optional_consent_token],
);
await axeptioSdkPlugin.setupUI()
```

### App Tracking Transparency (ATT)

The Axeptio SDK does not ask for the user permission for tracking in the ATT framework and it is the responsibility of the app to do so and to decide how the Axeptio CMP and the ATT permission should coexist.

Your app must follow [Apple's guidelines](https://developer.apple.com/app-store/user-privacy-and-data-use/) for disclosing the data collected by your app and asking for the user's permission for tracking.

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

### Responsibilities: Mobile App vs SDK

The Axeptio SDK and your mobile application have distinct responsibilities in managing user consent and tracking:

#### Mobile Application Responsibilities:
- Implementing and managing the App Tracking Transparency (ATT) permission flow
- Deciding when to show the ATT prompt relative to the Axeptio CMP
- Properly declaring data collection practices in App Store privacy labels
- Handling SDK events and updating app behavior based on user consent

#### Axeptio SDK Responsibilities:
- Displaying the consent management platform (CMP) interface
- Managing and storing user consent choices
- Sending consent status through APIs

The SDK does not automatically handle ATT permissions - this must be explicitly managed by the host application as shown in the implementation examples above.

### Get stored consents

You can retrieve the consents that are stored by the SDK in UserDefaults/SharedPreferences.

To access UserDefaults/SharedPreferences, you can use the [shared_preferences](https://pub.dev/packages/shared_preferences) library.

For detailed information about stored values and cookies, please refer to the [Axeptio documentation](https://support.axeptio.eu/hc/en-gb/articles/8558526367249-Does-Axeptio-deposit-cookies).

### Show consent popup on demand

Additionally, you can request the consent popup to open on demand.
```dart
axeptioSdk.showConsentScreen();
```

### Sharing consents with other web views
>*This feature is only available for **publishers** service.*

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
  // Retrieve consents from UserDefaults/SharedPreference
  // Check user preferences
  // Run external process/services according user consents
};

listener.onGoogleConsentModeUpdate = (consents) {
  // The Google Consent V2 status
  // Do something
};

listener.onConsentCleared = () {
  // The consent of the user has been cleared
  // Do something
};

// Add and remove listener as with the available methods
var axeptioSdk = AxeptioSdk()
axeptioSdkPlugin.addEventListerner(listener);
axeptioSdkPlugin.removeEventListener(listener);
```
