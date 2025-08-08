import 'package:axeptio_sdk/src/events/event_listener.dart';
import 'package:axeptio_sdk/src/model/model.dart';

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

  addEventListerner(AxeptioEventListener listener) {
    AxeptioSdkPlatform.instance.addEventListener(listener);
  }

  removeEventListener(AxeptioEventListener listener) {
    AxeptioSdkPlatform.instance.removeEventListener(listener);
  }
}
