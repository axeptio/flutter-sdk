import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:axeptio_sdk/src/channel/axeptio_sdk_method_channel.dart';
import 'package:axeptio_sdk/src/model/axeptio_service.dart';
import 'package:axeptio_sdk/src/events/event_listener.dart';
import 'package:axeptio_sdk/src/model/vendor_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelAxeptioSdk platform = MethodChannelAxeptioSdk();
  const MethodChannel channel = MethodChannel('axeptio_sdk');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getPlatformVersion':
            return '42';
          case 'initialize':
            return null; // Void method
          case 'setupUI':
            return null; // Void method
          case 'setUserDeniedTracking':
            return null; // Void method
          case 'showConsentScreen':
            return null; // Void method
          case 'clearConsent':
            return null; // Void method
          case 'axeptioToken':
            return 'mock-token-123';
          case 'appendAxeptioTokenURL':
            final url = methodCall.arguments['url'] as String;
            final token = methodCall.arguments['token'] as String;
            final separator = url.contains('?') ? '&' : '?';
            return '$url${separator}axeptio_token=$token';
          case 'getConsentSavedData':
            final preferenceKey =
                methodCall.arguments?['preferenceKey'] as String?;
            final mockData = {
              'axeptio_cookies': '{"analytics": true, "ads": false}',
              'IABTCF_TCString': 'CPXxRfAPXxRfAAfKABENATEIAAIAAAAAAAAAAAAA',
              'IABTCF_gdprApplies': '1',
            };
            if (preferenceKey != null) {
              final value = mockData[preferenceKey];
              return value != null ? {preferenceKey: value} : null;
            }
            return mockData;
          case 'getConsentDebugInfo':
            return {
              'sdk_version': '2.0.16',
              'client_id': 'test-client',
              'initialization_time': '2025-01-01T00:00:00Z',
            };
          case 'getVendorConsents':
            return {1: true, 2: false, 50: true}; // Map<int, bool>
          case 'getConsentedVendors':
            return [1, 50]; // List<int>
          case 'getRefusedVendors':
            return [2]; // List<int>
          case 'isVendorConsented':
            final vendorId = methodCall.arguments['vendorId'] as int;
            return vendorId == 1 || vendorId == 50; // bool
          case 'loadGVL':
            final gvlVersion = methodCall.arguments?['gvlVersion'] as String?;
            return true; // Mock successful load
          case 'unloadGVL':
            return null; // Void method
          case 'clearGVL':
            return null; // Void method
          case 'getVendorName':
            final vendorId = methodCall.arguments['vendorId'] as int;
            final mockNames = {
              1: 'Google',
              2: 'Facebook',
              755: 'Microsoft',
            };
            return mockNames[vendorId];
          case 'getVendorNames':
            final vendorIds = methodCall.arguments['vendorIds'] as List<dynamic>;
            final mockNames = {
              1: 'Google',
              2: 'Facebook',
              755: 'Microsoft',
            };
            final result = <String, String>{};
            for (final id in vendorIds) {
              final name = mockNames[id as int];
              if (name != null) {
                result[id.toString()] = name;
              }
            }
            return result;
          case 'getVendorConsentsWithNames':
            return {
              '1': {
                'id': 1,
                'name': 'Google',
                'consented': true,
                'purposes': [1, 2, 3],
              },
              '755': {
                'id': 755,
                'name': 'Microsoft',
                'consented': false,
                'purposes': [1, 4, 5],
              },
            };
          case 'isGVLLoaded':
            return true;
          case 'getGVLVersion':
            return '123';
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('getVendorConsents returns Map<int, bool>', () async {
    final result = await platform.getVendorConsents();
    expect(result, isA<Map<int, bool>>());
    expect(result[1], true);
    expect(result[2], false);
    expect(result[50], true);
  });

  test('getConsentedVendors returns List<int>', () async {
    final result = await platform.getConsentedVendors();
    expect(result, isA<List<int>>());
    expect(result, contains(1));
    expect(result, contains(50));
    expect(result, hasLength(2));
  });

  test('getRefusedVendors returns List<int>', () async {
    final result = await platform.getRefusedVendors();
    expect(result, isA<List<int>>());
    expect(result, contains(2));
    expect(result, hasLength(1));
  });

  test('isVendorConsented returns bool', () async {
    final result1 = await platform.isVendorConsented(1);
    expect(result1, isA<bool>());
    expect(result1, true);

    final result2 = await platform.isVendorConsented(2);
    expect(result2, isA<bool>());
    expect(result2, false);
  });

  group('Core SDK Methods', () {
    test('initialize completes successfully', () async {
      await expectLater(
        platform.initialize(
            AxeptioService.brands, 'test-client', 'v1.0.0', null),
        completes,
      );
    });

    test('setupUI completes successfully', () async {
      await expectLater(platform.setupUI(), completes);
    });

    test('setUserDeniedTracking completes successfully', () async {
      await expectLater(platform.setUserDeniedTracking(), completes);
    });

    test('showConsentScreen completes successfully', () async {
      await expectLater(platform.showConsentScreen(), completes);
    });

    test('clearConsent completes successfully', () async {
      await expectLater(platform.clearConsent(), completes);
    });
  });

  group('Token Management', () {
    test('axeptioToken returns String', () async {
      final result = await platform.axeptioToken;
      expect(result, isA<String>());
      expect(result, equals('mock-token-123'));
    });

    test('appendAxeptioTokenURL returns formatted URL', () async {
      final result = await platform.appendAxeptioTokenURL(
          'https://example.com', 'token123');
      expect(result, isA<String>());
      expect(result, equals('https://example.com?axeptio_token=token123'));
    });
  });

  group('Data Retrieval', () {
    test('getConsentSavedData returns all data when no key specified',
        () async {
      final result = await platform.getConsentSavedData();
      expect(result, isA<Map<String, dynamic>>());
      expect(result!.containsKey('axeptio_cookies'), isTrue);
      expect(result.containsKey('IABTCF_TCString'), isTrue);
      expect(result.containsKey('IABTCF_gdprApplies'), isTrue);
    });

    test('getConsentSavedData returns specific data when key specified',
        () async {
      final result =
          await platform.getConsentSavedData(preferenceKey: 'axeptio_cookies');
      expect(result, isA<Map<String, dynamic>>());
      expect(result!.length, equals(1));
      expect(result['axeptio_cookies'],
          equals('{"analytics": true, "ads": false}'));
    });

    test('getConsentSavedData returns null for non-existent key', () async {
      final result =
          await platform.getConsentSavedData(preferenceKey: 'non_existent_key');
      expect(result, isNull);
    });

    test('getConsentDebugInfo returns debug information', () async {
      final result = await platform.getConsentDebugInfo();
      expect(result, isA<Map<String, dynamic>>());
      expect(result!.containsKey('sdk_version'), isTrue);
      expect(result.containsKey('client_id'), isTrue);
      expect(result['sdk_version'], equals('2.0.16'));
    });
  });

  group('Event Listener Management', () {
    test('addEventListener does not throw', () {
      final listener = AxeptioEventListener();
      expect(() => platform.addEventListener(listener), returnsNormally);
    });

    test('removeEventListener does not throw', () {
      final listener = AxeptioEventListener();
      expect(() => platform.removeEventListener(listener), returnsNormally);
    });
  });

  group('GVL Methods', () {
    test('loadGVL with default version returns true', () async {
      final result = await platform.loadGVL();
      expect(result, isTrue);
    });

    test('loadGVL with specific version returns true', () async {
      final result = await platform.loadGVL(gvlVersion: '123');
      expect(result, isTrue);
    });

    test('unloadGVL completes successfully', () async {
      await expectLater(platform.unloadGVL(), completes);
    });

    test('clearGVL completes successfully', () async {
      await expectLater(platform.clearGVL(), completes);
    });

    test('getVendorName returns name for known vendor', () async {
      final name = await platform.getVendorName(1);
      expect(name, equals('Google'));
    });

    test('getVendorName returns null for unknown vendor', () async {
      final name = await platform.getVendorName(9999);
      expect(name, isNull);
    });

    test('getVendorNames returns map of vendor names', () async {
      final names = await platform.getVendorNames([1, 2, 755]);
      expect(names, isA<Map<int, String>>());
      expect(names[1], equals('Google'));
      expect(names[2], equals('Facebook'));
      expect(names[755], equals('Microsoft'));
    });

    test('getVendorNames handles empty list', () async {
      final names = await platform.getVendorNames([]);
      expect(names, isEmpty);
    });

    test('getVendorConsentsWithNames returns VendorInfo objects', () async {
      final consents = await platform.getVendorConsentsWithNames();
      expect(consents, isA<Map<int, VendorInfo>>());
      
      final googleVendor = consents[1]!;
      expect(googleVendor.id, equals(1));
      expect(googleVendor.name, equals('Google'));
      expect(googleVendor.consented, isTrue);
      expect(googleVendor.purposes, equals([1, 2, 3]));
      
      final microsoftVendor = consents[755]!;
      expect(microsoftVendor.id, equals(755));
      expect(microsoftVendor.name, equals('Microsoft'));
      expect(microsoftVendor.consented, isFalse);
      expect(microsoftVendor.purposes, equals([1, 4, 5]));
    });

    test('isGVLLoaded returns boolean status', () async {
      final isLoaded = await platform.isGVLLoaded();
      expect(isLoaded, isTrue);
    });

    test('getGVLVersion returns version string', () async {
      final version = await platform.getGVLVersion();
      expect(version, equals('123'));
    });
  });

  group('Edge Cases', () {
    test('isVendorConsented with unknown vendor returns false', () async {
      final result = await platform.isVendorConsented(999);
      expect(result, isFalse);
    });

    test('appendAxeptioTokenURL handles empty strings', () async {
      final result = await platform.appendAxeptioTokenURL('', '');
      expect(result, equals('?axeptio_token='));
    });

    test('appendAxeptioTokenURL handles special characters', () async {
      final result = await platform.appendAxeptioTokenURL(
          'https://example.com/path?param=value', 'token@123#');
      expect(
          result,
          equals(
              'https://example.com/path?param=value&axeptio_token=token@123#'));
    });
  });
}
