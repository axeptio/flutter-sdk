// ignore_for_file: avoid_print

import 'package:axeptio_sdk/src/model/consents_v2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'event_listener.dart';

class EventsHandler {
  static const EventChannel _eventChannel = EventChannel('axeptio_sdk/events');
  List<AxeptioEventListener> listeners = [];

  EventsHandler() {
    _eventChannel
        .receiveBroadcastStream()
        .listen(handleAxeptioEvent, onError: handleDAxeptioErrorEvent);
  }

  handleAxeptioEvent(dynamic event) {
    final String eventType = event['type'].toString();

    switch (eventType) {
      case 'onPopupClosedEvent':
        for (var listener in listeners) {
          listener.onPopupClosedEvent();
        }
        break;

      case 'onConsentCleared':
        for (var listener in listeners) {
          listener.onConsentCleared();
        }
        break;

      case 'onGoogleConsentModeUpdate':
        final ConsentsV2 consents =
            ConsentsV2.fromDictionary(event["googleConsentV2"]);
        for (var listener in listeners) {
          listener.onGoogleConsentModeUpdate(consents);
        }
        break;

      default:
        if (kDebugMode) {
          print('Received invalid event: $eventType');
        }
        break;
    }
  }

  handleDAxeptioErrorEvent(dynamic error) =>
      print('Received error: ${error.message}');

  addEventListener(AxeptioEventListener listener) {
    if (!listeners.contains(listener)) {
      listeners.add(listener);
    }
  }

  removeEventListener(AxeptioEventListener listener) {
    listeners.remove(listener);
  }
}
