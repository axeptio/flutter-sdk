import 'package:axeptio_sdk/src/channel/axeptio_sdk_platform_interface.dart';
import 'package:flutter/foundation.dart';

/// Provides access to native platform preferences for consent data.
///
/// This class bridges the gap between Flutter and native preferences storage,
/// allowing access to TCF consent data, brand preferences, and other SDK-stored values.
class NativeDefaultPreferences {
  NativeDefaultPreferences._();

  /// Supported preference keys for brands configuration
  static const List<String> brandKeys = [
    'axeptio_cookies',
    'axeptio_all_vendors',
    'axeptio_authorized_vendors',
  ];

  /// Supported preference keys for TCF (Transparency & Consent Framework)
  static const List<String> tcfKeys = [
    'IABTCF_CmpSdkID',
    'IABTCF_CmpSdkVersion',
    'IABTCF_PolicyVersion',
    'IABTCF_gdprApplies',
    'IABTCF_PublisherCC',
    'IABTCF_PurposeOneTreatment',
    'IABTCF_UseNonStandardTexts',
    'IABTCF_TCString',
    'IABTCF_VendorConsents',
    'IABTCF_VendorLegitimateInterests',
    'IABTCF_PurposeConsents',
    'IABTCF_PurposeLegitimateInterests',
    'IABTCF_SpecialFeaturesOptIns',
    'IABTCF_PublisherRestrictions1',
    'IABTCF_PublisherRestrictions2',
    'IABTCF_PublisherRestrictions3',
    'IABTCF_PublisherRestrictions4',
    'IABTCF_PublisherRestrictions5',
    'IABTCF_PublisherRestrictions6',
    'IABTCF_PublisherRestrictions7',
    'IABTCF_PublisherRestrictions8',
    'IABTCF_PublisherRestrictions9',
    'IABTCF_PublisherRestrictions10',
    'IABTCF_PublisherRestrictions11',
    'IABTCF_PublisherConsent',
    'IABTCF_PublisherLegitimateInterests',
    'IABTCF_PublisherCustomPurposesConsents',
    'IABTCF_PublisherCustomPurposesLegitimateInterests',
    'IABTCF_AddtlConsent',
    'IABTCF_EnableAdvertiserConsentMode',
  ];

  /// Additional Axeptio-specific preference keys
  static const List<String> additionalKeys = [
    'AX_CLIENT_TOKEN',
    'AX_POPUP_ON_GOING',
  ];

  /// All supported preference keys
  static List<String> get allKeys => [
        ...brandKeys,
        ...tcfKeys,
        ...additionalKeys,
      ];

  /// Retrieves a specific preference value by key.
  ///
  /// This method provides cross-platform access to native preferences
  /// where consent data is stored. It uses the SDK's internal method
  /// to fetch data from the appropriate native storage.
  ///
  /// Returns the preference value as a String, or null if not found.
  ///
  /// Example:
  /// ```dart
  /// final tcString = await NativeDefaultPreferences.getDefaultPreference('IABTCF_TCString');
  /// final cookies = await NativeDefaultPreferences.getDefaultPreference('axeptio_cookies');
  /// ```
  static Future<String?> getDefaultPreference(String key) async {
    try {
      final data = await AxeptioSdkPlatform.instance.getConsentSavedData(
        preferenceKey: key,
      );

      if (data == null || data.isEmpty) {
        return null;
      }

      // If specific key was requested and found, return its value
      final value = data[key];
      if (value != null) {
        return _convertToString(value);
      }

      // Fallback: if data contains only one entry, return its value
      if (data.length == 1) {
        return _convertToString(data.values.first);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('NativeDefaultPreferences: Error getting preference $key: $e');
      }
      return null;
    }
  }

  /// Retrieves multiple preference values by their keys.
  ///
  /// This method efficiently fetches multiple preferences in a single operation.
  /// Returns a Map with the requested keys and their values, or null if no data found.
  ///
  /// Example:
  /// ```dart
  /// final prefs = await NativeDefaultPreferences.getDefaultPreferences([
  ///   'IABTCF_TCString',
  ///   'axeptio_cookies',
  ///   'IABTCF_gdprApplies'
  /// ]);
  /// ```
  static Future<Map<String, dynamic>?> getDefaultPreferences(
      List<String> keys) async {
    try {
      final data = await AxeptioSdkPlatform.instance.getConsentSavedData();

      if (data == null || data.isEmpty) {
        return null;
      }

      final result = <String, dynamic>{};
      for (final key in keys) {
        final value = data[key];
        if (value != null) {
          result[key] = value;
        }
      }

      return result.isNotEmpty ? result : null;
    } catch (e) {
      if (kDebugMode) {
        print('NativeDefaultPreferences: Error getting preferences $keys: $e');
      }
      return null;
    }
  }

  /// Retrieves all available preference values.
  ///
  /// This method fetches all consent-related preferences that are currently
  /// stored in native storage. Useful for debugging or comprehensive data access.
  ///
  /// Returns a Map containing all available preferences, or null if no data found.
  ///
  /// Example:
  /// ```dart
  /// final allPrefs = await NativeDefaultPreferences.getAllDefaultPreferences();
  /// if (allPrefs != null) {
  ///   print('Available preferences: ${allPrefs.keys}');
  /// }
  /// ```
  static Future<Map<String, dynamic>?> getAllDefaultPreferences() async {
    try {
      return await AxeptioSdkPlatform.instance.getConsentSavedData();
    } catch (e) {
      if (kDebugMode) {
        print('NativeDefaultPreferences: Error getting all preferences: $e');
      }
      return null;
    }
  }

  /// Converts a value to String representation.
  ///
  /// Handles various data types that might be stored in native preferences.
  static String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is bool) return value.toString();
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return value.toString();
  }
}
