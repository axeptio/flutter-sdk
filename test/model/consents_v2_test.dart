import 'package:axeptio_sdk/src/model/consents_v2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsentsV2', () {
    test('constructor creates object with all properties', () {
      final consents = ConsentsV2(true, false, true, false);

      expect(consents.analyticsStorage, isTrue);
      expect(consents.adStorage, isFalse);
      expect(consents.adUserData, isTrue);
      expect(consents.adPersonalization, isFalse);
    });

    test('constructor with all true values', () {
      final consents = ConsentsV2(true, true, true, true);

      expect(consents.analyticsStorage, isTrue);
      expect(consents.adStorage, isTrue);
      expect(consents.adUserData, isTrue);
      expect(consents.adPersonalization, isTrue);
    });

    test('constructor with all false values', () {
      final consents = ConsentsV2(false, false, false, false);

      expect(consents.analyticsStorage, isFalse);
      expect(consents.adStorage, isFalse);
      expect(consents.adUserData, isFalse);
      expect(consents.adPersonalization, isFalse);
    });

    group('fromDictionary constructor', () {
      test('creates object from valid dictionary', () {
        final dictionary = {
          'analyticsStorage': true,
          'adStorage': false,
          'adUserData': true,
          'adPersonalization': false,
        };

        final consents = ConsentsV2.fromDictionary(dictionary);

        expect(consents.analyticsStorage, isTrue);
        expect(consents.adStorage, isFalse);
        expect(consents.adUserData, isTrue);
        expect(consents.adPersonalization, isFalse);
      });

      test('creates object from dictionary with different boolean combinations', () {
        final dictionary = {
          'analyticsStorage': false,
          'adStorage': true,
          'adUserData': false,
          'adPersonalization': true,
        };

        final consents = ConsentsV2.fromDictionary(dictionary);

        expect(consents.analyticsStorage, isFalse);
        expect(consents.adStorage, isTrue);
        expect(consents.adUserData, isFalse);
        expect(consents.adPersonalization, isTrue);
      });

      test('handles dictionary with extra keys', () {
        final dictionary = {
          'analyticsStorage': true,
          'adStorage': false,
          'adUserData': true,
          'adPersonalization': false,
          'extraKey': 'extraValue',
          'anotherExtra': 123,
        };

        final consents = ConsentsV2.fromDictionary(dictionary);

        expect(consents.analyticsStorage, isTrue);
        expect(consents.adStorage, isFalse);
        expect(consents.adUserData, isTrue);
        expect(consents.adPersonalization, isFalse);
        // Extra keys should be ignored
      });

      test('handles case-sensitive keys correctly', () {
        final dictionary = {
          'AnalyticsStorage': true,  // Wrong case
          'adStorage': false,
          'adUserData': true,
          'AdPersonalization': false,  // Wrong case
        };

        // This will cause type errors since the model expects bool but gets null
        // We'll test what actually happens
        expect(() => ConsentsV2.fromDictionary(dictionary), throwsA(isA<TypeError>()));
      });
    });

    group('Edge cases and error handling', () {
      test('fromDictionary with null dictionary throws NoSuchMethodError', () {
        expect(() => ConsentsV2.fromDictionary(null), throwsA(isA<NoSuchMethodError>()));
      });

      test('properties can be modified after creation', () {
        final consents = ConsentsV2(true, false, true, false);
        
        // Properties should be mutable
        consents.analyticsStorage = false;
        consents.adStorage = true;
        
        expect(consents.analyticsStorage, isFalse);
        expect(consents.adStorage, isTrue);
        expect(consents.adUserData, isTrue);  // Unchanged
        expect(consents.adPersonalization, isFalse);  // Unchanged
      });

      test('objects created with different constructors are independent', () {
        final consents1 = ConsentsV2(true, false, true, false);
        final consents2 = ConsentsV2.fromDictionary({
          'analyticsStorage': false,
          'adStorage': true,
          'adUserData': false,
          'adPersonalization': true,
        });

        expect(consents1.analyticsStorage, isTrue);
        expect(consents2.analyticsStorage, isFalse);
        expect(consents1.adStorage, isFalse);
        expect(consents2.adStorage, isTrue);
      });

      test('real-world usage with valid boolean values', () {
        // Simulate real Google Consent Mode v2 boolean values
        final dictionary = {
          'analyticsStorage': true,
          'adStorage': false,
          'adUserData': true,
          'adPersonalization': false,
        };

        final consents = ConsentsV2.fromDictionary(dictionary);

        expect(consents.analyticsStorage, isTrue);
        expect(consents.adStorage, isFalse);
        expect(consents.adUserData, isTrue);
        expect(consents.adPersonalization, isFalse);
      });
    });
  });
}