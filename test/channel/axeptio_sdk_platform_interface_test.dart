import 'package:axeptio_sdk/src/channel/axeptio_sdk_platform_interface.dart';
import 'package:axeptio_sdk/src/events/event_listener.dart';
import 'package:axeptio_sdk/src/model/axeptio_service.dart';
import 'package:axeptio_sdk/src/webview/webview_axeptio_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AxeptioSdkPlatform', () {
    test('default instance is WebViewAxeptioSdk', () {
      expect(AxeptioSdkPlatform.instance, isInstanceOf<WebViewAxeptioSdk>());
    });

    test('instance getter returns non-null platform', () {
      expect(AxeptioSdkPlatform.instance, isNotNull);
    });

    test('default instance implements AxeptioSdkPlatform', () {
      expect(AxeptioSdkPlatform.instance, isA<AxeptioSdkPlatform>());
    });

    group('default UnimplementedError throws', () {
      late _StubPlatform stub;

      setUp(() => stub = _StubPlatform());

      test('getPlatformVersion throws', () {
        expect(() => stub.getPlatformVersion(), throwsUnimplementedError);
      });
      test('axeptioToken throws', () {
        expect(() => stub.axeptioToken, throwsUnimplementedError);
      });
      test('initialize throws', () {
        expect(() => stub.initialize(AxeptioService.publishers, '', '', null),
            throwsUnimplementedError);
      });
      test('setupUI throws', () {
        expect(() => stub.setupUI(), throwsUnimplementedError);
      });
      test('setUserDeniedTracking throws', () {
        expect(() => stub.setUserDeniedTracking(), throwsUnimplementedError);
      });
      test('appendAxeptioTokenURL throws', () {
        expect(
            () => stub.appendAxeptioTokenURL('', ''), throwsUnimplementedError);
      });
      test('showConsentScreen throws', () {
        expect(() => stub.showConsentScreen(), throwsUnimplementedError);
      });
      test('clearConsent throws', () {
        expect(() => stub.clearConsent(), throwsUnimplementedError);
      });
      test('getConsentSavedData throws', () {
        expect(() => stub.getConsentSavedData(), throwsUnimplementedError);
      });
      test('getConsentDebugInfo throws', () {
        expect(() => stub.getConsentDebugInfo(), throwsUnimplementedError);
      });
      test('getVendorConsents throws', () {
        expect(() => stub.getVendorConsents(), throwsUnimplementedError);
      });
      test('getConsentedVendors throws', () {
        expect(() => stub.getConsentedVendors(), throwsUnimplementedError);
      });
      test('getRefusedVendors throws', () {
        expect(() => stub.getRefusedVendors(), throwsUnimplementedError);
      });
      test('isVendorConsented throws', () {
        expect(() => stub.isVendorConsented(1), throwsUnimplementedError);
      });
      test('addEventListener throws', () {
        expect(() => stub.addEventListener(AxeptioEventListener()),
            throwsUnimplementedError);
      });
      test('removeEventListener throws', () {
        expect(() => stub.removeEventListener(AxeptioEventListener()),
            throwsUnimplementedError);
      });
    });
  });
}

/// Minimal subclass that inherits all default UnimplementedError throws.
class _StubPlatform extends AxeptioSdkPlatform {}
