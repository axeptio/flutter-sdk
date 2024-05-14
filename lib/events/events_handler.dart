import 'package:axeptio_sdk/model/consentsV2.dart';
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

      case 'onConsentChanged':
        for (var listener in listeners) {
          listener.onConsentChanged();
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

  // ignore: avoid_print
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
