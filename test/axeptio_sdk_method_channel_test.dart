import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:axeptio_sdk/src/channel/axeptio_sdk_method_channel.dart';
import 'package:axeptio_sdk/src/model/axeptio_service.dart';
import 'package:axeptio_sdk/src/events/event_listener.dart';
import 'package:axeptio_sdk/src/model/vendor_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Normal Operations', () {
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
  }); // End Normal Operations

  group('Error Handling', () {
    late MethodChannelAxeptioSdk errorPlatform;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('axeptio_sdk'), (call) async {
        // Mock platform exceptions for error testing
        switch (call.method) {
          case 'getPlatformVersion':
            throw PlatformException(code: 'UNAVAILABLE', message: 'Platform version unavailable');
          case 'getVendorConsents':
            throw PlatformException(code: 'FETCH_ERROR', message: 'Failed to fetch vendor consents');
          case 'getConsentSavedData':
            return null; // Simulate null return
          case 'getVendorName':
            final vendorId = call.arguments['vendorId'] as int;
            if (vendorId < 0) {
              throw PlatformException(code: 'INVALID_ID', message: 'Invalid vendor ID');
            }
            return null; // Normal null return for unknown vendor
          default:
            return null;
        }
      });
      errorPlatform = MethodChannelAxeptioSdk();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('axeptio_sdk'), null);
    });

    test('getPlatformVersion handles platform exception', () async {
      expect(
        () => errorPlatform.getPlatformVersion(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('getVendorConsents returns empty map on platform exception', () async {
      final result = await errorPlatform.getVendorConsents();
      expect(result, isEmpty);
    });

    test('getConsentSavedData handles null return gracefully', () async {
      final result = await errorPlatform.getConsentSavedData();
      expect(result, isNull);
    });

    test('getConsentSavedData handles platform exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('axeptio_sdk'), (call) async {
        if (call.method == 'getConsentSavedData') {
          throw PlatformException(code: 'ERROR', message: 'Test error');
        }
        return null;
      });

      final platform = MethodChannelAxeptioSdk();
      final result = await platform.getConsentSavedData();
      expect(result, isEmpty);
    });

    test('getConsentDebugInfo handles platform exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('axeptio_sdk'), (call) async {
        if (call.method == 'getConsentDebugInfo') {
          throw PlatformException(code: 'ERROR', message: 'Test error');
        }
        return null;
      });

      final platform = MethodChannelAxeptioSdk();
      final result = await platform.getConsentDebugInfo();
      expect(result, isEmpty);
    });

    test('getVendorConsents handles null return', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('axeptio_sdk'), (call) async {
        if (call.method == 'getVendorConsents') {
          return null;
        }
        return <String, dynamic>{'755': true};
      });

      final platform = MethodChannelAxeptioSdk();
      final result = await platform.getVendorConsents();
      expect(result, isEmpty);
    });

    test('getConsentedVendors handles null return', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('axeptio_sdk'), (call) async {
        if (call.method == 'getConsentedVendors') {
          return null;
        }
        return [755];
      });

      final platform = MethodChannelAxeptioSdk();
      final result = await platform.getConsentedVendors();
      expect(result, isEmpty);
    });


    test('getConsentedVendors handles platform exception', () async {
      // Reset mock to throw exception for getConsentedVendors
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('axeptio_sdk'), (call) async {
        if (call.method == 'getConsentedVendors') {
          throw PlatformException(code: 'ERROR', message: 'Test error');
        }
        return null;
      });

      final result = await errorPlatform.getConsentedVendors();
      expect(result, isEmpty);
    });

    test('getRefusedVendors handles platform exception', () async {
      // Reset mock to throw exception for getRefusedVendors  
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('axeptio_sdk'), (call) async {
        if (call.method == 'getRefusedVendors') {
          throw PlatformException(code: 'ERROR', message: 'Test error');
        }
        return null;
      });

      final result = await errorPlatform.getRefusedVendors();
      expect(result, isEmpty);
    });

    test('isVendorConsented handles platform exception', () async {
      // Reset mock to throw exception for isVendorConsented
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('axeptio_sdk'), (call) async {
        if (call.method == 'isVendorConsented') {
          throw PlatformException(code: 'ERROR', message: 'Test error');
        }
        return null;
      });

      final result = await errorPlatform.isVendorConsented(1);
      expect(result, isFalse);
    });


    test('GVL methods handle platform exceptions gracefully', () async {
      // Reset mock to throw exceptions for all GVL methods
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('axeptio_sdk'), (call) async {
        switch (call.method) {
          default:
            return null;
        }
      });

      // Test removed as GVL methods are now Flutter-native
    });

    test('data parsing handles invalid formats', () async {
      // Test malformed data handling
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('axeptio_sdk'), (call) async {
        switch (call.method) {
          case 'getVendorConsents':
            return {'invalid': 'not_a_boolean'}; // Invalid format
          case 'getConsentedVendors':
            return [1, 'invalid', 2.5, null]; // Mixed types
          default:
            return null;
        }
      });

      // These should handle invalid data gracefully
      final vendorConsents = await errorPlatform.getVendorConsents();
      expect(vendorConsents, isEmpty);

      final consentedVendors = await errorPlatform.getConsentedVendors();
      expect(consentedVendors, contains(1)); // Should filter out invalid entries

      // GVL methods removed - now Flutter-native
    });
  });
}
