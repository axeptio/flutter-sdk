import 'dart:convert';
import 'dart:io';

import 'package:axeptio_sdk/src/exceptions/axeptio_exceptions.dart';
import 'package:axeptio_sdk/src/gvl/gvl_service.dart';
import 'package:axeptio_sdk/src/model/vendor_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sampleVendorJson = {
  'vendors': {
    '1': {
      'name': 'Vendor One',
      'purposes': [1, 2],
      'legIntPurposes': [3],
      'specialFeatures': [1],
      'specialPurposes': [2],
      'cookieMaxAgeSeconds': 86400,
      'usesCookies': true,
      'usesNonCookieAccess': false,
      'policyUrl': 'https://example.com/privacy',
      'description': 'Test vendor',
    },
    '2': {
      'name': 'Vendor Two',
      'purposes': [1],
      'legIntPurposes': [],
      'specialFeatures': [],
      'specialPurposes': [],
      'usesCookies': false,
      'usesNonCookieAccess': true,
    },
  },
  'gvlSpecificationVersion': '3',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GVLService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Reset singleton for each test
    GVLService.resetInstance();
    service = GVLService.instance;
  });

  group('GVLService', () {
    group('loadGVL from cache', () {
      test('loads successfully from valid cache', () async {
        final body = jsonEncode(_sampleVendorJson);
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'gvl_data': body,
          'gvl_version': '3',
          'gvl_timestamp': nowMs,
        });
        GVLService.resetInstance();
        service = GVLService.instance;

        final result = await service.loadGVL();

        expect(result, isTrue);
        expect(service.isGVLLoaded(), isTrue);
        expect(service.getGVLVersion(), '3');
      });

      test('skips expired cache and falls back to remote failure', () async {
        final expiredMs = DateTime.now()
            .subtract(const Duration(days: 8))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'gvl_data': jsonEncode(_sampleVendorJson),
          'gvl_version': '3',
          'gvl_timestamp': expiredMs,
        });
        GVLService.resetInstance();
        service = GVLService.instance;

        // Without mock HTTP, remote fetch will throw
        expect(
            () => service.loadGVL(), throwsA(isA<AxeptioNetworkException>()));
      });

      test('throws when cache keys are missing and remote fails', () async {
        SharedPreferences.setMockInitialValues({'gvl_data': 'some data'});
        GVLService.resetInstance();
        service = GVLService.instance;

        final mockClient =
            MockClient((_) async => http.Response('Not Found', 404));

        expect(
          () => http.runWithClient(
            () => service.loadGVL(),
            () => mockClient,
          ),
          throwsA(isA<AxeptioNetworkException>()),
        );
      });

      test('throws AxeptioConsentException on corrupt cache data', () async {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'gvl_data': 'not valid json{{{',
          'gvl_version': '3',
          'gvl_timestamp': nowMs,
        });
        GVLService.resetInstance();
        service = GVLService.instance;

        expect(
          () => service.loadGVL(),
          throwsA(isA<AxeptioConsentException>()),
        );
      });
    });

    group('loadGVL from remote', () {
      test('succeeds with 200 response and saves to cache', () async {
        final body = jsonEncode(_sampleVendorJson);
        final mockClient = MockClient((_) async => http.Response(body, 200));

        final result = await http.runWithClient(
          () => service.loadGVL(gvlVersion: '3'),
          () => mockClient,
        );

        expect(result, isTrue);
        expect(service.isGVLLoaded(), isTrue);

        // Verify it was saved to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('gvl_data'), isNotNull);
        expect(prefs.getString('gvl_version'), isNotNull);
        expect(prefs.getInt('gvl_timestamp'), isNotNull);
      });

      test('throws AxeptioNetworkException on non-200 HTTP status', () async {
        final mockClient =
            MockClient((_) async => http.Response('Not Found', 404));

        expect(
          () => http.runWithClient(
            () => service.loadGVL(gvlVersion: 'bad'),
            () => mockClient,
          ),
          throwsA(isA<AxeptioNetworkException>()),
        );
      });

      test('throws AxeptioNetworkException when HTTP throws', () async {
        final mockClient =
            MockClient((_) async => throw Exception('Network error'));

        expect(
          () => http.runWithClient(
            () => service.loadGVL(),
            () => mockClient,
          ),
          throwsA(isA<AxeptioNetworkException>()),
        );
      });

      test('throws AxeptioNetworkException on SocketException', () async {
        final mockClient = MockClient(
            (_) async => throw const SocketException('Connection refused'));

        expect(
          () => http.runWithClient(
            () => service.loadGVL(gvlVersion: '3'),
            () => mockClient,
          ),
          throwsA(isA<AxeptioNetworkException>()),
        );
      });

      test('throws AxeptioConsentException on invalid response JSON', () async {
        final mockClient =
            MockClient((_) async => http.Response('not json{{{', 200));

        expect(
          () => http.runWithClient(
            () => service.loadGVL(gvlVersion: '3'),
            () => mockClient,
          ),
          throwsA(isA<AxeptioConsentException>()),
        );
      });

      test('returns false when concurrent load is in progress', () async {
        // Start a load but don't await it
        final first = http.runWithClient(
          () => service.loadGVL(gvlVersion: '3'),
          () => MockClient((_) async {
            await Future.delayed(const Duration(milliseconds: 50));
            return http.Response(jsonEncode(_sampleVendorJson), 200);
          }),
        );
        // Second call while first is in progress
        final second = service.loadGVL();
        expect(await second, isFalse);
        await first;
      });

      test('parses extended vendor fields correctly', () async {
        final body = jsonEncode(_sampleVendorJson);
        final mockClient = MockClient((_) async => http.Response(body, 200));

        await http.runWithClient(
          () => service.loadGVL(gvlVersion: '3'),
          () => mockClient,
        );

        final vendor = service.getVendorInfo(1);
        expect(vendor, isNotNull);
        expect(vendor!.legitimateInterestPurposes, [3]);
        expect(vendor.specialFeatures, [1]);
        expect(vendor.specialPurposes, [2]);
        expect(vendor.cookieMaxAgeSeconds, 86400);
        expect(vendor.usesCookies, isTrue);
        expect(vendor.usesNonCookieAccess, isFalse);
        expect(vendor.policyUrl, 'https://example.com/privacy');
      });

      test('throws on malformed vendors JSON', () async {
        final badJson = jsonEncode({'vendors': 'not_a_map'});
        final mockClient = MockClient((_) async => http.Response(badJson, 200));

        // _parseVendorList will throw a TypeError when casting
        expect(
          () => http.runWithClient(
            () => service.loadGVL(gvlVersion: '3'),
            () => mockClient,
          ),
          throwsA(isA<AxeptioNetworkException>()),
        );
      });

      test('uses tcfPolicyVersion as fallback version', () async {
        final body = jsonEncode({
          'vendors': {},
          'tcfPolicyVersion': '4',
        });
        final mockClient = MockClient((_) async => http.Response(body, 200));

        await http.runWithClient(
          () => service.loadGVL(gvlVersion: '4'),
          () => mockClient,
        );

        expect(service.getGVLVersion(), '4');
      });
    });

    group('getVendorInfo', () {
      test('returns null when not loaded', () {
        expect(service.getVendorInfo(1), isNull);
      });

      test('returns VendorInfo after loading', () async {
        final mockClient = MockClient(
            (_) async => http.Response(jsonEncode(_sampleVendorJson), 200));
        await http.runWithClient(
          () => service.loadGVL(gvlVersion: '3'),
          () => mockClient,
        );

        final info = service.getVendorInfo(1);
        expect(info, isNotNull);
        expect(info!.name, 'Vendor One');
      });

      test('returns null for unknown vendor', () async {
        final mockClient = MockClient(
            (_) async => http.Response(jsonEncode(_sampleVendorJson), 200));
        await http.runWithClient(
          () => service.loadGVL(gvlVersion: '3'),
          () => mockClient,
        );

        expect(service.getVendorInfo(999), isNull);
      });
    });

    group('getAllVendors', () {
      test('returns empty map when not loaded', () {
        expect(service.getAllVendors(), isEmpty);
      });

      test('returns all vendors after loading', () async {
        final mockClient = MockClient(
            (_) async => http.Response(jsonEncode(_sampleVendorJson), 200));
        await http.runWithClient(
          () => service.loadGVL(gvlVersion: '3'),
          () => mockClient,
        );

        final all = service.getAllVendors();
        expect(all, hasLength(2));
        expect(all[1]!.name, 'Vendor One');
        expect(all[2]!.name, 'Vendor Two');
      });
    });

    group('clearGVL', () {
      test('clears cache from SharedPreferences', () async {
        final body = jsonEncode(_sampleVendorJson);
        SharedPreferences.setMockInitialValues({
          'gvl_data': body,
          'gvl_version': '3',
          'gvl_timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        GVLService.resetInstance();
        service = GVLService.instance;
        await service.loadGVL();

        await service.clearGVL();

        expect(service.isGVLLoaded(), isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('gvl_data'), isNull);
        expect(prefs.getString('gvl_version'), isNull);
        expect(prefs.getInt('gvl_timestamp'), isNull);
      });
    });

    group('createVendorConsentsWithNames', () {
      test('returns empty map when GVL not loaded', () {
        final result =
            service.createVendorConsentsWithNames({1: true, 2: false});
        expect(result, isEmpty);
      });

      test('creates fallback VendorInfo for unknown vendors', () async {
        final mockClient = MockClient(
            (_) async => http.Response(jsonEncode(_sampleVendorJson), 200));
        await http.runWithClient(
          () => service.loadGVL(gvlVersion: '3'),
          () => mockClient,
        );

        final result = service.createVendorConsentsWithNames({
          1: true, // Known vendor
          999: false, // Unknown vendor
        });

        expect(result[999]!.name, 'Vendor 999');
        expect(result[999]!.consented, isFalse);
        expect(result[1]!.name, 'Vendor One');
      });
    });

    group('VendorInfo equality', () {
      test('two identical VendorInfo are equal', () {
        const v1 = VendorInfo(
          id: 1,
          name: 'Test',
          consented: true,
          purposes: [1, 2],
          legitimateInterestPurposes: [3],
          specialFeatures: [4],
          specialPurposes: [5],
          cookieMaxAgeSeconds: 100,
          usesCookies: true,
          usesNonCookieAccess: false,
          policyUrl: 'https://example.com',
        );
        const v2 = VendorInfo(
          id: 1,
          name: 'Test',
          consented: true,
          purposes: [1, 2],
          legitimateInterestPurposes: [3],
          specialFeatures: [4],
          specialPurposes: [5],
          cookieMaxAgeSeconds: 100,
          usesCookies: true,
          usesNonCookieAccess: false,
          policyUrl: 'https://example.com',
        );
        expect(v1, equals(v2));
      });
    });
  });
}
