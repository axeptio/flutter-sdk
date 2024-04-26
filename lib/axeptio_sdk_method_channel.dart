import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'axeptio_sdk_platform_interface.dart';

import 'package:axeptio_sdk/events/event_listener.dart';
import 'package:axeptio_sdk/events/events_handler.dart';

/// An implementation of [AxeptioSdkPlatform] that uses method channels.
class MethodChannelAxeptioSdk extends AxeptioSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('axeptio_sdk');
  EventsHandler _eventsHandler = EventsHandler();

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> get axeptioToken async {
    final token = await methodChannel.invokeMethod<String>('axeptioToken');
    return token;
  }

  @override
  Future<void> initialize(String clientId, String cookiesVersion, String? token) async {
    await methodChannel.invokeMethod('initialize', {
      "clientId": clientId,
      "cookiesVersion": cookiesVersion,
      "token": token
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
    final updatedUrl = await methodChannel.invokeMethod('appendAxeptioTokenURL', {
      "url": url,
      "token": token
    });
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

  addEventListener(EventListener listener) {
    _eventsHandler.addEventListener(listener);
  }

  removeEventListener(EventListener listener) {
    _eventsHandler.removeEventListener(listener);
  }
}
