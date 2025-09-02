import 'package:axeptio_sdk/src/events/events.dart';
import 'package:axeptio_sdk/src/model/model.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'axeptio_sdk_method_channel.dart';

abstract interface class AxeptioSdkPlatform extends PlatformInterface {
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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> get axeptioToken {
    throw UnimplementedError('axeptioToken() has not been implemented.');
  }

  Future<void> initialize(AxeptioService targetService, String clientId,
      String cookiesVersion, String? token) {
    throw UnimplementedError('initialize() has not been implemented');
  }

  Future<void> setupUI() {
    throw UnimplementedError('setupUI() has not been implemented');
  }

  Future<void> setUserDeniedTracking() {
    throw UnimplementedError(
        'setUserDeniedTracking() has not been implemented');
  }

  Future<String?> appendAxeptioTokenURL(String url, String token) {
    throw UnimplementedError(
        'appendAxeptioTokenURL() has not been implemented');
  }

  Future<void> showConsentScreen() {
    throw UnimplementedError('showConsentScreen() has not been implemented');
  }

  Future<void> clearConsent() {
    throw UnimplementedError('clearConsent() has not been implemented');
  }

  Future<Map<String, dynamic>?> getConsentSavedData({String? preferenceKey}) {
    throw UnimplementedError('getConsentSavedData() has not been implemented');
  }

  Future<Map<String, dynamic>?> getConsentDebugInfo({String? preferenceKey}) {
    throw UnimplementedError('getConsentDebugInfo() has not been implemented');
  }

  Future<Map<int, bool>> getVendorConsents() {
    throw UnimplementedError('getVendorConsents() has not been implemented');
  }

  Future<List<int>> getConsentedVendors() {
    throw UnimplementedError('getConsentedVendors() has not been implemented');
  }

  Future<List<int>> getRefusedVendors() {
    throw UnimplementedError('getRefusedVendors() has not been implemented');
  }

  Future<bool> isVendorConsented(int vendorId) {
    throw UnimplementedError('isVendorConsented() has not been implemented');
  }

  addEventListener(AxeptioEventListener listener) {
    throw UnimplementedError('addEventListener() has not been implemented');
  }

  removeEventListener(AxeptioEventListener listener) {
    throw UnimplementedError('removeEventListener() has not been implemented');
  }

}
