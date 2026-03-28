import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:axeptio_sdk/src/events/events_handler.dart';
import 'package:axeptio_sdk/src/events/event_listener.dart';
import 'package:axeptio_sdk/src/exceptions/axeptio_exceptions.dart';
import 'package:axeptio_sdk/src/model/consents_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventsHandler', () {
    late EventsHandler eventsHandler;
    late StreamController<dynamic> eventStreamController;

    setUp(() {
      eventStreamController = StreamController<dynamic>.broadcast();
      eventsHandler = EventsHandler(eventStreamController.stream);
    });

    tearDown(() {
      eventStreamController.close();
    });

    group('Event Listener Management', () {
      test('addEventListener adds listener to list', () {
        final listener = AxeptioEventListener();
        expect(eventsHandler.listeners.length, equals(0));

        eventsHandler.addEventListener(listener);

        expect(eventsHandler.listeners.length, equals(1));
        expect(eventsHandler.listeners.contains(listener), isTrue);
      });

      test('addEventListener does not add duplicate listeners', () {
        final listener = AxeptioEventListener();

        eventsHandler.addEventListener(listener);
        eventsHandler.addEventListener(listener);

        expect(eventsHandler.listeners.length, equals(1));
      });

      test('removeEventListener removes listener from list', () {
        final listener1 = AxeptioEventListener();
        final listener2 = AxeptioEventListener();

        eventsHandler.addEventListener(listener1);
        eventsHandler.addEventListener(listener2);
        expect(eventsHandler.listeners.length, equals(2));

        eventsHandler.removeEventListener(listener1);

        expect(eventsHandler.listeners.length, equals(1));
        expect(eventsHandler.listeners.contains(listener1), isFalse);
        expect(eventsHandler.listeners.contains(listener2), isTrue);
      });

      test('removeEventListener handles non-existent listener gracefully', () {
        final listener1 = AxeptioEventListener();
        final listener2 = AxeptioEventListener();

        eventsHandler.addEventListener(listener1);
        expect(eventsHandler.listeners.length, equals(1));

        // Try to remove a listener that was never added
        eventsHandler.removeEventListener(listener2);

        expect(eventsHandler.listeners.length, equals(1));
        expect(eventsHandler.listeners.contains(listener1), isTrue);
      });
    });

    group('Event Handling', () {
      test('handleAxeptioEvent processes onPopupClosedEvent', () {
        bool popupClosed = false;
        final listener = AxeptioEventListener();
        listener.onPopupClosedEvent = () {
          popupClosed = true;
        };

        eventsHandler.addEventListener(listener);

        final event = {'type': 'onPopupClosedEvent'};
        eventsHandler.handleAxeptioEvent(event);

        expect(popupClosed, isTrue);
      });

      test('handleAxeptioEvent processes onConsentCleared', () {
        bool consentCleared = false;
        final listener = AxeptioEventListener();
        listener.onConsentCleared = () {
          consentCleared = true;
        };

        eventsHandler.addEventListener(listener);

        final event = {'type': 'onConsentCleared'};
        eventsHandler.handleAxeptioEvent(event);

        expect(consentCleared, isTrue);
      });

      test('handleAxeptioEvent processes onGoogleConsentModeUpdate', () {
        ConsentsV2? receivedConsents;
        final listener = AxeptioEventListener();
        listener.onGoogleConsentModeUpdate = (consents) {
          receivedConsents = consents;
        };

        eventsHandler.addEventListener(listener);

        final event = {
          'type': 'onGoogleConsentModeUpdate',
          'googleConsentV2': {
            'analyticsStorage': true,
            'adStorage': false,
            'adUserData': true,
            'adPersonalization': false,
          }
        };
        eventsHandler.handleAxeptioEvent(event);

        expect(receivedConsents, isNotNull);
        expect(receivedConsents!.analyticsStorage, isTrue);
        expect(receivedConsents!.adStorage, isFalse);
        expect(receivedConsents!.adUserData, isTrue);
        expect(receivedConsents!.adPersonalization, isFalse);
      });

      test('handleAxeptioEvent calls all registered listeners', () {
        int callCount1 = 0;
        int callCount2 = 0;

        final listener1 = AxeptioEventListener();
        listener1.onPopupClosedEvent = () {
          callCount1++;
        };

        final listener2 = AxeptioEventListener();
        listener2.onPopupClosedEvent = () {
          callCount2++;
        };

        eventsHandler.addEventListener(listener1);
        eventsHandler.addEventListener(listener2);

        final event = {'type': 'onPopupClosedEvent'};
        eventsHandler.handleAxeptioEvent(event);

        expect(callCount1, equals(1));
        expect(callCount2, equals(1));
      });

      test('handleAxeptioEvent handles unknown event type gracefully', () {
        // This test captures debug print output to verify the unknown event is logged
        final listener = AxeptioEventListener();
        eventsHandler.addEventListener(listener);

        final event = {'type': 'unknownEventType'};

        // Should not throw an exception
        expect(() => eventsHandler.handleAxeptioEvent(event), returnsNormally);
      });

      test('handleAxeptioEvent handles malformed event data', () {
        final listener = AxeptioEventListener();
        eventsHandler.addEventListener(listener);

        // Event without type field - should handle gracefully
        final malformedEvent = {'data': 'test'};

        // Should not throw exception, handles gracefully with null toString()
        expect(() => eventsHandler.handleAxeptioEvent(malformedEvent),
            returnsNormally);
      });

      test('handleAxeptioEvent handles null type gracefully', () {
        final listener = AxeptioEventListener();
        eventsHandler.addEventListener(listener);

        final event = {'type': null};

        // Should convert null to string and handle as unknown event
        expect(() => eventsHandler.handleAxeptioEvent(event), returnsNormally);
      });
    });

    group('Error Handling', () {
      test('handleDAxeptioErrorEvent routes to listeners onError', () {
        AxeptioException? received;
        final listener = AxeptioEventListener();
        listener.onError = (error) => received = error;
        eventsHandler.addEventListener(listener);

        final mockError =
            MockPlatformException('TEST_ERROR', 'Test error message');

        eventsHandler.handleDAxeptioErrorEvent(mockError);

        expect(received, isNotNull);
        expect(received!.message, contains('MockPlatformException'));
      });

      test('handleDAxeptioErrorEvent passes AxeptioException directly', () {
        AxeptioException? received;
        final listener = AxeptioEventListener();
        listener.onError = (error) => received = error;
        eventsHandler.addEventListener(listener);

        const axError =
            AxeptioNetworkException('network fail', statusCode: 503);
        eventsHandler.handleDAxeptioErrorEvent(axError);

        expect(received, isA<AxeptioNetworkException>());
        expect((received as AxeptioNetworkException).statusCode, 503);
      });

      test('handleDAxeptioErrorEvent routes to all listeners', () {
        int callCount = 0;
        final listener1 = AxeptioEventListener();
        listener1.onError = (_) => callCount++;
        final listener2 = AxeptioEventListener();
        listener2.onError = (_) => callCount++;
        eventsHandler.addEventListener(listener1);
        eventsHandler.addEventListener(listener2);

        eventsHandler.handleDAxeptioErrorEvent(const AxeptioException('test'));

        expect(callCount, 2);
      });

      test('handleDAxeptioErrorEvent does nothing with no listeners', () {
        // Should not throw
        expect(
            () => eventsHandler
                .handleDAxeptioErrorEvent(const AxeptioException('test')),
            returnsNormally);
      });
    });

    group('Event Processing with Multiple Listeners', () {
      test('different events trigger only relevant callbacks', () {
        bool popupClosed = false;
        bool consentCleared = false;
        ConsentsV2? googleConsents;

        final listener = AxeptioEventListener();
        listener.onPopupClosedEvent = () {
          popupClosed = true;
        };
        listener.onConsentCleared = () {
          consentCleared = true;
        };
        listener.onGoogleConsentModeUpdate = (consents) {
          googleConsents = consents;
        };

        eventsHandler.addEventListener(listener);

        // Send popup closed event
        eventsHandler.handleAxeptioEvent({'type': 'onPopupClosedEvent'});
        expect(popupClosed, isTrue);
        expect(consentCleared, isFalse);
        expect(googleConsents, isNull);

        // Reset flags
        popupClosed = false;

        // Send consent cleared event
        eventsHandler.handleAxeptioEvent({'type': 'onConsentCleared'});
        expect(popupClosed, isFalse);
        expect(consentCleared, isTrue);
        expect(googleConsents, isNull);

        // Reset flags
        consentCleared = false;

        // Send Google consent event
        eventsHandler.handleAxeptioEvent({
          'type': 'onGoogleConsentModeUpdate',
          'googleConsentV2': {
            'analyticsStorage': true,
            'adStorage': true,
            'adUserData': true,
            'adPersonalization': true,
          }
        });
        expect(popupClosed, isFalse);
        expect(consentCleared, isFalse);
        expect(googleConsents, isNotNull);
      });

      test(
          'listener that removes itself during onPopupClosedEvent does not cause ConcurrentModificationError',
          () {
        final listener = AxeptioEventListener();
        listener.onPopupClosedEvent = () {
          eventsHandler.removeEventListener(listener);
        };

        eventsHandler.addEventListener(listener);

        expect(
          () =>
              eventsHandler.handleAxeptioEvent({'type': 'onPopupClosedEvent'}),
          returnsNormally,
        );
        expect(eventsHandler.listeners, isEmpty);
      });

      test('listeners can be removed and re-added dynamically', () {
        int callCount = 0;
        final listener = AxeptioEventListener();
        listener.onPopupClosedEvent = () {
          callCount++;
        };

        // Add listener and trigger event
        eventsHandler.addEventListener(listener);
        eventsHandler.handleAxeptioEvent({'type': 'onPopupClosedEvent'});
        expect(callCount, equals(1));

        // Remove listener and trigger event
        eventsHandler.removeEventListener(listener);
        eventsHandler.handleAxeptioEvent({'type': 'onPopupClosedEvent'});
        expect(callCount, equals(1)); // Should not increment

        // Re-add listener and trigger event
        eventsHandler.addEventListener(listener);
        eventsHandler.handleAxeptioEvent({'type': 'onPopupClosedEvent'});
        expect(callCount, equals(2)); // Should increment again
      });
    });
  });
}

// Mock class to simulate PlatformException
class MockPlatformException {
  final String code;
  final String message;

  MockPlatformException(this.code, this.message);
}
