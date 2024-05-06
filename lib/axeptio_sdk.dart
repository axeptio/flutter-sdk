import 'axeptio_sdk_platform_interface.dart';

class AxeptioSdk {
  Future<String?> getPlatformVersion() {
    return AxeptioSdkPlatform.instance.getPlatformVersion();
  }

  Future<String?> get axeptioToken {
    return AxeptioSdkPlatform.instance.axeptioToken;
  }

  Future<void> initialize(
      String clientId, String cookiesVersion, String? token) {
    return AxeptioSdkPlatform.instance
        .initialize(clientId, cookiesVersion, token);
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
}
