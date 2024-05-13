# axeptio_sdk

This repository demonstrates how to implement the Axeptio Flutter SDK in your mobile applications.

## Flutter setup

## Android setup
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
## iOS setup

## Usage
### Initialize the SDK on app start up:
```dart
final axeptioSdkPlugin = AxeptioSdk();
await axeptioSdkPlugin.initialize(  
  [your_client_id],  
  [your_cookies_version],  
  [optional_consent_token],
);
```
//TODO setupUI(), setUserDeniedTracking() for ios
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

### Popup events