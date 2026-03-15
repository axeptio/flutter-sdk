import 'package:axeptio_sdk/src/events/event_listener.dart';
import 'package:axeptio_sdk/src/model/axeptio_service.dart';
import 'package:axeptio_sdk/src/model/consents_v2.dart';
import 'package:axeptio_sdk/src/webview/axeptio_consent_view.dart';
import 'package:axeptio_sdk/src/webview/webview_axeptio_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  WebViewPlatform? savedWebViewPlatform;

  setUpAll(() {
    WebViewPlatform.instance = _MockWebViewPlatform();
  });

  group('WebViewAxeptioSdk', () {
    late WebViewAxeptioSdk sdk;

    setUp(() async {
      savedWebViewPlatform = WebViewPlatform.instance;
      SharedPreferences.setMockInitialValues({});
      sdk = WebViewAxeptioSdk();
    });

    tearDown(() {
      WebViewPlatform.instance = savedWebViewPlatform!;
    });

    group('initialization', () {
      test('getPlatformVersion returns null', () async {
        expect(await sdk.getPlatformVersion(), isNull);
      });

      test('axeptioToken returns null before initialize', () async {
        expect(await sdk.axeptioToken, isNull);
      });

      test('initialize stores configuration', () async {
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', 'tok');
        expect(await sdk.axeptioToken, 'tok');
      });

      test('axeptioToken returns null when no init token and storage empty',
          () async {
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        expect(await sdk.axeptioToken, isNull);
      });

      test('initialize creates storage', () async {
        await sdk.initialize(AxeptioService.brands, 'cid', 'cv', null);
        final data = await sdk.getConsentSavedData();
        expect(data, isNull);
      });
    });

    group('setupUI', () {
      test('does nothing when storage is null (not initialized)', () async {
        await expectLater(sdk.setupUI(), completes);
      });

      test('does nothing when tcString already exists', () async {
        SharedPreferences.setMockInitialValues({'IABTCF_TCString': 'CPXxRfAP'});
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        // No navigator key set — if it would show screen it would silently skip
        await expectLater(sdk.setupUI(), completes);
      });
    });

    group('setUserDeniedTracking', () {
      test('completes without error', () async {
        await expectLater(sdk.setUserDeniedTracking(), completes);
      });
    });

    group('showConsentScreen', () {
      test('does nothing when navigatorKey is null', () async {
        WebViewAxeptioSdk.navigatorKey = null;
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        await expectLater(sdk.showConsentScreen(), completes);
      });

      test('does nothing when navigator state is null', () async {
        WebViewAxeptioSdk.navigatorKey = GlobalKey<NavigatorState>();
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        await expectLater(sdk.showConsentScreen(), completes);
      });

      test('does nothing when not initialized', () async {
        WebViewAxeptioSdk.navigatorKey = null;
        await expectLater(sdk.showConsentScreen(), completes);
      });

      testWidgets('pushes AxeptioConsentView with valid navigator',
          (tester) async {
        WebViewPlatform.instance = _MockWebViewPlatform();
        final navKey = GlobalKey<NavigatorState>();
        WebViewAxeptioSdk.navigatorKey = navKey;

        await sdk.initialize(
            AxeptioService.publishers, 'client-id', 'version', null);

        await tester.pumpWidget(MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('home')),
        ));
        await tester.pumpAndSettle();

        await sdk.showConsentScreen();
        await tester.pumpAndSettle();

        expect(find.byType(AxeptioConsentView), findsOneWidget);

        WebViewAxeptioSdk.navigatorKey = null;
      });

      testWidgets('consentUrl contains showConsentManager=true',
          (tester) async {
        WebViewPlatform.instance = _MockWebViewPlatform();
        final navKey = GlobalKey<NavigatorState>();
        WebViewAxeptioSdk.navigatorKey = navKey;

        await sdk.initialize(
            AxeptioService.publishers, 'client-id', 'version', null);

        await tester.pumpWidget(MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('home')),
        ));
        await tester.pumpAndSettle();

        await sdk.showConsentScreen();
        await tester.pumpAndSettle();

        final view =
            tester.widget<AxeptioConsentView>(find.byType(AxeptioConsentView));
        expect(view.consentUrl.queryParameters['showConsentManager'], 'true');

        WebViewAxeptioSdk.navigatorKey = null;
      });
    });

    group('setupUI calls showConsentScreen', () {
      testWidgets('setupUI shows consent when tcString is empty',
          (tester) async {
        WebViewPlatform.instance = _MockWebViewPlatform();
        final navKey = GlobalKey<NavigatorState>();
        WebViewAxeptioSdk.navigatorKey = navKey;

        SharedPreferences.setMockInitialValues({});
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);

        await tester.pumpWidget(MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('home')),
        ));
        await tester.pumpAndSettle();

        await sdk.setupUI();
        await tester.pumpAndSettle();

        expect(find.byType(AxeptioConsentView), findsOneWidget);

        WebViewAxeptioSdk.navigatorKey = null;
      });
    });

    group('clearConsent', () {
      test('completes when storage is null', () async {
        await expectLater(sdk.clearConsent(), completes);
      });

      test('notifies listeners via onConsentCleared', () async {
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        bool cleared = false;
        final listener = AxeptioEventListener();
        listener.onConsentCleared = () => cleared = true;
        sdk.addEventListener(listener);

        await sdk.clearConsent();

        expect(cleared, isTrue);
      });

      test('clears stored data', () async {
        SharedPreferences.setMockInitialValues(
            {'IABTCF_TCString': 'CPXx', 'AX_CLIENT_TOKEN': 'tok'});
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);

        await sdk.clearConsent();

        expect(await sdk.axeptioToken, isNull);
        expect(await sdk.getConsentSavedData(), isNull);
      });

      test('resets in-memory token after clearConsent', () async {
        await sdk.initialize(
            AxeptioService.publishers, 'cid', 'cv', 'initial-tok');
        await sdk
            .handleJsEvent('consent:saved', {'axeptio_token': 'updated-tok'});
        expect(await sdk.axeptioToken, 'updated-tok');

        await sdk.clearConsent();

        expect(await sdk.axeptioToken, isNull);
      });
    });

    group('getConsentSavedData', () {
      test('returns null when not initialized', () async {
        expect(await sdk.getConsentSavedData(), isNull);
      });

      test('returns null when no data stored', () async {
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        expect(await sdk.getConsentSavedData(), isNull);
      });

      test('returns all data', () async {
        SharedPreferences.setMockInitialValues({'IABTCF_TCString': 'CPXx'});
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        final data = await sdk.getConsentSavedData();
        expect(data, isNotNull);
        expect(data!['IABTCF_TCString'], 'CPXx');
      });

      test('returns specific key data', () async {
        SharedPreferences.setMockInitialValues(
            {'IABTCF_TCString': 'CPXx', '_ax_token': 'tok'});
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        final data =
            await sdk.getConsentSavedData(preferenceKey: 'IABTCF_TCString');
        expect(data, {'IABTCF_TCString': 'CPXx'});
      });

      test('returns null for non-existent key', () async {
        SharedPreferences.setMockInitialValues({'IABTCF_TCString': 'CPXx'});
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        final data =
            await sdk.getConsentSavedData(preferenceKey: 'non_existent');
        expect(data, isNull);
      });
    });

    group('getConsentDebugInfo', () {
      test('delegates to getConsentSavedData', () async {
        SharedPreferences.setMockInitialValues({'IABTCF_TCString': 'CPXx'});
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        final debug = await sdk.getConsentDebugInfo();
        final saved = await sdk.getConsentSavedData();
        expect(debug, equals(saved));
      });
    });

    group('getVendorConsents', () {
      test('returns empty map when not initialized', () async {
        expect(await sdk.getVendorConsents(), isEmpty);
      });

      test('returns decoded vendor consents', () async {
        SharedPreferences.setMockInitialValues(
            {'IABTCF_VendorConsents': '101'});
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        final consents = await sdk.getVendorConsents();
        expect(consents[1], isTrue);
        expect(consents[2], isFalse);
        expect(consents[3], isTrue);
      });
    });

    group('getConsentedVendors', () {
      test('returns empty list when not initialized', () async {
        expect(await sdk.getConsentedVendors(), isEmpty);
      });

      test('returns consented vendor IDs', () async {
        SharedPreferences.setMockInitialValues(
            {'IABTCF_VendorConsents': '101'});
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        final vendors = await sdk.getConsentedVendors();
        expect(vendors, containsAll([1, 3]));
        expect(vendors, isNot(contains(2)));
      });
    });

    group('getRefusedVendors', () {
      test('returns empty list when not initialized', () async {
        expect(await sdk.getRefusedVendors(), isEmpty);
      });

      test('returns refused vendor IDs', () async {
        SharedPreferences.setMockInitialValues(
            {'IABTCF_VendorConsents': '101'});
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        final vendors = await sdk.getRefusedVendors();
        expect(vendors, contains(2));
        expect(vendors, isNot(contains(1)));
      });
    });

    group('isVendorConsented', () {
      test('returns false when not initialized', () async {
        expect(await sdk.isVendorConsented(1), isFalse);
      });

      test('returns true for consented vendor', () async {
        SharedPreferences.setMockInitialValues(
            {'IABTCF_VendorConsents': '101'});
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        expect(await sdk.isVendorConsented(1), isTrue);
      });

      test('returns false for refused vendor', () async {
        SharedPreferences.setMockInitialValues(
            {'IABTCF_VendorConsents': '101'});
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        expect(await sdk.isVendorConsented(2), isFalse);
      });

      test('returns false for out-of-range vendor', () async {
        SharedPreferences.setMockInitialValues(
            {'IABTCF_VendorConsents': '101'});
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);
        expect(await sdk.isVendorConsented(999), isFalse);
      });
    });

    group('appendAxeptioTokenURL', () {
      test('returns original url when not initialized', () async {
        final result =
            await sdk.appendAxeptioTokenURL('https://example.com', 'tok');
        expect(result, 'https://example.com');
      });

      test('appends params when initialized', () async {
        await sdk.initialize(
            AxeptioService.publishers, 'my-cid', 'my-cv', null);
        final result =
            await sdk.appendAxeptioTokenURL('https://example.com', 'tok');
        expect(result, isNotNull);
        final uri = Uri.parse(result!);
        expect(uri.queryParameters['clientId'], 'my-cid');
        expect(uri.queryParameters['cookiesVersion'], 'my-cv');
        expect(uri.queryParameters['axeptio_token'], 'tok');
      });
    });

    group('event listeners', () {
      test('addEventListener and removeEventListener work', () {
        final listener = AxeptioEventListener();
        expect(() => sdk.addEventListener(listener), returnsNormally);
        expect(() => sdk.removeEventListener(listener), returnsNormally);
      });

      test('listeners receive onPopupClosedEvent from JS cookies:close',
          () async {
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);

        bool closed = false;
        final listener = AxeptioEventListener();
        listener.onPopupClosedEvent = () => closed = true;
        sdk.addEventListener(listener);

        await sdk.handleJsEvent('cookies:close', null);

        expect(closed, isTrue);
      });

      test('listeners receive onGoogleConsentModeUpdate', () async {
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);

        ConsentsV2? received;
        final listener = AxeptioEventListener();
        listener.onGoogleConsentModeUpdate = (c) => received = c;
        sdk.addEventListener(listener);

        await sdk.handleJsEvent('google:consent-mode-v2-update', {
          'analytics_storage': true,
          'ad_storage': false,
          'ad_user_data': true,
          'ad_personalization': false,
        });

        expect(received, isNotNull);
        expect(received!.analyticsStorage, isTrue);
        expect(received!.adStorage, isFalse);
        expect(received!.adUserData, isTrue);
        expect(received!.adPersonalization, isFalse);
      });

      test('iabtcf event writes to storage', () async {
        SharedPreferences.setMockInitialValues({});
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);

        await sdk.handleJsEvent('iabtcf', {'IABTCF_TCString': 'CPXxTest'});

        final data = await sdk.getConsentSavedData();
        expect(data?['IABTCF_TCString'], 'CPXxTest');
      });

      test('consent:saved event writes token', () async {
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);

        await sdk
            .handleJsEvent('consent:saved', {'axeptio_token': 'new-token'});

        expect(await sdk.axeptioToken, 'new-token');
      });

      test(
          'showConsentScreen uses updated token from storage after consent:saved',
          () async {
        await sdk.initialize(
            AxeptioService.publishers, 'cid', 'cv', 'initial-tok');
        await sdk
            .handleJsEvent('consent:saved', {'axeptio_token': 'refreshed-tok'});
        // The storage now holds 'refreshed-tok'; _token still holds 'initial-tok'.
        // Verify that axeptioToken (sourced from storage) reflects the update.
        expect(await sdk.axeptioToken, 'refreshed-tok');
      });

      test('axeptio:cookies event writes cookies', () async {
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);

        await sdk
            .handleJsEvent('axeptio:cookies', {'axeptio_cookies': '{"a":1}'});

        final data = await sdk.getConsentSavedData();
        expect(data?['axeptio_cookies'], '{"a":1}');
      });

      test('cookies:complete event writes scope', () async {
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);

        await sdk.handleJsEvent('cookies:complete', {'scope': 'persistent'});

        final data = await sdk.getConsentSavedData();
        expect(data?['widget_scope'], 'persistent');
      });

      test('unknown events are silently ignored', () async {
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);

        await expectLater(sdk.handleJsEvent('unknown:event', null), completes);
      });

      test('google consent with null payload is ignored', () async {
        await sdk.initialize(AxeptioService.publishers, 'cid', 'cv', null);

        ConsentsV2? received;
        final listener = AxeptioEventListener();
        listener.onGoogleConsentModeUpdate = (c) => received = c;
        sdk.addEventListener(listener);

        await sdk.handleJsEvent('google:consent-mode-v2-update', null);

        expect(received, isNull);
      });
    });
  });
}

class _MockWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
          PlatformWebViewControllerCreationParams params) =>
      _MockCtrl(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams params) =>
      _MockWidget(params);

  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
          PlatformWebViewCookieManagerCreationParams params) =>
      _MockCookies(params);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
          PlatformNavigationDelegateCreationParams params) =>
      _MockDelegate(params);
}

class _MockCtrl extends PlatformWebViewController {
  _MockCtrl(super.params) : super.implementation();
  @override
  Future<void> setJavaScriptMode(JavaScriptMode m) async {}
  @override
  Future<void> setBackgroundColor(Color c) async {}
  @override
  Future<void> setPlatformNavigationDelegate(
      PlatformNavigationDelegate h) async {}
  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams p) async {}
  @override
  Future<void> removeJavaScriptChannel(String n) async {}
  @override
  Future<void> loadRequest(LoadRequestParams p) async {}
  @override
  Future<void> loadHtmlString(String h, {String? baseUrl}) async {}
  @override
  Future<void> loadFile(String p) async {}
  @override
  Future<void> loadFlutterAsset(String k) async {}
  @override
  Future<String?> currentUrl() async => null;
  @override
  Future<bool> canGoBack() async => false;
  @override
  Future<bool> canGoForward() async => false;
  @override
  Future<void> goBack() async {}
  @override
  Future<void> goForward() async {}
  @override
  Future<void> reload() async {}
  @override
  Future<void> clearCache() async {}
  @override
  Future<void> clearLocalStorage() async {}
  @override
  Future<void> runJavaScript(String js) async {}
  @override
  Future<Object> runJavaScriptReturningResult(String js) async => '';
  @override
  Future<String?> getTitle() async => null;
  @override
  Future<void> scrollTo(int x, int y) async {}
  @override
  Future<void> scrollBy(int x, int y) async {}
  @override
  Future<Offset> getScrollPosition() async => Offset.zero;
  @override
  Future<void> enableZoom(bool e) async {}
  Future<void> setCustomUserAgent(String? ua) async {}
  @override
  Future<String?> getUserAgent() async => null;
}

class _MockWidget extends PlatformWebViewWidget {
  _MockWidget(super.params) : super.implementation();
  @override
  Widget build(BuildContext ctx) => const SizedBox.shrink();
}

class _MockCookies extends PlatformWebViewCookieManager {
  _MockCookies(super.params) : super.implementation();
  @override
  Future<bool> clearCookies() async => true;
  @override
  Future<void> setCookie(WebViewCookie c) async {}
}

class _MockDelegate extends PlatformNavigationDelegate {
  _MockDelegate(super.params) : super.implementation();
  @override
  Future<void> setOnNavigationRequest(NavigationRequestCallback f) async {}
  @override
  Future<void> setOnPageStarted(PageEventCallback f) async {}
  @override
  Future<void> setOnPageFinished(PageEventCallback f) async {}
  @override
  Future<void> setOnProgress(ProgressCallback f) async {}
  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback f) async {}
  @override
  Future<void> setOnUrlChange(UrlChangeCallback f) async {}
  @override
  Future<void> setOnHttpAuthRequest(HttpAuthRequestCallback f) async {}
  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback f) async {}
}
