import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:axeptio_sdk/src/channel/axeptio_sdk_method_channel.dart';

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
}
