import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'axeptio_sdk_platform_interface.dart';

import 'package:axeptio_sdk/events/event_listener.dart';
import 'package:axeptio_sdk/events/events_handler.dart';

/// An implementation of [AxeptioSdkPlatform] that uses method channels.
class MethodChannelAxeptioSdk extends AxeptioSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  static const methodChannel = const MethodChannel('axeptio_sdk');
  static EventsHandler _eventsHandler = EventsHandler();

  static Future<String?> get axeptioToken async {
    final token = await methodChannel.invokeMethod<String>('axeptioToken');
    return token;
  }

  static Future<void> initialize(String clientId, String cookiesVersion, String? token) async {
    await methodChannel.invokeMethod('initialize', {
      "clientId": clientId,
      "cookiesVersion": cookiesVersion,
      "token": token
    });
  }

  static Future<void> setupUI() async {
    await methodChannel.invokeMethod('setupUI');
  }

  static Future<void> setUserDeniedTracking() async {
    await methodChannel.invokeMethod('setUserDeniedTracking');
  }

  static Future<String?> appendAxeptioTokenURL(String url, String token) async {
    final updatedUrl = await methodChannel.invokeMethod('appendAxeptioTokenURL', {
      "url": url,
      "token": token
    });
    return updatedUrl;
  }

  static Future<void> showConsentScreen() async {
    await methodChannel.invokeMethod('showConsentScreen');
  }

  static Future<void> clearConsent() async {
    await methodChannel.invokeMethod('clearConsent');
  }

  static addEventListener(EventListener listener) {
    _eventsHandler.addEventListener(listener);
  }

  static removeEventListener(EventListener listener) {
    _eventsHandler.removeEventListener(listener);
  }
}
