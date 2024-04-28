import 'package:axeptio_sdk/events/event_listener.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'axeptio_sdk_method_channel.dart';

abstract class AxeptioSdkPlatform extends PlatformInterface {
  /// Constructs a AxeptioSdkPlatform.
  AxeptioSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static AxeptioSdkPlatform _instance = MethodChannelAxeptioSdk();

  /// The default instance of [AxeptioSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelAxeptioSdk].
  static AxeptioSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AxeptioSdkPlatform] when
  /// they register themselves.
  static set instance(AxeptioSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  static Future<String?> get axeptioToken {
    throw UnimplementedError('axeptioToken() has not been implemented.');
  }

  static Future<void> initialize(String clientId, String cookiesVersion, String? token) {
    throw UnimplementedError('initialize() has not been implemented');
  }

  static Future<void> setupUI() {
    throw UnimplementedError('setupUI() has not been implemented');
  }

  static Future<void> setUserDeniedTracking() {
    throw UnimplementedError('setUserDeniedTracking() has not been implemented');
  }

  static Future<String?> appendAxeptioTokenURL(String url, String token) {
    throw UnimplementedError('appendAxeptioTokenURL() has not been implemented');
  }

  static Future<void> showConsentScreen() {
    throw UnimplementedError('showConsentScreen() has not been implemented');
  }

  static Future<void> clearConsent() {
    throw UnimplementedError('clearConsent() has not been implemented');
  }

  static addEventListener(EventListener listener) {
    throw UnimplementedError('addEventListener() has not been implemented');
  }

  static removeEventListener(EventListener listener) {
    throw UnimplementedError('removeListener() has not been implemented');
  }
}
