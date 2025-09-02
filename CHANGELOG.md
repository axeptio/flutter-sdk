## 2.0.18

### ✨ New Features
- **Flutter-Native GVL Service**: Complete Global Vendor List integration implemented in pure Dart/Flutter
  - `loadGVL()`: Download and cache IAB Global Vendor List from https://static.axept.io/gvl/vendor-list.json
  - `getVendorName(vendorId)`: Get individual vendor name by ID with intelligent fallbacks
  - `getVendorNames(vendorIds[])`: Get multiple vendor names efficiently
  - `getVendorConsentsWithNames()`: Enhanced consent data combining platform consent with GVL names
  - `unloadGVL()`, `clearGVL()`: Memory and cache management for GVL data
  - `isGVLLoaded()`, `getGVLVersion()`: Status and version information
- **VendorInfo Model**: Comprehensive vendor information class with purposes, features, and metadata
- **Smart Caching**: 7-day local storage with SharedPreferences and automatic cache invalidation
- **Zero Native Dependencies**: Pure Flutter implementation eliminates platform-specific GVL code

### 🎛️ Enhanced Example App
- **Advanced GVL Management UI**: Comprehensive interface for testing all GVL features
- **Real-time Vendor Analytics**: Live vendor consent visualization with names
- **Interactive Controls**: Load/unload/clear GVL operations with status feedback
- **Performance Monitoring**: GVL loading status, version tracking, and error reporting

### 🧪 Testing Improvements
- **100% Test Success Rate**: All 163 tests passing with real GVL API integration
- **Real Data Testing**: Tests use actual GVL data (1372+ vendors) instead of mocks
- **Comprehensive Coverage**: Unit, integration, and error handling tests for all GVL features

### 🔧 Technical Architecture
- **HTTP Client Integration**: Direct API calls with proper error handling and timeouts
- **Memory Optimization**: Efficient loading and unloading of large vendor datasets (1372+ vendors)
- **Platform Interface Cleanup**: Removed complex GVL method signatures from native bridges
- **Backward Compatibility**: All existing APIs maintained, zero breaking changes

### 📚 Documentation
- Enhanced README with GVL integration examples
- Comprehensive API documentation for all new methods
- Example app serves as complete integration reference

## 2.0.17

- Update example app with improved user interface and functionality.
- Enhance configuration screen with better validation and user feedback.
- Improve vendor data service with real-time updates and analytics.
- Add comprehensive TCF vendor management UI with detailed consent tracking.
- Enhanced debug information display with proper scrolling and formatting.

## 2.0.16

- Implement manual workflow dispatch for publishing workflows.
- Add comprehensive changelog validation to prevent publishing without documentation.
- Align dry-run-publish.yml to use release tag logic instead of pubspec.yaml.
- Update release process to require manual workflow execution for better control.

## 2.0.15

- Fix iOS bridge type casting issue for vendor consent APIs.
- Resolve 'String' is not subtype of 'Map<dynamic, dynamic>' error in getVendorConsents.
- Add proper handling for [Int: Bool] dictionary conversion in iOS sanitizeForFlutter.
- Improve method channel bridge reliability for TCF vendor APIs.

## 2.0.12

- Update iOS Axeptio SDK to 2.0.15.
- Update Android Axeptio SDK to 2.0.8.
- Add comprehensive TCF vendor consent management APIs (iOS & Android).
  - `getVendorConsents()`: Get all vendor consents as Map<int, bool>
  - `getConsentedVendors()`: Get list of consented vendor IDs
  - `getRefusedVendors()`: Get list of refused vendor IDs  
  - `isVendorConsented(vendorId)`: Check specific vendor consent status
- Add extensive README documentation with TCF vendor management examples.
- Add TCF vendor consent demo in example app with detailed logging.
- Fix GitHub Package Registry credentials configuration in example project.

## 2.0.11

- Add NativeDefaultPreferences class for cross-platform access to native consent preferences (MSK-76).
- Provide unified API to access TCF data, brand preferences, and custom vendor information.
- Support bulk operations and comprehensive preference key access.
- Update documentation with correct import paths and usage examples.

## 2.0.10

- Fix iOS crash when calling getConsentSavedData due to NSDate serialization error (MSK-81).
- Add error handling to gracefully handle iOS date serialization issues.


## 2.0.9

- Update iOS Axeptio SDK to 2.0.13 and Android SDK to 2.0.7.
- Expose method to fetch vendor consent debug info.

## 2.0.8

Docs and sample apps improvements.

## 2.0.7

Update to iOSAxeptio SDK 2.0.7 and Android SDK 2.0.6

## 2.0.5

Update to iOSAxeptio SDK 2.0.5 and Android SDK 2.0.4

## 2.0.4

Update to iOSAxeptio SDK 2.0.4 and Android SDK 2.0.3
Enable user token update

## 2.0.3

Update to iOSAxeptio SDK 2.0.3 and Android SDK 2.0.2
Brands events fix.

## 2.0.2

Update to iOSAxeptio SDK 2.0.2
ATT consent bug fix.

## 2.0.1

Update to Axeptio SDK 2.0.1
Clearing consent and partial consent bug fix.

## 2.0.0

Updated to Axeptio SDK 2.0.0
Manage brands and publishers configuration

## 1.3.1

Fix CMP first show on iOS SDK

## 1.2.1

* Fix xcprivacy in iOS SDK

## 1.2.0

* First release
  
## 1.0.0-alpha2

* Second alpha

## 1.0.0-alpha

* First alpha