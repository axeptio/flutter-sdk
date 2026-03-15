import 'package:axeptio_sdk/src/webview/tcf_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TcfStorage', () {
    late TcfStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = TcfStorage(prefs);
    });

    group('create()', () {
      test('creates instance via shared preferences', () async {
        SharedPreferences.setMockInitialValues({});
        final s = await TcfStorage.create();
        expect(s, isA<TcfStorage>());
      });
    });

    group('tcString getter', () {
      test('returns null when not set', () {
        expect(storage.tcString, isNull);
      });

      test('returns stored value', () async {
        SharedPreferences.setMockInitialValues({'IABTCF_TCString': 'CPXxRfAP'});
        final prefs = await SharedPreferences.getInstance();
        final s = TcfStorage(prefs);
        expect(s.tcString, 'CPXxRfAP');
      });
    });

    group('axeptioToken getter', () {
      test('returns null when not set', () {
        expect(storage.axeptioToken, isNull);
      });

      test('returns stored token from AX_CLIENT_TOKEN key', () async {
        SharedPreferences.setMockInitialValues({'AX_CLIENT_TOKEN': 'tok-123'});
        final prefs = await SharedPreferences.getInstance();
        final s = TcfStorage(prefs);
        expect(s.axeptioToken, 'tok-123');
      });

      test('falls back to legacy _ax_token key for migration', () async {
        SharedPreferences.setMockInitialValues({'_ax_token': 'legacy-tok'});
        final prefs = await SharedPreferences.getInstance();
        final s = TcfStorage(prefs);
        expect(s.axeptioToken, 'legacy-tok');
      });
    });

    group('writeIabTcfFields', () {
      test('writes string fields', () async {
        await storage.writeIabTcfFields({'IABTCF_TCString': 'CPXxRfAP'});
        expect(storage.tcString, 'CPXxRfAP');
      });

      test('writes bool fields', () async {
        await storage.writeIabTcfFields({'IABTCF_gdprApplies': true});
        final all = storage.getAllData();
        expect(all['IABTCF_gdprApplies'], true);
      });

      test('writes int fields', () async {
        await storage.writeIabTcfFields({'IABTCF_CmpSdkID': 42});
        final all = storage.getAllData();
        expect(all['IABTCF_CmpSdkID'], 42);
      });

      test('skips null values', () async {
        await storage.writeIabTcfFields({'IABTCF_TCString': null});
        expect(storage.tcString, isNull);
      });

      test('does nothing when payload is null', () async {
        await expectLater(storage.writeIabTcfFields(null), completes);
      });

      test('writes multiple fields', () async {
        await storage.writeIabTcfFields({
          'IABTCF_TCString': 'CPXx',
          'IABTCF_gdprApplies': true,
          'IABTCF_CmpSdkID': 1,
        });
        final all = storage.getAllData();
        expect(all['IABTCF_TCString'], 'CPXx');
        expect(all['IABTCF_gdprApplies'], true);
        expect(all['IABTCF_CmpSdkID'], 1);
      });
    });

    group('writeConsentSaved', () {
      test('stores axeptio_token under AX_CLIENT_TOKEN key', () async {
        await storage.writeConsentSaved({'axeptio_token': 'my-token'});
        expect(storage.axeptioToken, 'my-token');
      });

      test('stores axeptio_cookies', () async {
        await storage.writeConsentSaved({'axeptio_cookies': '{"a":true}'});
        final all = storage.getAllData();
        expect(all['axeptio_cookies'], '{"a":true}');
      });

      test('stores axeptio_all_vendors', () async {
        await storage.writeConsentSaved({'axeptio_all_vendors': 'v1,v2'});
        final all = storage.getAllData();
        expect(all['axeptio_all_vendors'], 'v1,v2');
      });

      test('stores axeptio_authorized_vendors', () async {
        await storage.writeConsentSaved({'axeptio_authorized_vendors': 'v1'});
        final all = storage.getAllData();
        expect(all['axeptio_authorized_vendors'], 'v1');
      });

      test('does nothing when null', () async {
        await expectLater(storage.writeConsentSaved(null), completes);
      });

      test('skips missing keys gracefully', () async {
        await storage.writeConsentSaved({'axeptio_token': 'tok'});
        final all = storage.getAllData();
        expect(all.containsKey('axeptio_cookies'), isFalse);
      });
    });

    group('writeCookies', () {
      test('writes cookie key-value pairs', () async {
        await storage.writeCookies({'axeptio_cookies': 'data'});
        final all = storage.getAllData();
        expect(all['axeptio_cookies'], 'data');
      });

      test('does nothing when null', () async {
        await expectLater(storage.writeCookies(null), completes);
      });
    });

    group('writeScope', () {
      test('stores widget_scope', () async {
        await storage.writeScope({'scope': 'persistent'});
        final all = storage.getAllData();
        expect(all['widget_scope'], 'persistent');
      });

      test('does nothing when null', () async {
        await expectLater(storage.writeScope(null), completes);
      });

      test('skips when scope key is absent', () async {
        await storage.writeScope({'other': 'value'});
        final all = storage.getAllData();
        expect(all.containsKey('widget_scope'), isFalse);
      });
    });

    group('clearAll', () {
      test('removes all stored keys', () async {
        await storage.writeIabTcfFields({'IABTCF_TCString': 'CPXx'});
        await storage.writeConsentSaved({'axeptio_token': 'tok'});
        await storage.writeScope({'scope': 'session'});

        await storage.clearAll();

        final all = storage.getAllData();
        expect(all, isEmpty);
        expect(storage.tcString, isNull);
        expect(storage.axeptioToken, isNull);
      });
    });

    group('getAllData', () {
      test('returns empty map when nothing stored', () {
        expect(storage.getAllData(), isEmpty);
      });

      test('returns stored values', () async {
        await storage.writeIabTcfFields({'IABTCF_TCString': 'CPXx'});
        await storage.writeConsentSaved({'axeptio_token': 'tok'});
        final all = storage.getAllData();
        expect(all['IABTCF_TCString'], 'CPXx');
        expect(all['AX_CLIENT_TOKEN'], 'tok');
      });

      test('includes legacy _ax_token when only that key is present', () async {
        SharedPreferences.setMockInitialValues({'_ax_token': 'legacy-tok'});
        final prefs = await SharedPreferences.getInstance();
        final s = TcfStorage(prefs);
        final all = s.getAllData();
        expect(all['_ax_token'], 'legacy-tok');
      });
    });

    group('getVendorConsents', () {
      test('returns empty map when not set', () {
        expect(storage.getVendorConsents(), isEmpty);
      });

      test('decodes bitstring correctly', () async {
        SharedPreferences.setMockInitialValues(
            {'IABTCF_VendorConsents': '101'});
        final prefs = await SharedPreferences.getInstance();
        final s = TcfStorage(prefs);
        final consents = s.getVendorConsents();
        expect(consents[1], isTrue);
        expect(consents[2], isFalse);
        expect(consents[3], isTrue);
      });

      test('all consented', () async {
        SharedPreferences.setMockInitialValues(
            {'IABTCF_VendorConsents': '111'});
        final prefs = await SharedPreferences.getInstance();
        final s = TcfStorage(prefs);
        final consents = s.getVendorConsents();
        expect(consents[1], isTrue);
        expect(consents[2], isTrue);
        expect(consents[3], isTrue);
      });

      test('all refused', () async {
        SharedPreferences.setMockInitialValues(
            {'IABTCF_VendorConsents': '000'});
        final prefs = await SharedPreferences.getInstance();
        final s = TcfStorage(prefs);
        final consents = s.getVendorConsents();
        expect(consents[1], isFalse);
        expect(consents[2], isFalse);
        expect(consents[3], isFalse);
      });
    });
  });
}
