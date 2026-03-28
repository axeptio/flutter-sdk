// ignore_for_file: avoid_print

import 'package:axeptio_sdk/src/exceptions/axeptio_exceptions.dart';
import 'package:axeptio_sdk/src/model/consents_v2.dart';
import 'package:flutter/foundation.dart';

import 'event_listener.dart';

class EventsHandler {
  List<AxeptioEventListener> listeners = [];

  /// Creates an [EventsHandler].
  ///
  /// If [stream] is provided, events are received from it automatically.
  /// When omitted (WebView implementation), events are dispatched directly
  /// via listener callbacks by the caller — no platform channel subscription is made.
  EventsHandler([Stream<dynamic>? stream]) {
    stream?.listen(handleAxeptioEvent, onError: handleDAxeptioErrorEvent);
  }

  handleAxeptioEvent(dynamic event) {
    final String eventType = event['type'].toString();

    switch (eventType) {
      case 'onPopupClosedEvent':
        for (final listener in List.of(listeners)) {
          listener.onPopupClosedEvent();
        }
        break;

      case 'onConsentCleared':
        for (final listener in List.of(listeners)) {
          listener.onConsentCleared();
        }
        break;

      case 'onGoogleConsentModeUpdate':
        final ConsentsV2 consents =
            ConsentsV2.fromDictionary(event["googleConsentV2"]);
        for (final listener in List.of(listeners)) {
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

  handleDAxeptioErrorEvent(dynamic error) {
    final exception = error is AxeptioException
        ? error
        : AxeptioException(error.toString(), cause: error);
    for (final listener in List.of(listeners)) {
      try {
        listener.onError(exception);
      } catch (listenerError) {
        if (kDebugMode) {
          print('Error in AxeptioEventListener.onError: $listenerError');
        }
      }
    }
  }

  addEventListener(AxeptioEventListener listener) {
    if (!listeners.contains(listener)) {
      listeners.add(listener);
    }
  }

  removeEventListener(AxeptioEventListener listener) {
    listeners.remove(listener);
  }
}
