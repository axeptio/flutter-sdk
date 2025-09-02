import 'package:axeptio_sdk/src/channel/axeptio_sdk_platform_interface.dart';
import 'package:axeptio_sdk/src/preferences/native_default_preferences.dart';
import 'package:axeptio_sdk/src/model/axeptio_service.dart';
import 'package:axeptio_sdk/src/model/vendor_info.dart';
import 'package:axeptio_sdk/src/events/event_listener.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock platform for testing NativeDefaultPreferences
class MockNativePreferencesPlatform
    with MockPlatformInterfaceMixin
    implements AxeptioSdkPlatform {
  Map<String, dynamic> _mockData = {};
  bool _shouldThrowError = false;

  void setMockData(Map<String, dynamic> data) {
    _mockData = data;
  }

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  void reset() {
    _mockData.clear();
    _shouldThrowError = false;
  }

  @override
  Future<Map<String, dynamic>?> getConsentSavedData(
      {String? preferenceKey}) async {
    if (_shouldThrowError) {
      throw PlatformException(code: 'TEST_ERROR', message: 'Test error');
    }

    if (preferenceKey != null) {
      final value = _mockData[preferenceKey];
      return value != null ? {preferenceKey: value} : null;
    }

    return _mockData.isEmpty ? null : Map<String, dynamic>.from(_mockData);
  }

  // Minimal implementations for other required methods
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> appendAxeptioTokenURL(String url, String token) =>
      throw UnimplementedError();

  @override
  Future<void> clearConsent() => throw UnimplementedError();

  @override
  Future<String?> get axeptioToken => throw UnimplementedError();

  @override
  Future<void> initialize(AxeptioService service, String clientId,
          String cookiesVersion, String? token) =>
      throw UnimplementedError();

  @override
  Future<void> setUserDeniedTracking() => throw UnimplementedError();

  @override
  Future<void> setupUI() => throw UnimplementedError();

  @override
  Future<void> showConsentScreen() => throw UnimplementedError();

  @override
  addEventListener(AxeptioEventListener listener) => throw UnimplementedError();

  @override
  removeEventListener(AxeptioEventListener listener) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> getConsentDebugInfo({String? preferenceKey}) =>
      throw UnimplementedError();

  @override
  Future<Map<int, bool>> getVendorConsents() => throw UnimplementedError();

  @override
  Future<List<int>> getConsentedVendors() => throw UnimplementedError();

  @override
  Future<List<int>> getRefusedVendors() => throw UnimplementedError();

  @override
  Future<bool> isVendorConsented(int vendorId) => throw UnimplementedError();

  // GVL Mock Methods
  @override
  Future<bool> loadGVL({String? gvlVersion}) => Future.value(true);

  @override
  Future<void> unloadGVL() => Future.value();

  @override
  Future<void> clearGVL() => Future.value();

  @override
  Future<String?> getVendorName(int vendorId) => Future.value(null);

  @override
  Future<Map<int, String>> getVendorNames(List<int> vendorIds) =>
      Future.value(<int, String>{});

  @override
  Future<Map<int, VendorInfo>> getVendorConsentsWithNames() =>
      Future.value(<int, VendorInfo>{});

  @override
  Future<bool> isGVLLoaded() => Future.value(false);

  @override
  Future<String?> getGVLVersion() => Future.value(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeDefaultPreferences', () {
    late MockNativePreferencesPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockNativePreferencesPlatform();
      AxeptioSdkPlatform.instance = mockPlatform;
      mockPlatform.reset();
    });

    group('Predefined Keys', () {
      test('brandKeys contains expected values', () {
        expect(NativeDefaultPreferences.brandKeys, hasLength(3));
        expect(NativeDefaultPreferences.brandKeys, contains('axeptio_cookies'));
        expect(NativeDefaultPreferences.brandKeys,
            contains('axeptio_all_vendors'));
        expect(NativeDefaultPreferences.brandKeys,
            contains('axeptio_authorized_vendors'));
      });

      test('tcfKeys contains expected TCF standard keys', () {
        expect(NativeDefaultPreferences.tcfKeys.length, greaterThan(20));
        expect(NativeDefaultPreferences.tcfKeys, contains('IABTCF_CmpSdkID'));
        expect(NativeDefaultPreferences.tcfKeys, contains('IABTCF_TCString'));
        expect(
            NativeDefaultPreferences.tcfKeys, contains('IABTCF_gdprApplies'));
        expect(NativeDefaultPreferences.tcfKeys,
            contains('IABTCF_VendorConsents'));
        expect(NativeDefaultPreferences.tcfKeys,
            contains('IABTCF_PublisherRestrictions1'));
        expect(NativeDefaultPreferences.tcfKeys,
            contains('IABTCF_PublisherRestrictions10'));
      });

      test('additionalKeys contains Axeptio-specific keys', () {
        expect(NativeDefaultPreferences.additionalKeys, hasLength(2));
        expect(NativeDefaultPreferences.additionalKeys,
            contains('AX_CLIENT_TOKEN'));
        expect(NativeDefaultPreferences.additionalKeys,
            contains('AX_POPUP_ON_GOING'));
      });

      test('allKeys combines all key types', () {
        final expectedLength = NativeDefaultPreferences.brandKeys.length +
            NativeDefaultPreferences.tcfKeys.length +
            NativeDefaultPreferences.additionalKeys.length;

        expect(NativeDefaultPreferences.allKeys.length, equals(expectedLength));
        expect(NativeDefaultPreferences.allKeys,
            containsAll(NativeDefaultPreferences.brandKeys));
        expect(NativeDefaultPreferences.allKeys,
            containsAll(NativeDefaultPreferences.tcfKeys));
        expect(NativeDefaultPreferences.allKeys,
            containsAll(NativeDefaultPreferences.additionalKeys));
      });
    });

    group('getDefaultPreference', () {
      test('returns value for existing key', () async {
        mockPlatform.setMockData({'test_key': 'test_value'});

        final result =
            await NativeDefaultPreferences.getDefaultPreference('test_key');

        expect(result, equals('test_value'));
      });

      test('returns null for non-existing key', () async {
        mockPlatform.setMockData({'other_key': 'other_value'});

        final result =
            await NativeDefaultPreferences.getDefaultPreference('test_key');

        expect(result, isNull);
      });

      test('returns null when no data available', () async {
        mockPlatform.setMockData({});

        final result =
            await NativeDefaultPreferences.getDefaultPreference('test_key');

        expect(result, isNull);
      });

      test('converts different data types to string', () async {
        mockPlatform.setMockData({
          'string_key': 'string_value',
          'int_key': 42,
          'bool_key': true,
          'double_key': 3.14,
          'null_key': null,
        });

        expect(
            await NativeDefaultPreferences.getDefaultPreference('string_key'),
            equals('string_value'));
        expect(await NativeDefaultPreferences.getDefaultPreference('int_key'),
            equals('42'));
        expect(await NativeDefaultPreferences.getDefaultPreference('bool_key'),
            equals('true'));
        expect(
            await NativeDefaultPreferences.getDefaultPreference('double_key'),
            equals('3.14'));
        expect(await NativeDefaultPreferences.getDefaultPreference('null_key'),
            isNull);
      });

      test('handles single entry fallback', () async {
        mockPlatform.setMockData({'single_key': 'single_value'});

        // Request a different key, should return null since key doesn't exist
        final result = await NativeDefaultPreferences.getDefaultPreference(
            'different_key');

        expect(result, isNull);
      });

      test('returns null when multiple entries and key not found', () async {
        mockPlatform.setMockData({
          'key1': 'value1',
          'key2': 'value2',
        });

        final result =
            await NativeDefaultPreferences.getDefaultPreference('key3');

        expect(result, isNull);
      });

      test('handles platform exceptions gracefully', () async {
        mockPlatform.setShouldThrowError(true);

        final result =
            await NativeDefaultPreferences.getDefaultPreference('test_key');

        expect(result, isNull);
      });

      test('works with real preference keys', () async {
        mockPlatform.setMockData({
          'IABTCF_TCString': 'CPXxRfAPXxRfAAfKABENATEIAAIAAAAAAAAAAAAA',
          'IABTCF_gdprApplies': '1',
          'axeptio_cookies': '{"analytics": true}',
        });

        final tcString = await NativeDefaultPreferences.getDefaultPreference(
            'IABTCF_TCString');
        final gdprApplies = await NativeDefaultPreferences.getDefaultPreference(
            'IABTCF_gdprApplies');
        final cookies = await NativeDefaultPreferences.getDefaultPreference(
            'axeptio_cookies');

        expect(tcString, equals('CPXxRfAPXxRfAAfKABENATEIAAIAAAAAAAAAAAAA'));
        expect(gdprApplies, equals('1'));
        expect(cookies, equals('{"analytics": true}'));
      });
    });

    group('getDefaultPreferences', () {
      test('returns requested preferences', () async {
        mockPlatform.setMockData({
          'key1': 'value1',
          'key2': 'value2',
          'key3': 'value3',
        });

        final result = await NativeDefaultPreferences.getDefaultPreferences(
            ['key1', 'key3']);

        expect(result, isNotNull);
        expect(result!.containsKey('key1'), isTrue);
        expect(result.containsKey('key3'), isTrue);
        expect(result.containsKey('key2'), isFalse);
        expect(result['key1'], equals('value1'));
        expect(result['key3'], equals('value3'));
      });

      test('returns only existing keys', () async {
        mockPlatform.setMockData({
          'key1': 'value1',
          'key2': 'value2',
        });

        final result = await NativeDefaultPreferences.getDefaultPreferences(
            ['key1', 'nonexistent', 'key2']);

        expect(result, isNotNull);
        expect(result!.length, equals(2));
        expect(result.containsKey('key1'), isTrue);
        expect(result.containsKey('key2'), isTrue);
        expect(result.containsKey('nonexistent'), isFalse);
      });

      test('returns null when no requested keys found', () async {
        mockPlatform.setMockData({
          'key1': 'value1',
          'key2': 'value2',
        });

        final result = await NativeDefaultPreferences.getDefaultPreferences(
            ['nonexistent1', 'nonexistent2']);

        expect(result, isNull);
      });

      test('returns null when no data available', () async {
        mockPlatform.setMockData({});

        final result = await NativeDefaultPreferences.getDefaultPreferences(
            ['key1', 'key2']);

        expect(result, isNull);
      });

      test('handles empty key list', () async {
        mockPlatform.setMockData({'key1': 'value1'});

        final result = await NativeDefaultPreferences.getDefaultPreferences([]);

        expect(result, isNull);
      });

      test('handles platform exceptions gracefully', () async {
        mockPlatform.setShouldThrowError(true);

        final result = await NativeDefaultPreferences.getDefaultPreferences(
            ['key1', 'key2']);

        expect(result, isNull);
      });

      test('works with TCF and brand keys', () async {
        mockPlatform.setMockData({
          'IABTCF_TCString': 'CPXxRfAPXxRfAAfKABENATEIAAIAAAAAAAAAAAAA',
          'axeptio_cookies': '{"analytics": true}',
          'IABTCF_gdprApplies': 1,
          'other_key': 'other_value',
        });

        final result = await NativeDefaultPreferences.getDefaultPreferences(
            ['IABTCF_TCString', 'axeptio_cookies', 'IABTCF_gdprApplies']);

        expect(result, isNotNull);
        expect(result!.length, equals(3));
        expect(result['IABTCF_TCString'],
            equals('CPXxRfAPXxRfAAfKABENATEIAAIAAAAAAAAAAAAA'));
        expect(result['axeptio_cookies'], equals('{"analytics": true}'));
        expect(result['IABTCF_gdprApplies'], equals(1));
      });
    });

    group('getAllDefaultPreferences', () {
      test('returns all available preferences', () async {
        final mockData = {
          'IABTCF_TCString': 'CPXxRfAPXxRfAAfKABENATEIAAIAAAAAAAAAAAAA',
          'axeptio_cookies': '{"analytics": true}',
          'IABTCF_gdprApplies': '1',
          'AX_CLIENT_TOKEN': 'token123',
        };
        mockPlatform.setMockData(mockData);

        final result =
            await NativeDefaultPreferences.getAllDefaultPreferences();

        expect(result, isNotNull);
        expect(result!.length, equals(4));
        expect(result, equals(mockData));
      });

      test('returns null when no data available', () async {
        mockPlatform.setMockData({});

        final result =
            await NativeDefaultPreferences.getAllDefaultPreferences();

        expect(result, isNull);
      });

      test('handles platform exceptions gracefully', () async {
        mockPlatform.setShouldThrowError(true);

        final result =
            await NativeDefaultPreferences.getAllDefaultPreferences();

        expect(result, isNull);
      });

      test('returned map is independent from internal data', () async {
        final mockData = {'key1': 'value1'};
        mockPlatform.setMockData(mockData);

        final result =
            await NativeDefaultPreferences.getAllDefaultPreferences();

        expect(result, isNotNull);

        // Modify returned map
        result!['key1'] = 'modified_value';
        result['new_key'] = 'new_value';

        // Original mock data should be unchanged
        final result2 =
            await NativeDefaultPreferences.getAllDefaultPreferences();
        expect(result2!['key1'], equals('value1'));
        expect(result2.containsKey('new_key'), isFalse);
      });
    });

    group('String Conversion', () {
      test('_convertToString handles various data types', () async {
        mockPlatform.setMockData({
          'null_value': null,
          'string_value': 'hello',
          'bool_true': true,
          'bool_false': false,
          'int_value': 42,
          'double_value': 3.14159,
          'list_value': [1, 2, 3],
          'map_value': {'nested': 'object'},
        });

        expect(
            await NativeDefaultPreferences.getDefaultPreference('null_value'),
            isNull);
        expect(
            await NativeDefaultPreferences.getDefaultPreference('string_value'),
            equals('hello'));
        expect(await NativeDefaultPreferences.getDefaultPreference('bool_true'),
            equals('true'));
        expect(
            await NativeDefaultPreferences.getDefaultPreference('bool_false'),
            equals('false'));
        expect(await NativeDefaultPreferences.getDefaultPreference('int_value'),
            equals('42'));
        expect(
            await NativeDefaultPreferences.getDefaultPreference('double_value'),
            equals('3.14159'));
        expect(
            await NativeDefaultPreferences.getDefaultPreference('list_value'),
            equals('[1, 2, 3]'));
        expect(await NativeDefaultPreferences.getDefaultPreference('map_value'),
            equals('{nested: object}'));
      });
    });

    group('Real-world Usage', () {
      test('simulates typical TCF consent data retrieval', () async {
        // Simulate realistic TCF data
        mockPlatform.setMockData({
          'IABTCF_CmpSdkID': '42',
          'IABTCF_CmpSdkVersion': '2',
          'IABTCF_PolicyVersion': '4',
          'IABTCF_gdprApplies': '1',
          'IABTCF_TCString':
              'CPXxRfAPXxRfAAfKABENATEIAAIAAAAAAAAAAAAA.argAC0gAAAAAAAAAAAA',
          'IABTCF_VendorConsents': '0000001111000011110000',
          'IABTCF_PurposeConsents': '1111000011110000',
        });

        // Get specific TCF keys
        final tcfKeys = [
          'IABTCF_TCString',
          'IABTCF_gdprApplies',
          'IABTCF_VendorConsents'
        ];
        final result =
            await NativeDefaultPreferences.getDefaultPreferences(tcfKeys);

        expect(result, isNotNull);
        expect(result!.length, equals(3));
        expect(result['IABTCF_gdprApplies'], equals('1'));
        expect(result['IABTCF_TCString'],
            contains('CPXxRfAPXxRfAAfKABENATEIAAIAAAAAAAAAAAAA'));
      });

      test('simulates Axeptio brand preferences retrieval', () async {
        mockPlatform.setMockData({
          'axeptio_cookies':
              '{"analytics": true, "ads": false, "social": true}',
          'axeptio_all_vendors': '["google", "facebook", "twitter"]',
          'axeptio_authorized_vendors': '["google", "twitter"]',
          'AX_CLIENT_TOKEN': 'client-token-123',
        });

        const brandKeys = NativeDefaultPreferences.brandKeys;
        final result =
            await NativeDefaultPreferences.getDefaultPreferences(brandKeys);

        expect(result, isNotNull);
        expect(result!.length, equals(3));
        expect(result['axeptio_cookies'], contains('analytics'));
        expect(result['axeptio_all_vendors'], contains('google'));
      });
    });
  });
}
