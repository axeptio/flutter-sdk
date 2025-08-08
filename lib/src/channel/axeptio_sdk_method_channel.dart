import 'package:axeptio_sdk/src/events/events.dart';
import 'package:axeptio_sdk/src/model/model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'axeptio_sdk_platform_interface.dart';

/// An implementation of [AxeptioSdkPlatform] that uses method channels.
class MethodChannelAxeptioSdk implements AxeptioSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('axeptio_sdk');
  final EventsHandler _eventsHandler = EventsHandler();

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> get axeptioToken async {
    final token = await methodChannel.invokeMethod<String>('axeptioToken');
    return token;
  }

  @override
  Future<void> initialize(AxeptioService targetService, String clientId,
      String cookiesVersion, String? token) async {
    await methodChannel.invokeMethod('initialize', {
      "clientId": clientId,
      "cookiesVersion": cookiesVersion,
      "token": token,
      "targetService": targetService.name
    });
  }

  @override
  Future<void> setupUI() async {
    await methodChannel.invokeMethod('setupUI');
  }

  @override
  Future<void> setUserDeniedTracking() async {
    await methodChannel.invokeMethod('setUserDeniedTracking');
  }

  @override
  Future<String?> appendAxeptioTokenURL(String url, String token) async {
    final updatedUrl = await methodChannel
        .invokeMethod('appendAxeptioTokenURL', {"url": url, "token": token});
    return updatedUrl;
  }

  @override
  Future<void> showConsentScreen() async {
    await methodChannel.invokeMethod('showConsentScreen');
  }

  @override
  Future<void> clearConsent() async {
    await methodChannel.invokeMethod('clearConsent');
  }

  @override
  Future<Map<String, dynamic>?> getConsentSavedData(
      {String? preferenceKey}) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'getConsentSavedData',
      {"preferenceKey": preferenceKey},
    );
    return result?.map((key, value) => MapEntry(key.toString(), value));
  }

  @override
  addEventListener(AxeptioEventListener listener) {
    _eventsHandler.addEventListener(listener);
  }

  @override
  removeEventListener(AxeptioEventListener listener) {
    _eventsHandler.removeEventListener(listener);
  }
}
