import 'package:axeptio_sdk/src/model/vendor_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VendorInfo', () {
    test('constructor creates object with all properties', () {
      final vendorInfo = VendorInfo(
        id: 755,
        name: 'Google LLC',
        consented: true,
        description: 'Google advertising services',
        purposes: [1, 2, 3, 4],
      );

      expect(vendorInfo.id, equals(755));
      expect(vendorInfo.name, equals('Google LLC'));
      expect(vendorInfo.consented, isTrue);
      expect(vendorInfo.description, equals('Google advertising services'));
      expect(vendorInfo.purposes, equals([1, 2, 3, 4]));
    });

    test('constructor works with minimal required parameters', () {
      final vendorInfo = VendorInfo(
        id: 123,
        name: 'Test Vendor',
        consented: false,
        purposes: [1, 2],
      );

      expect(vendorInfo.id, equals(123));
      expect(vendorInfo.name, equals('Test Vendor'));
      expect(vendorInfo.consented, isFalse);
      expect(vendorInfo.description, isNull);
      expect(vendorInfo.purposes, equals([1, 2]));
    });

    test('constructor works with empty purposes list', () {
      final vendorInfo = VendorInfo(
        id: 456,
        name: 'Empty Purposes Vendor',
        consented: true,
        purposes: [],
      );

      expect(vendorInfo.purposes, isEmpty);
    });

    group('fromJson constructor', () {
      test('creates object from valid JSON with all fields', () {
        final json = {
          'id': 755,
          'name': 'Google LLC',
          'consented': true,
          'description': 'Google advertising services',
          'purposes': [1, 2, 3, 4],
        };

        final vendorInfo = VendorInfo.fromJson(json, true);

        expect(vendorInfo.id, equals(755));
        expect(vendorInfo.name, equals('Google LLC'));
        expect(vendorInfo.consented, isTrue);
        expect(vendorInfo.description, equals('Google advertising services'));
        expect(vendorInfo.purposes, equals([1, 2, 3, 4]));
      });

      test('creates object from JSON with minimal required fields', () {
        final json = {
          'id': 123,
          'name': 'Test Vendor',
          'consented': false,
          'purposes': [1, 2],
        };

        final vendorInfo = VendorInfo.fromJson(json, false);

        expect(vendorInfo.id, equals(123));
        expect(vendorInfo.name, equals('Test Vendor'));
        expect(vendorInfo.consented, isFalse);
        expect(vendorInfo.description, isNull);
        expect(vendorInfo.purposes, equals([1, 2]));
      });

      test('handles null description in JSON', () {
        final json = {
          'id': 456,
          'name': 'No Description Vendor',
          'consented': true,
          'description': null,
          'purposes': [3, 4, 5],
        };

        final vendorInfo = VendorInfo.fromJson(json, true);

        expect(vendorInfo.description, isNull);
      });

      test('handles empty purposes array in JSON', () {
        final json = {
          'id': 789,
          'name': 'No Purposes Vendor',
          'consented': false,
          'purposes': <int>[],
        };

        final vendorInfo = VendorInfo.fromJson(json, true);

        expect(vendorInfo.purposes, isEmpty);
      });

      test('throws when required fields are missing', () {
        final json = {
          'name': 'Missing ID Vendor',
          'consented': true,
          'purposes': [1, 2],
        };

        expect(() => VendorInfo.fromJson(json, true), throwsA(isA<TypeError>()));
      });

      test('handles different numeric types for ID', () {
        final json = {
          'id': 755.0, // Double instead of int
          'name': 'Google LLC',
          'consented': true,
          'purposes': [1, 2],
        };

        final vendorInfo = VendorInfo.fromJson(json, true);
        expect(vendorInfo.id, equals(755));
      });
    });

    group('toJson method', () {
      test('converts object to JSON with all fields', () {
        final vendorInfo = VendorInfo(
          id: 755,
          name: 'Google LLC',
          consented: true,
          description: 'Google advertising services',
          purposes: [1, 2, 3, 4],
        );

        final json = vendorInfo.toJson();

        expect(json['id'], equals(755));
        expect(json['name'], equals('Google LLC'));
        expect(json['consented'], isTrue);
        expect(json['description'], equals('Google advertising services'));
        expect(json['purposes'], equals([1, 2, 3, 4]));
      });

      test('converts object to JSON with null description', () {
        final vendorInfo = VendorInfo(
          id: 123,
          name: 'Test Vendor',
          consented: false,
          purposes: [1, 2],
        );

        final json = vendorInfo.toJson();

        expect(json['id'], equals(123));
        expect(json['name'], equals('Test Vendor'));
        expect(json['consented'], isFalse);
        expect(json['description'], isNull);
        expect(json['purposes'], equals([1, 2]));
      });

      test('round-trip conversion maintains data integrity', () {
        final original = VendorInfo(
          id: 755,
          name: 'Google LLC',
          consented: true,
          description: 'Google advertising services',
          purposes: [1, 2, 3, 4],
        );

        final json = original.toJson();
        final reconstructed = VendorInfo.fromJson(json, original.consented);

        expect(reconstructed.id, equals(original.id));
        expect(reconstructed.name, equals(original.name));
        expect(reconstructed.consented, equals(original.consented));
        expect(reconstructed.description, equals(original.description));
        expect(reconstructed.purposes, equals(original.purposes));
      });
    });

    group('copyWith method', () {
      test('creates copy with updated fields', () {
        final original = VendorInfo(
          id: 755,
          name: 'Google LLC',
          consented: true,
          description: 'Original description',
          purposes: [1, 2],
        );

        final updated = original.copyWith(
          name: 'Updated Google LLC',
          consented: false,
          purposes: [3, 4, 5],
        );

        expect(updated.id, equals(755)); // Unchanged
        expect(updated.name, equals('Updated Google LLC')); // Changed
        expect(updated.consented, isFalse); // Changed
        expect(updated.description, equals('Original description')); // Unchanged
        expect(updated.purposes, equals([3, 4, 5])); // Changed
      });

      test('creates exact copy when no parameters provided', () {
        final original = VendorInfo(
          id: 123,
          name: 'Test Vendor',
          consented: true,
          purposes: [1, 2, 3],
        );

        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.name, equals(original.name));
        expect(copy.consented, equals(original.consented));
        expect(copy.description, equals(original.description));
        expect(copy.purposes, equals(original.purposes));
      });

      test('copies all fields when no parameters provided', () {
        final original = VendorInfo(
          id: 456,
          name: 'Has Description',
          consented: true,
          description: 'Original description',
          purposes: [1],
        );

        final updated = original.copyWith();

        expect(updated.description, equals('Original description'));
        expect(updated.id, equals(original.id));
        expect(updated.name, equals(original.name));
      });
    });

    group('equality and hashCode', () {
      test('objects with same values are equal', () {
        final vendor1 = VendorInfo(
          id: 755,
          name: 'Google LLC',
          consented: true,
          description: 'Google services',
          purposes: [1, 2, 3],
          legitimateInterestPurposes: const [],
          specialFeatures: const [],
          specialPurposes: const [],
        );

        final vendor2 = VendorInfo(
          id: 755,
          name: 'Google LLC',
          consented: true,
          description: 'Google services',
          purposes: [1, 2, 3],
          legitimateInterestPurposes: const [],
          specialFeatures: const [],
          specialPurposes: const [],
        );

        expect(vendor1, equals(vendor2));
      });

      test('objects with different values are not equal', () {
        final vendor1 = VendorInfo(
          id: 755,
          name: 'Google LLC',
          consented: true,
          purposes: [1, 2, 3],
        );

        final vendor2 = VendorInfo(
          id: 756, // Different ID
          name: 'Google LLC',
          consented: true,
          purposes: [1, 2, 3],
        );

        expect(vendor1, isNot(equals(vendor2)));
      });

      test('objects with same null descriptions are equal', () {
        final vendor1 = VendorInfo(
          id: 123,
          name: 'Test',
          consented: false,
          purposes: [1],
        );

        final vendor2 = VendorInfo(
          id: 123,
          name: 'Test',
          consented: false,
          purposes: [1],
        );

        expect(vendor1, equals(vendor2));
      });

      test('objects with different purpose lists are not equal', () {
        final vendor1 = VendorInfo(
          id: 123,
          name: 'Test',
          consented: true,
          purposes: [1, 2, 3],
        );

        final vendor2 = VendorInfo(
          id: 123,
          name: 'Test',
          consented: true,
          purposes: [1, 2], // Different purposes
        );

        expect(vendor1, isNot(equals(vendor2)));
      });
    });

    group('toString method', () {
      test('provides readable string representation', () {
        final vendorInfo = VendorInfo(
          id: 755,
          name: 'Google LLC',
          consented: true,
          description: 'Google services',
          purposes: [1, 2, 3],
        );

        final str = vendorInfo.toString();

        expect(str, contains('VendorInfo'));
        expect(str, contains('755'));
        expect(str, contains('Google LLC'));
        expect(str, contains('true'));
        expect(str, contains('Google services'));
        expect(str, contains('[1, 2, 3]'));
      });

      test('handles null description in string representation', () {
        final vendorInfo = VendorInfo(
          id: 123,
          name: 'Test',
          consented: false,
          purposes: [1],
        );

        final str = vendorInfo.toString();

        expect(str, contains('null'));
      });
    });

    group('Real-world scenarios', () {
      test('handles typical TCF vendor data', () {
        final vendorInfo = VendorInfo(
          id: 755,
          name: 'Google LLC',
          consented: true,
          description: 'We collect and process personal data for the following purposes: Store and/or access information on a device, Select basic ads, Create a personalised ads profile, Select personalised ads, Create a personalised content profile, Select personalised content, Measure ad performance, Measure content performance, Apply market research to generate audience insights, Develop and improve products.',
          purposes: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        );

        expect(vendorInfo.id, equals(755));
        expect(vendorInfo.name, isNotEmpty);
        expect(vendorInfo.description, isNotEmpty);
        expect(vendorInfo.purposes, isNotEmpty);
      });

      test('handles vendor with no consent', () {
        final vendorInfo = VendorInfo(
          id: 50,
          name: 'Criteo SA',
          consented: false,
          purposes: [1, 2, 3],
        );

        expect(vendorInfo.consented, isFalse);
      });

      test('handles vendor with single purpose', () {
        final vendorInfo = VendorInfo(
          id: 100,
          name: 'Single Purpose Vendor',
          consented: true,
          purposes: [1],
        );

        expect(vendorInfo.purposes.length, equals(1));
        expect(vendorInfo.purposes.first, equals(1));
      });
    });
  });
}