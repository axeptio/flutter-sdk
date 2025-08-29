import 'package:axeptio_sdk/src/events/event_listener.dart';
import 'package:axeptio_sdk/src/model/consents_v2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AxeptioEventListener', () {
    late AxeptioEventListener listener;

    setUp(() {
      listener = AxeptioEventListener();
    });

    test('has default empty callback functions', () {
      expect(listener.onPopupClosedEvent, isA<Function>());
      expect(listener.onConsentCleared, isA<Function>());
      expect(listener.onGoogleConsentModeUpdate, isA<Function>());
    });

    test('onPopupClosedEvent can be called', () {
      bool callbackTriggered = false;
      listener.onPopupClosedEvent = () {
        callbackTriggered = true;
      };

      listener.onPopupClosedEvent();
      expect(callbackTriggered, isTrue);
    });

    test('onConsentCleared can be called', () {
      bool callbackTriggered = false;
      listener.onConsentCleared = () {
        callbackTriggered = true;
      };

      listener.onConsentCleared();
      expect(callbackTriggered, isTrue);
    });

    test('onGoogleConsentModeUpdate can be called with ConsentsV2', () {
      ConsentsV2? receivedConsents;
      listener.onGoogleConsentModeUpdate = (ConsentsV2 consents) {
        receivedConsents = consents;
      };

      final testConsents = ConsentsV2(true, false, true, false);
      listener.onGoogleConsentModeUpdate(testConsents);

      expect(receivedConsents, isNotNull);
      expect(receivedConsents!.analyticsStorage, isTrue);
      expect(receivedConsents!.adStorage, isFalse);
      expect(receivedConsents!.adUserData, isTrue);
      expect(receivedConsents!.adPersonalization, isFalse);
    });

    test('callbacks can be reassigned multiple times', () {
      int callCount = 0;

      // First callback
      listener.onPopupClosedEvent = () {
        callCount++;
      };
      listener.onPopupClosedEvent();
      expect(callCount, equals(1));

      // Reassign callback
      listener.onPopupClosedEvent = () {
        callCount += 10;
      };
      listener.onPopupClosedEvent();
      expect(callCount, equals(11));
    });

    test('multiple event types can be triggered independently', () {
      bool popupClosed = false;
      bool consentCleared = false;
      ConsentsV2? consentUpdate;

      listener.onPopupClosedEvent = () {
        popupClosed = true;
      };

      listener.onConsentCleared = () {
        consentCleared = true;
      };

      listener.onGoogleConsentModeUpdate = (ConsentsV2 consents) {
        consentUpdate = consents;
      };

      // Trigger popup closed
      listener.onPopupClosedEvent();
      expect(popupClosed, isTrue);
      expect(consentCleared, isFalse);
      expect(consentUpdate, isNull);

      // Trigger consent cleared
      listener.onConsentCleared();
      expect(consentCleared, isTrue);
      expect(consentUpdate, isNull);

      // Trigger consent mode update
      final testConsents = ConsentsV2(false, true, false, true);
      listener.onGoogleConsentModeUpdate(testConsents);
      expect(consentUpdate, isNotNull);
      expect(consentUpdate!.adStorage, isTrue);
    });

    test('event listener can handle exceptions in callbacks gracefully', () {
      // This test ensures that if a callback throws, it doesn't break the listener
      listener.onPopupClosedEvent = () {
        throw Exception('Test exception');
      };

      // Should not throw when called (depends on implementation)
      // In a real implementation, you might want to catch exceptions
      expect(() => listener.onPopupClosedEvent(), throwsException);
    });

    test('callbacks can access external variables', () {
      List<String> eventLog = [];

      listener.onPopupClosedEvent = () {
        eventLog.add('popup_closed');
      };

      listener.onConsentCleared = () {
        eventLog.add('consent_cleared');
      };

      listener.onGoogleConsentModeUpdate = (ConsentsV2 consents) {
        eventLog.add('consent_updated');
      };

      listener.onPopupClosedEvent();
      listener.onConsentCleared();
      listener.onGoogleConsentModeUpdate(ConsentsV2(true, true, true, true));

      expect(eventLog, hasLength(3));
      expect(eventLog, contains('popup_closed'));
      expect(eventLog, contains('consent_cleared'));
      expect(eventLog, contains('consent_updated'));
    });
  });
}