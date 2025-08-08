import 'package:axeptio_sdk/axeptio_sdk.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAxeptioSdkPlatform
    with MockPlatformInterfaceMixin
    implements AxeptioSdkPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> appendAxeptioTokenURL(String url, String token) {
    // TODO: implement appendAxeptioTokenURL
    throw UnimplementedError();
  }

  @override
  Future<void> clearConsent() {
    // TODO: implement clearConsent
    throw UnimplementedError();
  }

  @override
  Future<String?> get axeptioToken {
    // TODO: implement getAxeptioToken
    throw UnimplementedError();
  }

  @override
  Future<void> initialize(AxeptioService service, String clientId,
      String cookiesVersion, String? token) {
    // TODO: implement initialize
    throw UnimplementedError();
  }

  @override
  Future<void> setUserDeniedTracking() {
    // TODO: implement setUserDeniedTracking
    throw UnimplementedError();
  }

  @override
  Future<void> setupUI() {
    // TODO: implement setupUI
    throw UnimplementedError();
  }

  @override
  Future<void> showConsentScreen() {
    // TODO: implement showConsentScreen
    throw UnimplementedError();
  }

  @override
  addEventListener(AxeptioEventListener listener) {
    // TODO: implement addEventListener
    throw UnimplementedError();
  }

  @override
  removeEventListener(AxeptioEventListener listener) {
    // TODO: implement removeEventListener
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> getConsentSavedData({String? preferenceKey}) {
    // TODO: implement getConsentSavedData
    throw UnimplementedError();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final AxeptioSdkPlatform initialPlatform = AxeptioSdkPlatform.instance;

  test('$MethodChannelAxeptioSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAxeptioSdk>());
  });

  test('getPlatformVersion', () async {
    AxeptioSdk axeptioSdkPlugin = AxeptioSdk();
    MockAxeptioSdkPlatform fakePlatform = MockAxeptioSdkPlatform();
    AxeptioSdkPlatform.instance = fakePlatform;

    expect(await axeptioSdkPlugin.getPlatformVersion(), '42');
  });
}
