import 'dart:convert';

import 'package:axeptio_sdk/src/webview/js_bridge_message_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late JsBridgeMessageParser parser;

  setUp(() {
    parser = JsBridgeMessageParser();
  });

  group('JsBridgeMessageParser', () {
    group('parse', () {
      test('parses message with name and no payload', () {
        final raw = jsonEncode({'name': 'cookies:close'});
        final result = parser.parse(raw);
        expect(result, isNotNull);
        expect(result!.name, 'cookies:close');
        expect(result.payload, isNull);
      });

      test('parses message with name and Map payload', () {
        final raw = jsonEncode({
          'name': 'iabtcf',
          'payload': {
            'IABTCF_TCString': 'CPXxRfAPXxRfA',
            'IABTCF_gdprApplies': 1,
          },
        });
        final result = parser.parse(raw);
        expect(result, isNotNull);
        expect(result!.name, 'iabtcf');
        expect(result.payload, isNotNull);
        expect(result.payload!['IABTCF_TCString'], 'CPXxRfAPXxRfA');
        expect(result.payload!['IABTCF_gdprApplies'], 1);
      });

      test('parses message with name and String payload (double-encoded)', () {
        final innerPayload = jsonEncode({
          'axeptio_token': 'abc123',
          'axeptio_cookies': '{"key":"val"}',
        });
        final raw = jsonEncode({
          'name': 'consent:saved',
          'payload': innerPayload,
        });
        final result = parser.parse(raw);
        expect(result, isNotNull);
        expect(result!.name, 'consent:saved');
        expect(result.payload, isNotNull);
        expect(result.payload!['axeptio_token'], 'abc123');
      });

      test('parses app:cookies:ready with subscription payload', () {
        final raw = jsonEncode({
          'name': 'app:cookies:ready',
          'payload': {'subscription': true, 'showCmp': true},
        });
        final result = parser.parse(raw);
        expect(result, isNotNull);
        expect(result!.name, 'app:cookies:ready');
        expect(result.payload!['subscription'], true);
        expect(result.payload!['showCmp'], true);
      });

      test('parses google consent mode update', () {
        final raw = jsonEncode({
          'name': 'google:consent-mode-v2-update',
          'payload': {
            'analytics_storage': true,
            'ad_storage': false,
            'ad_user_data': true,
            'ad_personalization': false,
          },
        });
        final result = parser.parse(raw);
        expect(result, isNotNull);
        expect(result!.name, 'google:consent-mode-v2-update');
        expect(result.payload!['analytics_storage'], true);
        expect(result.payload!['ad_storage'], false);
      });

      test('parses axeptio:cookies event', () {
        final raw = jsonEncode({
          'name': 'axeptio:cookies',
          'payload': {'cookies': 'cookie_data'},
        });
        final result = parser.parse(raw);
        expect(result, isNotNull);
        expect(result!.name, 'axeptio:cookies');
      });

      test('parses cookies:complete event', () {
        final raw = jsonEncode({
          'name': 'cookies:complete',
          'payload': {'widget_scope': 'scope_value'},
        });
        final result = parser.parse(raw);
        expect(result, isNotNull);
        expect(result!.name, 'cookies:complete');
      });

      test('returns null for missing name field', () {
        final raw = jsonEncode({
          'payload': {'data': 'value'}
        });
        final result = parser.parse(raw);
        expect(result, isNull);
      });

      test('returns null for null name', () {
        final raw = jsonEncode({'name': null, 'payload': {}});
        final result = parser.parse(raw);
        expect(result, isNull);
      });

      test('returns null for invalid JSON', () {
        final result = parser.parse('not valid json {{{');
        expect(result, isNull);
      });

      test('returns null for empty string', () {
        final result = parser.parse('');
        expect(result, isNull);
      });

      test('handles null payload gracefully', () {
        final raw = jsonEncode({'name': 'cookies:close', 'payload': null});
        final result = parser.parse(raw);
        expect(result, isNotNull);
        expect(result!.name, 'cookies:close');
        expect(result.payload, isNull);
      });

      test('handles empty string payload', () {
        final raw = jsonEncode({'name': 'test', 'payload': ''});
        final result = parser.parse(raw);
        expect(result, isNotNull);
        expect(result!.payload, isNull);
      });

      test('handles invalid JSON string payload gracefully', () {
        final raw = jsonEncode({'name': 'test', 'payload': 'not-json'});
        final result = parser.parse(raw);
        expect(result, isNotNull);
        expect(result!.name, 'test');
        expect(result.payload, isNull);
      });

      test('handles payload as list (unexpected type)', () {
        final raw = jsonEncode({
          'name': 'test',
          'payload': [1, 2, 3],
        });
        final result = parser.parse(raw);
        expect(result, isNotNull);
        expect(result!.name, 'test');
        expect(result.payload, isNull);
      });

      test('handles payload as number (unexpected type)', () {
        final raw = jsonEncode({'name': 'test', 'payload': 42});
        final result = parser.parse(raw);
        expect(result, isNotNull);
        expect(result!.name, 'test');
        expect(result.payload, isNull);
      });

      test('handles unknown event types', () {
        final raw = jsonEncode({
          'name': 'unknown:event',
          'payload': {'key': 'value'},
        });
        final result = parser.parse(raw);
        expect(result, isNotNull);
        expect(result!.name, 'unknown:event');
        expect(result.payload!['key'], 'value');
      });

      test('handles nested payload structures', () {
        final raw = jsonEncode({
          'name': 'iabtcf',
          'payload': {
            'IABTCF_TCString': 'CPXxRfAPXxRfA',
            'nested': {
              'deep': {'value': true},
            },
          },
        });
        final result = parser.parse(raw);
        expect(result, isNotNull);
        expect(
          (result!.payload!['nested'] as Map)['deep']['value'],
          true,
        );
      });
    });
  });
}
