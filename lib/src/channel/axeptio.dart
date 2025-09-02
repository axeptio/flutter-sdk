import 'package:axeptio_sdk/src/events/event_listener.dart';
import 'package:axeptio_sdk/src/model/model.dart';
import 'package:axeptio_sdk/src/gvl/gvl_service.dart';

import 'axeptio_sdk_platform_interface.dart';

class AxeptioSdk {
  AxeptioService? _targetService;

  AxeptioService? get targetService => _targetService;

  Future<String?> getPlatformVersion() {
    return AxeptioSdkPlatform.instance.getPlatformVersion();
  }

  Future<String?> get axeptioToken {
    return AxeptioSdkPlatform.instance.axeptioToken;
  }

  Future<void> initialize(AxeptioService targetService, String clientId,
      String cookiesVersion, String? token) {
    _targetService = targetService;
    return AxeptioSdkPlatform.instance
        .initialize(targetService, clientId, cookiesVersion, token);
  }

  Future<void> setupUI() {
    return AxeptioSdkPlatform.instance.setupUI();
  }

  Future<void> setUserDeniedTracking() {
    return AxeptioSdkPlatform.instance.setUserDeniedTracking();
  }

  Future<String?> appendAxeptioTokenURL(String url, String token) {
    return AxeptioSdkPlatform.instance.appendAxeptioTokenURL(url, token);
  }

  Future<void> showConsentScreen() {
    return AxeptioSdkPlatform.instance.showConsentScreen();
  }

  Future<void> clearConsent() {
    return AxeptioSdkPlatform.instance.clearConsent();
  }

  Future<Map<String, dynamic>?> getConsentSavedData({String? preferenceKey}) {
    return AxeptioSdkPlatform.instance.getConsentSavedData(
      preferenceKey: preferenceKey,
    );
  }

  Future<Map<String, dynamic>?> getConsentDebugInfo({String? preferenceKey}) {
    return AxeptioSdkPlatform.instance.getConsentDebugInfo(
      preferenceKey: preferenceKey,
    );
  }

  Future<Map<int, bool>> getVendorConsents() {
    return AxeptioSdkPlatform.instance.getVendorConsents();
  }

  Future<List<int>> getConsentedVendors() {
    return AxeptioSdkPlatform.instance.getConsentedVendors();
  }

  Future<List<int>> getRefusedVendors() {
    return AxeptioSdkPlatform.instance.getRefusedVendors();
  }

  Future<bool> isVendorConsented(int vendorId) {
    return AxeptioSdkPlatform.instance.isVendorConsented(vendorId);
  }

  addEventListerner(AxeptioEventListener listener) {
    AxeptioSdkPlatform.instance.addEventListener(listener);
  }

  removeEventListener(AxeptioEventListener listener) {
    AxeptioSdkPlatform.instance.removeEventListener(listener);
  }

  // GVL Management methods

  /// Loads the Global Vendor List (GVL) from the IAB server.
  ///
  /// Downloads and caches the vendor list data locally. The [gvlVersion]
  /// parameter can be used to load a specific version of the GVL.
  ///
  /// Returns `true` if the GVL was loaded successfully, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final success = await axeptioSdk.loadGVL();
  /// if (success) {
  ///   print('GVL loaded successfully');
  /// }
  /// ```
  Future<bool> loadGVL({String? gvlVersion}) {
    return GVLService.instance.loadGVL(gvlVersion: gvlVersion);
  }

  /// Unloads the currently cached GVL data from memory.
  ///
  /// This method clears the GVL data from memory but preserves the cache
  /// for future loading. Useful for memory management in resource-constrained
  /// environments.
  Future<void> unloadGVL() {
    GVLService.instance.unloadGVL();
    return Future.value();
  }

  /// Clears all cached GVL data from storage.
  ///
  /// This method permanently removes the cached GVL data, forcing a fresh
  /// download on the next [loadGVL] call. Use this to refresh stale data
  /// or clear storage space.
  Future<void> clearGVL() {
    return GVLService.instance.clearGVL();
  }

  // Vendor information methods

  /// Gets the human-readable name for a specific vendor ID.
  ///
  /// Returns the vendor name from the GVL, or `null` if the vendor ID
  /// is not found or the GVL is not loaded.
  ///
  /// Example:
  /// ```dart
  /// final vendorName = await axeptioSdk.getVendorName(1);
  /// print('Vendor 1: $vendorName'); // e.g., "Vendor 1: Google"
  /// ```
  Future<String?> getVendorName(int vendorId) async {
    return GVLService.instance.getVendorName(vendorId);
  }

  /// Gets the human-readable names for multiple vendor IDs.
  ///
  /// Returns a map of vendor IDs to their names. Missing or invalid
  /// vendor IDs will not be included in the result.
  ///
  /// Example:
  /// ```dart
  /// final vendorNames = await axeptioSdk.getVendorNames([1, 2, 755]);
  /// vendorNames.forEach((id, name) {
  ///   print('Vendor $id: $name');
  /// });
  /// ```
  Future<Map<int, String>> getVendorNames(List<int> vendorIds) async {
    return GVLService.instance.getVendorNames(vendorIds);
  }

  /// Gets comprehensive vendor information with consent status.
  ///
  /// Returns a map of vendor IDs to [VendorInfo] objects that include
  /// both consent status and detailed vendor information from the GVL.
  ///
  /// Example:
  /// ```dart
  /// final vendorInfos = await axeptioSdk.getVendorConsentsWithNames();
  /// vendorInfos.forEach((id, info) {
  ///   print('${info.name}: ${info.consented ? "✅" : "❌"}');
  /// });
  /// ```
  Future<Map<int, VendorInfo>> getVendorConsentsWithNames() async {
    // Get current vendor consents from platform
    final vendorConsents = await getVendorConsents();
    // Combine with GVL data using Flutter-native service
    return GVLService.instance.createVendorConsentsWithNames(vendorConsents);
  }

  // GVL status methods

  /// Checks if the GVL is currently loaded and available.
  ///
  /// Returns `true` if the GVL data is loaded in memory and ready for use,
  /// `false` otherwise.
  Future<bool> isGVLLoaded() async {
    return GVLService.instance.isGVLLoaded();
  }

  /// Gets the version of the currently loaded GVL.
  ///
  /// Returns the version string of the loaded GVL, or `null` if no GVL
  /// is currently loaded.
  Future<String?> getGVLVersion() async {
    return GVLService.instance.getGVLVersion();
  }
}
