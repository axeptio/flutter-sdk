import 'package:axeptio_sdk/src/exceptions/axeptio_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AxeptioException', () {
    test('constructs with message', () {
      const e = AxeptioException('test error');
      expect(e.message, 'test error');
      expect(e.cause, isNull);
    });

    test('constructs with message and cause', () {
      final cause = Exception('root cause');
      final e = AxeptioException('test error', cause: cause);
      expect(e.message, 'test error');
      expect(e.cause, cause);
    });

    test('toString includes class name and message', () {
      const e = AxeptioException('something went wrong');
      expect(e.toString(), 'AxeptioException: something went wrong');
    });

    test('implements Exception', () {
      const e = AxeptioException('test');
      expect(e, isA<Exception>());
    });
  });

  group('AxeptioNotInitializedException', () {
    test('has default message', () {
      const e = AxeptioNotInitializedException();
      expect(e.message, 'SDK not initialized. Call initialize() first.');
    });

    test('accepts custom message', () {
      const e = AxeptioNotInitializedException('custom msg');
      expect(e.message, 'custom msg');
    });

    test('toString uses own prefix', () {
      const e = AxeptioNotInitializedException();
      expect(e.toString(), startsWith('AxeptioNotInitializedException:'));
    });

    test('is an AxeptioException', () {
      const e = AxeptioNotInitializedException();
      expect(e, isA<AxeptioException>());
    });
  });

  group('AxeptioConsentException', () {
    test('constructs with message', () {
      const e = AxeptioConsentException('consent fail');
      expect(e.message, 'consent fail');
    });

    test('supports cause chaining', () {
      final cause = FormatException('bad json');
      final e = AxeptioConsentException('parse error', cause: cause);
      expect(e.cause, cause);
    });

    test('toString uses own prefix', () {
      const e = AxeptioConsentException('test');
      expect(e.toString(), 'AxeptioConsentException: test');
    });

    test('is an AxeptioException', () {
      const e = AxeptioConsentException('test');
      expect(e, isA<AxeptioException>());
    });
  });

  group('AxeptioNetworkException', () {
    test('constructs with message only', () {
      const e = AxeptioNetworkException('network fail');
      expect(e.message, 'network fail');
      expect(e.statusCode, isNull);
    });

    test('constructs with statusCode', () {
      const e = AxeptioNetworkException('not found', statusCode: 404);
      expect(e.statusCode, 404);
    });

    test('toString includes HTTP status when present', () {
      const e = AxeptioNetworkException('error', statusCode: 500);
      expect(e.toString(), 'AxeptioNetworkException: error (HTTP 500)');
    });

    test('toString omits HTTP status when null', () {
      const e = AxeptioNetworkException('error');
      expect(e.toString(), 'AxeptioNetworkException: error');
    });

    test('supports cause chaining', () {
      final cause = Exception('socket');
      final e = AxeptioNetworkException('fail', cause: cause);
      expect(e.cause, cause);
    });

    test('is an AxeptioException', () {
      const e = AxeptioNetworkException('test');
      expect(e, isA<AxeptioException>());
    });
  });

  group('AxeptioWebViewException', () {
    test('constructs with message', () {
      const e = AxeptioWebViewException('js fail');
      expect(e.message, 'js fail');
    });

    test('toString uses own prefix', () {
      const e = AxeptioWebViewException('test');
      expect(e.toString(), 'AxeptioWebViewException: test');
    });

    test('supports cause chaining', () {
      final cause = Exception('js context not ready');
      final e = AxeptioWebViewException('fail', cause: cause);
      expect(e.cause, cause);
    });

    test('is an AxeptioException', () {
      const e = AxeptioWebViewException('test');
      expect(e, isA<AxeptioException>());
    });
  });

  group('AxeptioStorageException', () {
    test('constructs with message', () {
      const e = AxeptioStorageException('storage fail');
      expect(e.message, 'storage fail');
    });

    test('toString uses own prefix', () {
      const e = AxeptioStorageException('test');
      expect(e.toString(), 'AxeptioStorageException: test');
    });

    test('supports cause chaining', () {
      final cause = Exception('prefs error');
      final e = AxeptioStorageException('fail', cause: cause);
      expect(e.cause, cause);
    });

    test('is an AxeptioException', () {
      const e = AxeptioStorageException('test');
      expect(e, isA<AxeptioException>());
    });
  });
}
