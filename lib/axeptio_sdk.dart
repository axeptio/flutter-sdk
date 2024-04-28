
import 'package:axeptio_sdk/events/event_listener.dart';

import 'axeptio_sdk_platform_interface.dart';

class AxeptioSdk {
  static Future<String?> get axeptioToken {
    return AxeptioSdkPlatform.axeptioToken;
  }

  static Future<void> initialize(String clientId, String cookiesVersion, String? token) {
    return AxeptioSdkPlatform.initialize(clientId, cookiesVersion, token);
  }

  static Future<void> setupUI() {
    return AxeptioSdkPlatform.setupUI();
  }

  static Future<void> setUserDeniedTracking() {
    return AxeptioSdkPlatform.setUserDeniedTracking();
  }

  static Future<String?> appendAxeptioTokenURL(String url, String token) {
    return AxeptioSdkPlatform.appendAxeptioTokenURL(url, token);
  }

  static Future<void> showConsentScreen() {
    return AxeptioSdkPlatform.showConsentScreen();
  }

  static Future<void> clearConsent() {
    return AxeptioSdkPlatform.clearConsent();
  }

  static addEventListener(EventListener listener) {
    return AxeptioSdkPlatform.addEventListener(listener);
  }

  static removeEventListener(EventListener listener) {
    return AxeptioSdkPlatform.removeEventListener(listener);
  }
}
