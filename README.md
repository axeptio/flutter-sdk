<img src="https://github.com/user-attachments/assets/e3af712d-45ce-4b80-896e-a8d878bffc51" width="600" height="300"/>



# Axeptio Flutter SDK Documentation


[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![Android SDK Version](https://img.shields.io/badge/Android%20SDK-%3E%3D%2026-blue)](https://developer.android.com/studio) [![iOS Version Support](https://img.shields.io/badge/iOS%20Version-%3E%3D%2015.0-blue)](https://developer.apple.com) [![Axeptio Flutter SDK Version](https://img.shields.io/github/v/release/axeptio/flutter-sdk)](https://github.com/axeptio/flutter-sdk/releases) [![Flutter Version](https://img.shields.io/badge/flutter-%3E%3D%203.3.0-blue)](https://flutter.dev) [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/axeptio/flutter-sdk/pulls)







This repository demonstrates the integration of the **Axeptio Flutter SDK** into mobile applications, enabling seamless consent management for both brands and publishers, tailored to your specific requirements.
<br><br>
## Table of Contents
1. [Setup and Installation](#setup-and-installation)
   - [Android Setup](#android-setup)
   - [iOS Setup](#ios-setup)
2. [SDK Initialization](#sdk-initialization)
3. [App Tracking Transparency (ATT) Integration](#app-tracking-transparency-att-integration)
4. [SDK and Mobile App Responsibilities](#sdk-and-mobile-app-responsibilities)
5. [Retrieving and Managing Stored Consents](#retrieving-and-managing-stored-consents)
6. [TCF Vendor Consent Management](#tcf-vendor-consent-management)
7. [Displaying the Consent Popup on Demand](#displaying-the-consent-popup-on-demand)
8. [Sharing Consents with Web Views](#sharing-consents-with-web-views)
9. [Clearing User Consent](#clearing-user-consent)
10. [Event Handling and Customization](#event-handling-and-customization)
    - [Event Source Identification](#event-source-identification)
11. [Testing and Development](#testing-and-development)
12. [Local Test](#local-test)
<br><br><br>
## Setup and Installation   
To integrate the Axeptio SDK into your Flutter project, run the following command in your terminal:
```bash
flutter pub add axeptio_sdk
```
This command will automatically add the `axeptio_sdk` dependency to your `pubspec.yaml` file and download the latest available version. After running this command, the SDK will be ready for use in your Flutter project.

Alternatively, you can manually add the dependency to your `pubspec.yaml` under the dependencies section:
```yaml
dependencies:
  flutter:
    sdk: flutter
  axeptio_sdk: ^2.0.15
```

### Android Setup
##### Minimum SDK Version
To ensure compatibility with the Axeptio SDK, the **minimum SDK** version for your Flutter project must be set to **API level 26** (Android 8.0 Oreo) or higher. To verify and update this setting, open your project's `android/app/build.gradle` file and check the following:
```gradle
android {
    defaultConfig {
        minSdkVersion 26 // Ensure this is set to 26 or higher
    }
}
```
##### Add Maven Repository and Credentials
In order to download and include the Axeptio SDK, you'll need to configure the Maven repository and authentication credentials in your `android/build.gradle` file. Follow these steps:
1. Open the `android/build.gradle` file in your Flutter project.
2. In the `repositories block`, add the Axeptio Maven repository URL and the required credentials for authentication.

Here is the necessary configuration to add:
```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://maven.pkg.github.com/axeptio/axeptio-android-sdk")
            credentials {
                username = System.getenv("GITHUB_USERNAME") ?: project.findProperty("github.username") as String? ?: ""
                password = System.getenv("GITHUB_TOKEN") ?: project.findProperty("github.token") as String? ?: ""
            }
        }
    }
}
```
##### GitHub Authentication & Security Setup

⚠️ **SECURITY CRITICAL**: Never hardcode credentials in your build files or commit them to version control.

**Step 1: Generate GitHub Token**
1. Visit GitHub and navigate to **Settings > Developer settings > Personal access tokens**.
2. Click **Generate new token** and select permissions (minimum: `read:packages`).
3. Copy the generated token immediately (you won't see it again).

**Step 2: Configure Environment Variables**
Set up your credentials using **environment variables** (recommended) or **gradle.properties**:

**Option A: Environment Variables (Recommended)**
```bash
export GITHUB_USERNAME=your_github_username
export GITHUB_TOKEN=your_generated_token
```

**Option B: gradle.properties (Alternative)**
Create `~/.gradle/gradle.properties` or `android/gradle.properties`:
```properties
github.username=your_github_username
github.token=your_generated_token
```

**Step 3: Update .gitignore**
Ensure your `.gitignore` includes:
```gitignore
# Gradle credentials
gradle.properties
local.properties
```

> **🔒 Security Best Practices:**
> - Never commit credentials to version control
> - Rotate tokens regularly (quarterly recommended)  
> - Use minimal required permissions
> - Consider using CI/CD environment variables for builds

##### Sync Gradle
Once you've added the repository and credentials, sync your Gradle files by either running:
```bash
flutter pub get
```
Or manually through Android Studio by clicking **File > Sync Project** with Gradle Files.

This will allow your project to fetch the necessary dependencies from the Axeptio Maven repository.

> **🏭 Production Deployment Notice:**
> For production builds, ensure you have configured CI/CD environment variables and never include credentials in your app bundle. Consider using build flavors for different environments.

### iOS Setup
##### Minimum iOS Version
The Axeptio SDK supports **iOS versions 15.0 and higher**. To ensure compatibility with the SDK, make sure your project is set to support at least iOS 15.0. To check or update the minimum iOS version, open the `ios/Podfile` and ensure the following line is present:

```ruby
platform :ios, '15.0'
```
This ensures that your app targets devices running iOS 15 or later.

<br><br><br>
## SDK Initialization
To initialize the Axeptio SDK on app startup, select either **brands** or **publishers** depending on your use case. The SDK is `initialized` through the AxeptioService enum and requires your `client_id`, `cookies_version`, and optionally a `consent_token`.

### Brands

```dart
final axeptioSdkPlugin = AxeptioSdk();
await axeptioSdkPlugin.initialize(
    AxeptioService.brands, // Choose either brands or publishers
    "your_client_id",  // Your client ID
    "your_cookies_version",  // Version of your cookies policy
    "optional_consent_token",  // Optionally pass a consent token for existing user consent
);
await axeptioSdkPlugin.setupUI();  // Setup the UI for consent management
```

### Publisher (TCF)

```dart
final axeptioSdkPlugin = AxeptioSdk();
await axeptioSdkPlugin.initialize(
    AxeptioService.publishers, // Choose either brands or publishers
    "your_client_id",  // Your client ID
    "your_cookies_version",  // Version of your cookies policy
    "optional_consent_token",  // Optionally pass a consent token for existing user consent
);
await axeptioSdkPlugin.setupUI();  // Setup the UI for consent management
```

The **setupUI()** function will display the consent management UI once initialized.
<br><br><br>
## App Tracking Transparency (ATT) Integration
The **Axeptio SDK** does not manage **App Tracking Transparency** (ATT) permissions. It is the responsibility of the host app to manage the **ATT** flow, ensuring that the user is prompted before consent management is handled by the SDK.
##### Steps for Integrating ATT with Axeptio SDK:
1. **Add Permission Description in `Info.plist`:**
In your iOS project, add the following key to `Info.plist` to explain why the app requires user tracking:
```xml
<key>NSUserTrackingUsageDescription</key>
<string>Explain why you need user tracking</string>
```
2. **Install App Tracking Transparency Plugin:**
```bash
flutter pub add app_tracking_transparency
```
3. **Request Tracking Authorization:**
Use the **AppTrackingTransparency** plugin to request permission before initializing the **Axeptio SDK's** consent UI. The flow checks the user’s status and takes appropriate actions based on their choice. 
```dart
try {
  TrackingStatus status = await AppTrackingTransparency.trackingAuthorizationStatus;

  // If the status is not determined, show the system's ATT request dialog
  if (status == TrackingStatus.notDetermined) {
    status = await AppTrackingTransparency.requestTrackingAuthorization();
  }

  // If the user denied tracking, update consent status accordingly
  if (status == TrackingStatus.denied) {
    await axeptioSdkPlugin.setUserDeniedTracking();
  } else {
    // Proceed with the consent UI setup
    await axeptioSdkPlugin.setupUI();
  }
} on PlatformException {
  // On Android, skip ATT dialog and proceed with the UI setup directly
  await axeptioSdkPlugin.setupUI();
}
```
<br><br><br>
## SDK and Mobile App Responsibilities

The Axeptio SDK and your mobile application each have distinct responsibilities in the consent management process:

#### Mobile App Responsibilities:

1. **Implementing ATT Flow**  
   Your app must handle the App Tracking Transparency (ATT) permission request and manage the display of the ATT prompt at the appropriate time relative to the Axeptio CMP.

2. **Privacy Declaration**  
   The app must declare data collection practices accurately in App Store privacy labels.

3. **Handling SDK Events**  
   The app should listen for events triggered by the SDK and adjust its behavior based on user consent status.

#### Axeptio SDK Responsibilities:

1. **Consent Management UI**  
   The SDK is responsible for displaying the consent management interface.

2. **Storing and Managing User Consent**  
   It stores and manages consent choices across sessions.

3. **API Integration**  
   The SDK communicates user consent status through its API endpoints.

**Note:** The SDK does not manage ATT permissions. You must handle this separately as shown above.

<br><br><br>
## Retrieving and Managing Stored Consents

To retrieve stored consent choices, use **UserDefaults** (iOS) with the `shared_preferences` package.

##### Dart Example

```dart
import 'package:shared_preferences/shared_preferences.dart';

// Access stored consents
SharedPreferences prefs = await SharedPreferences.getInstance();
String userConsent = prefs.getString('axeptio_consent');
```
To retrieve stored consent choices, you can access the native preferences directly through the SDK using the following method:

```dart
import 'package:axeptio_sdk/axeptio_sdk.dart';

final result = await NativeDefaultPreferences.getDefaultPreference(
  "axeptio_cookies",
);
print(result);
```
You can use any of the following keys depending on your needs:

##### Brand Keys
```dart
// Access brand-specific consent data
final cookies = await NativeDefaultPreferences.getDefaultPreference('axeptio_cookies');
final allVendors = await NativeDefaultPreferences.getDefaultPreference('axeptio_all_vendors');
final authorizedVendors = await NativeDefaultPreferences.getDefaultPreference('axeptio_authorized_vendors');
```

##### TCF Keys  
```dart
// Access TCF (Transparency & Consent Framework) data
final tcString = await NativeDefaultPreferences.getDefaultPreference('IABTCF_TCString');
final vendorConsents = await NativeDefaultPreferences.getDefaultPreference('IABTCF_VendorConsents');
final gdprApplies = await NativeDefaultPreferences.getDefaultPreference('IABTCF_gdprApplies');
```

##### Bulk Operations
```dart
// Get multiple preferences at once
final preferences = await NativeDefaultPreferences.getDefaultPreferences([
  'IABTCF_TCString',
  'axeptio_cookies',
  'IABTCF_gdprApplies'
]);

// Get all available preferences
final allPrefs = await NativeDefaultPreferences.getAllDefaultPreferences();
```

##### Available Keys
All supported preference keys are available as static lists:
```dart
// Access predefined key lists
print('Brand keys: ${NativeDefaultPreferences.brandKeys}');
print('TCF keys: ${NativeDefaultPreferences.tcfKeys}');
print('All supported keys: ${NativeDefaultPreferences.allKeys}');
```
> ⚠️ **Note for Android:** On Android, the SDK stores consent data in native preferences. 
> Using `SharedPreferences.getInstance()` may return `null` if the consent popup was not accepted or if the storage is not shared with Flutter.
> For reliable results, use `NativeDefaultPreferences.getDefaultPreference()` instead.

<br><br><br>
## TCF Vendor Consent Management

The Axeptio SDK provides comprehensive **TCF (Transparency & Consent Framework)** vendor consent management APIs, allowing you to programmatically access and analyze user consent decisions for individual vendors.

> 📱 **Platform Support**: Available on **both iOS and Android** platforms.

### Available APIs

#### Get All Vendor Consents
Returns a complete mapping of vendor IDs to their consent status:

```dart
import 'package:axeptio_sdk/axeptio_sdk.dart';

// Get all vendor consents as a map
Map<int, bool> vendorConsents = await axeptioSdk.getVendorConsents();

// Example output: {1: true, 2: false, 50: true, 755: false}
print('Total vendors: ${vendorConsents.length}');

// Iterate through all vendor consents
vendorConsents.forEach((vendorId, isConsented) {
  print('Vendor $vendorId: ${isConsented ? "Consented" : "Refused"}');
});
```

#### Get Consented Vendors
Returns a list of vendor IDs that have been granted consent:

```dart
// Get list of consented vendor IDs
List<int> consentedVendors = await axeptioSdk.getConsentedVendors();

print('Consented vendors: $consentedVendors');
print('Number of consented vendors: ${consentedVendors.length}');

// Check if specific vendors are in the consented list
if (consentedVendors.contains(1)) {
  print('Google (Vendor ID 1) has consent');
}
```

#### Get Refused Vendors
Returns a list of vendor IDs that have been refused consent:

```dart
// Get list of refused vendor IDs
List<int> refusedVendors = await axeptioSdk.getRefusedVendors();

print('Refused vendors: $refusedVendors');
print('Number of refused vendors: ${refusedVendors.length}');
```

#### Check Individual Vendor Consent
Check the consent status of a specific vendor:

```dart
// Check consent for specific vendor IDs
bool googleConsent = await axeptioSdk.isVendorConsented(1);    // Google
bool facebookConsent = await axeptioSdk.isVendorConsented(2);  // Facebook
bool appleConsent = await axeptioSdk.isVendorConsented(755);   // Apple

print('Google consent: ${googleConsent ? "✅ Granted" : "❌ Refused"}');
print('Facebook consent: ${facebookConsent ? "✅ Granted" : "❌ Refused"}');
print('Apple consent: ${appleConsent ? "✅ Granted" : "❌ Refused"}');
```

### Practical Usage Examples

#### Conditional Feature Loading
```dart
Future<void> loadFeatureBasedOnConsent() async {
  // Check if advertising vendor has consent
  bool adConsentGranted = await axeptioSdk.isVendorConsented(50);
  
  if (adConsentGranted) {
    // Load advertising SDK
    await initializeAdvertisingSDK();
  } else {
    print('Advertising consent not granted - skipping ad initialization');
  }
}
```

#### Vendor Consent Analytics
```dart
Future<void> analyzeVendorConsents() async {
  // Get comprehensive vendor consent data
  Map<int, bool> allConsents = await axeptioSdk.getVendorConsents();
  List<int> consented = await axeptioSdk.getConsentedVendors();
  List<int> refused = await axeptioSdk.getRefusedVendors();
  
  // Calculate consent statistics
  double consentRate = consented.length / allConsents.length;
  
  print('📊 Consent Analytics:');
  print('Total vendors: ${allConsents.length}');
  print('Consented: ${consented.length}');
  print('Refused: ${refused.length}');
  print('Consent rate: ${(consentRate * 100).toStringAsFixed(1)}%');
  
  // Log specific vendor categories
  List<int> adTechVendors = [1, 2, 50, 100]; // Example ad tech vendor IDs
  List<int> consentedAdTech = adTechVendors.where(
    (id) => consented.contains(id)
  ).toList();
  
  print('Ad Tech vendors consented: $consentedAdTech');
}
```

#### Integration with Privacy Settings UI
```dart
Widget buildVendorConsentList() {
  return FutureBuilder<Map<int, bool>>(
    future: axeptioSdk.getVendorConsents(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return CircularProgressIndicator();
      
      final vendorConsents = snapshot.data!;
      
      return ListView.builder(
        itemCount: vendorConsents.length,
        itemBuilder: (context, index) {
          final vendorId = vendorConsents.keys.elementAt(index);
          final isConsented = vendorConsents[vendorId]!;
          
          return ListTile(
            title: Text('Vendor $vendorId'),
            trailing: Icon(
              isConsented ? Icons.check_circle : Icons.cancel,
              color: isConsented ? Colors.green : Colors.red,
            ),
            subtitle: Text(isConsented ? 'Consented' : 'Refused'),
          );
        },
      );
    },
  );
}
```

### Error Handling

The vendor consent APIs include built-in error handling:

```dart
Future<void> safeVendorConsentCheck() async {
  try {
    // APIs return empty collections on error (never null)
    Map<int, bool> consents = await axeptioSdk.getVendorConsents();
    
    if (consents.isEmpty) {
      print('No vendor consent data available');
      // Handle case where no consent data exists
    } else {
      print('Successfully retrieved ${consents.length} vendor consents');
    }
  } catch (e) {
    print('Error retrieving vendor consents: $e');
    // Handle any unexpected errors
  }
}
```

### Platform Compatibility

| Method | iOS | Android |
|--------|-----|---------|
| `getVendorConsents()` | ✅ Available | ✅ Available |
| `getConsentedVendors()` | ✅ Available | ✅ Available |  
| `getRefusedVendors()` | ✅ Available | ✅ Available |
| `isVendorConsented()` | ✅ Available | ✅ Available |

> 📝 **Note**: All vendor consent APIs are fully supported on both iOS and Android platforms.

<br><br><br>
## Displaying the Consent Popup on Demand
If needed, you can display the consent popup manually by calling the following method:
```dart
axeptioSdk.showConsentScreen();
```
This is useful if you want to show the popup at a specific moment based on app flow or user behavior.

<br><br><br>
## Sharing Consents with Web Views
For **publishers**, the SDK provides a feature to share the user's consent status with web views by appending the **Axeptio token** as a query parameter.
```dart
final token = await axeptioSdk.axeptioToken;
final url = await axeptioSdk.appendAxeptioTokenURL(  
  "https://myurl.com",  
  token,  
); 
// Will return: https://myurl.com?axeptio_token=[token]
```
This feature ensures that consent status is properly communicated across different parts of the application, including web content.
<br><br><br>

## Clearing User Consent
If necessary, you can clear the user’s consent choices by invoking the following method:
```dart
axeptioSdk.clearConsent();
```
This will reset the consent status, allowing the user to be prompted for consent again.

<br><br><br>

## Event Handling and Customization
The **Axeptio SDK** triggers various events that notify your app when the user takes specific actions related to consent. Use the `AxeptioEventListener` class to listen for these events and handle them as needed.
##### Example Event Listener Implementation:
```dart
var listener = AxeptioEventListener();

// Event triggered when the user closes the consent popup
listener.onPopupClosedEvent = () {
  // Retrieve consents from SharedPreferences/UserDefaults
  // Handle actions based on the user's consent preferences
};

// Event triggered when Google Consent Mode is updated
listener.onGoogleConsentModeUpdate = (consents) {
  // Handle updates to Google Consent Mode status
  // Perform specific actions based on updated consents
};

// Add and remove event listeners as necessary
var axeptioSdk = AxeptioSdk();
axeptioSdkPlugin.addEventListener(listener);
axeptioSdkPlugin.removeEventListener(listener);
```
<br><br><br>

### Event Source Identification

Events sent from the SDK (including those triggered via the internal WebView) include an `event_source` value to distinguish between App and Web contexts. This ensures analytics and KPIs are correctly attributed in the Axeptio back office.

The following values are used:

- `sdk-app-tcf`: TCF popup inside mobile apps.
- `sdk-web-tcf`: TCF popup in web browsers.
- `sdk-app-brands`: Brands widget loaded in apps.
- `sdk-web`: Brands widget on websites.

This tagging is handled automatically by the native SDK components used under the hood in the Flutter module.
<br><br><br>

## Testing and Development

The Axeptio Flutter SDK includes comprehensive test coverage to ensure reliability and catch regressions. 

### Current Test Coverage
- **Coverage**: 58.9% (122/207 lines covered)
- **Target**: 95% coverage requirement 
- **Tests**: 85 comprehensive tests
- **Status**: ⚠️ Coverage below target - improvement in progress

[![Test Coverage](https://img.shields.io/badge/coverage-58.9%25-orange)](TESTING.md)

### Quick Testing Commands

```bash
# Run all tests
flutter test

# Run tests with coverage report
flutter test --coverage

# Run specific test category
flutter test test/events/
flutter test test/model/
flutter test test/preferences/
```

### Test Structure
Our test suite is organized into logical components:
- **Core SDK Tests**: Initialization, UI management, consent handling
- **Method Channel Tests**: Platform communication and vendor consent APIs  
- **Event System Tests**: Event listeners and callback handling
- **Model Tests**: Data validation and type conversion
- **Native Preferences Tests**: Cross-platform preference access

### For Contributors
- **Required**: All new features must include comprehensive tests
- **Coverage**: Maintain or improve overall test coverage
- **Patterns**: Follow established mock platform and testing patterns
- **Validation**: All tests must pass before PR acceptance

For detailed testing information, patterns, and coverage improvement strategies, see [TESTING.md](TESTING.md).

<br><br><br>

## Local Test

### To test a bug fix
1. Clone the `flutter-sdk` repository.
2. Switch to the branch you want to test.
3. Configure the widget in the sample app for either **iOS** or **Android**.

### To test the version in production
- Checkout the master branch.

### Change native SDK version
#### Android 
In `android/build.gradle`, update the dependencies:
```gradle
dependencies {
    implementation("io.axept.android:android-sdk:2.0.8")
}
```
#### iOS
In `ios/axeptio_sdk.podspec`, update the version:
```ruby
Pod::Spec.new do |s|
  s.name             = 'axeptio_sdk'
  s.version          = '2.0.15'
  s.summary          = 'AxeptioSDK for presenting cookies consent to the user'
  s.homepage         = '<https://github.com/axeptio/flutter-sdk>'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Axeptio' => 'support@axeptio.eu' }
  s.source           = { :git => "<https://github.com/axeptio/flutter-sdk.git>" }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency "AxeptioIOSSDK", "2.0.15"
  s.platform = :ios, '15.0'
```

### ⚙️Configure widget in sample app 
To configure the widget, add the project ID and version name in `example/lib/main.dart`:
```dart
  Future<void> initSDK() async {
    try {
      await _axeptioSdkPlugin.initialize(
        AxeptioService.publishers,
        '67b63ac7d81d22bf09c09e52',
        'tcf-consent-mode',
        null,
      );
```
#### Android
In the Android sample app, add your GitHub credentials in example/android/build.gradle:
```gradle
maven {
      url = uri("<https://maven.pkg.github.com/axeptio/axeptio-android-sdk>")
      credentials {
          username = "USER" // TODO: GITHUB USERNAME
          password = "TOKEN" // TODO: GITHUB TOKEN
      }
```
In build variants select `Brands` or `Publisher` depending on which service you want to use.

In `settings.gradle.kts` add your GitHub user and token.
```gradle
  maven {
      url = uri("<https://maven.pkg.github.com/axeptio/tcf-android-sdk>")
      credentials {
          username = "USER" // TODO: GITHUB USERNAME
          password = "TOKEN" // TODO: GITHUB TOKEN
      }
  }
```

<br><br><br>

By following this guide, you'll be able to integrate the Axeptio Flutter SDK effectively into your app, providing comprehensive consent management and ensuring compliance with privacy regulations.

For advanced configurations and further documentation, please refer to the official [Axeptio documentation](https://support.axeptio.eu/hc/en-gb).
We hope this guide helps you get started with the Axeptio Flutter SDK. Good luck with your integration, and thank you for choosing Axeptio!
