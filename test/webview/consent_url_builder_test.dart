import 'package:axeptio_sdk/src/model/axeptio_service.dart';
import 'package:axeptio_sdk/src/webview/consent_url_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsentUrlBuilder.build', () {
    test('publishers service uses correct base URL', () {
      final uri = ConsentUrlBuilder.build(
        service: AxeptioService.publishers,
        clientId: 'client123',
        cookiesVersion: 'v1',
      );
      expect(uri.host, 'static.axept.io');
      expect(uri.path, '/app-sdk-webview.html');
    });

    test('brands service uses correct base URL', () {
      final uri = ConsentUrlBuilder.build(
        service: AxeptioService.brands,
        clientId: 'client123',
        cookiesVersion: 'v1',
      );
      expect(uri.host, 'static.axept.io');
      expect(uri.path, '/app-sdk-webview-for-brands.html');
    });

    test('includes required query params', () {
      final uri = ConsentUrlBuilder.build(
        service: AxeptioService.publishers,
        clientId: 'my-client',
        cookiesVersion: 'my-version',
      );
      expect(uri.queryParameters['clientId'], 'my-client');
      expect(uri.queryParameters['cookiesVersion'], 'my-version');
    });

    test('includes token when provided', () {
      final uri = ConsentUrlBuilder.build(
        service: AxeptioService.publishers,
        clientId: 'c',
        cookiesVersion: 'v',
        token: 'tok-abc',
      );
      expect(uri.queryParameters['axeptio_token'], 'tok-abc');
    });

    test('omits token param when not provided', () {
      final uri = ConsentUrlBuilder.build(
        service: AxeptioService.publishers,
        clientId: 'c',
        cookiesVersion: 'v',
      );
      expect(uri.queryParameters.containsKey('axeptio_token'), isFalse);
    });

    test('includes showConsentManager when true', () {
      final uri = ConsentUrlBuilder.build(
        service: AxeptioService.publishers,
        clientId: 'c',
        cookiesVersion: 'v',
        showConsentManager: true,
      );
      expect(uri.queryParameters['showConsentManager'], 'true');
    });

    test('omits showConsentManager when false', () {
      final uri = ConsentUrlBuilder.build(
        service: AxeptioService.publishers,
        clientId: 'c',
        cookiesVersion: 'v',
        showConsentManager: false,
      );
      expect(uri.queryParameters.containsKey('showConsentManager'), isFalse);
    });

    test('all params combined', () {
      final uri = ConsentUrlBuilder.build(
        service: AxeptioService.brands,
        clientId: 'cid',
        cookiesVersion: 'cv',
        token: 'tok',
        showConsentManager: true,
      );
      expect(uri.queryParameters['clientId'], 'cid');
      expect(uri.queryParameters['cookiesVersion'], 'cv');
      expect(uri.queryParameters['axeptio_token'], 'tok');
      expect(uri.queryParameters['showConsentManager'], 'true');
    });
  });

  group('ConsentUrlBuilder.appendToken', () {
    test('appends clientId and cookiesVersion to URL', () {
      final uri = ConsentUrlBuilder.appendToken(
          'https://example.com', 'cid', 'cv', null);
      expect(uri.queryParameters['clientId'], 'cid');
      expect(uri.queryParameters['cookiesVersion'], 'cv');
    });

    test('appends token when provided', () {
      final uri = ConsentUrlBuilder.appendToken(
          'https://example.com', 'cid', 'cv', 'tok');
      expect(uri.queryParameters['axeptio_token'], 'tok');
    });

    test('omits token param when null', () {
      final uri = ConsentUrlBuilder.appendToken(
          'https://example.com', 'cid', 'cv', null);
      expect(uri.queryParameters.containsKey('axeptio_token'), isFalse);
    });

    test('removes existing axeptio_token from url when token is null', () {
      final uri = ConsentUrlBuilder.appendToken(
          'https://example.com?axeptio_token=old', 'cid', 'cv', null);
      expect(uri.queryParameters.containsKey('axeptio_token'), isFalse);
    });

    test('preserves existing query params', () {
      final uri = ConsentUrlBuilder.appendToken(
          'https://example.com?foo=bar', 'cid', 'cv', 'tok');
      expect(uri.queryParameters['foo'], 'bar');
      expect(uri.queryParameters['clientId'], 'cid');
    });

    test('preserves host and path', () {
      final uri = ConsentUrlBuilder.appendToken(
          'https://mysite.com/path/page', 'cid', 'cv', null);
      expect(uri.host, 'mysite.com');
      expect(uri.path, '/path/page');
    });

    test('overrides existing clientId if present', () {
      final uri = ConsentUrlBuilder.appendToken(
          'https://example.com?clientId=old', 'new-cid', 'cv', null);
      expect(uri.queryParameters['clientId'], 'new-cid');
    });
  });
}
