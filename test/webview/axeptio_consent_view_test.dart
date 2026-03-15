import 'dart:convert';

import 'package:axeptio_sdk/src/webview/axeptio_consent_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    WebViewPlatform.instance = _MockWebViewPlatform();
  });

  final testUri = Uri.parse('https://static.axept.io/test.html');

  group('AxeptioConsentView widget', () {
    testWidgets('renders Scaffold with WebViewWidget', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          consentUrl: testUri,
          onJsEvent: (_, __) {},
          onClose: () {},
        ),
      ));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(WebViewWidget), findsOneWidget);
    });

    testWidgets('accepts attDenied and storedTcString parameters',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          consentUrl: testUri,
          onJsEvent: (_, __) {},
          onClose: () {},
          attDenied: true,
          storedTcString: 'CPXxRfAP',
        ),
      ));
      expect(find.byType(AxeptioConsentView), findsOneWidget);
    });

    testWidgets('has correct default values', (tester) async {
      AxeptioConsentView? w;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          w = AxeptioConsentView(
            consentUrl: testUri,
            onJsEvent: (_, __) {},
            onClose: () {},
          );
          return w!;
        }),
      ));
      expect(w!.attDenied, isFalse);
      expect(w!.storedTcString, isNull);
    });
  });

  group('AxeptioConsentViewState JS message handling', () {
    late GlobalKey<AxeptioConsentViewState> stateKey;
    late List<String> jsEvents;
    late int closeCount;

    setUp(() {
      stateKey = GlobalKey<AxeptioConsentViewState>();
      jsEvents = [];
      closeCount = 0;
    });

    Future<void> buildWidget(WidgetTester tester,
        {bool attDenied = false, String? storedTcString}) async {
      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          key: stateKey,
          consentUrl: testUri,
          onJsEvent: (name, _) => jsEvents.add(name),
          onClose: () => closeCount++,
          attDenied: attDenied,
          storedTcString: storedTcString,
        ),
      ));
    }

    testWidgets('simulatePageFinished runs without error', (tester) async {
      await buildWidget(tester);
      await expectLater(
          stateKey.currentState!.simulatePageFinished(), completes);
    });

    testWidgets('simulatePageFinished with attDenied', (tester) async {
      await buildWidget(tester, attDenied: true);
      await expectLater(
          stateKey.currentState!.simulatePageFinished(), completes);
    });

    testWidgets('simulatePageFinished with storedTcString', (tester) async {
      await buildWidget(tester, storedTcString: 'CPXx');
      await expectLater(
          stateKey.currentState!.simulatePageFinished(), completes);
    });

    testWidgets('unknown event fires onJsEvent callback', (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.simulateJsMessage(
          jsonEncode({'name': 'some:event', 'payload': null}));
      expect(jsEvents, contains('some:event'));
    });

    testWidgets('cookies:close fires onJsEvent and onClose', (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.simulateJsMessage(
          jsonEncode({'name': 'cookies:close', 'payload': null}));
      expect(jsEvents, contains('cookies:close'));
      expect(closeCount, 1);
    });

    testWidgets('app:cookies:ready with subscription==false calls onClose',
        (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.simulateJsMessage(jsonEncode({
        'name': 'app:cookies:ready',
        'payload': jsonEncode({'subscription': false, 'showCmp': true})
      }));
      expect(closeCount, 1);
    });

    testWidgets('app:cookies:ready with showCmp==false calls onClose',
        (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.simulateJsMessage(jsonEncode({
        'name': 'app:cookies:ready',
        'payload': jsonEncode({'subscription': null, 'showCmp': false})
      }));
      expect(closeCount, 1);
    });

    testWidgets('app:cookies:ready with showCmp==true does NOT close',
        (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.simulateJsMessage(jsonEncode({
        'name': 'app:cookies:ready',
        'payload': jsonEncode({'subscription': null, 'showCmp': true})
      }));
      expect(closeCount, 0);
    });

    testWidgets(
        'app:cookies:ready with showConsentManager==true bypasses showCmp check',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          key: stateKey,
          consentUrl: testUri,
          onJsEvent: (name, _) => jsEvents.add(name),
          onClose: () => closeCount++,
          showConsentManager: true,
        ),
      ));
      stateKey.currentState!.simulateJsMessage(jsonEncode({
        'name': 'app:cookies:ready',
        'payload': jsonEncode({'subscription': null, 'showCmp': false})
      }));
      // Should NOT close — showConsentManager forces the CMP to show
      expect(closeCount, 0);
    });

    testWidgets('app:cookies:ready with null payload calls onClose',
        (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.simulateJsMessage(
          jsonEncode({'name': 'app:cookies:ready', 'payload': null}));
      expect(closeCount, 1);
    });

    testWidgets('payload as Map (not string) is handled', (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.simulateJsMessage(jsonEncode({
        'name': 'some:event',
        'payload': {'key': 'value'}
      }));
      expect(jsEvents, contains('some:event'));
    });

    testWidgets('message with null name is ignored', (tester) async {
      await buildWidget(tester);
      stateKey.currentState!
          .simulateJsMessage(jsonEncode({'name': null, 'payload': null}));
      expect(jsEvents, isEmpty);
      expect(closeCount, 0);
    });

    testWidgets('invalid JSON is silently ignored', (tester) async {
      await buildWidget(tester);
      expect(() => stateKey.currentState!.simulateJsMessage('not valid json'),
          returnsNormally);
      expect(jsEvents, isEmpty);
    });
  });
}

// Minimal mock WebView platform
class _MockWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
      PlatformWebViewControllerCreationParams params) {
    return _MockWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
      PlatformWebViewWidgetCreationParams params) {
    return _MockWebViewWidget(params);
  }

  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
      PlatformWebViewCookieManagerCreationParams params) {
    return _MockCookieManager(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
      PlatformNavigationDelegateCreationParams params) {
    return _MockNavigationDelegate(params);
  }
}

class _MockWebViewController extends PlatformWebViewController {
  _MockWebViewController(super.params) : super.implementation();

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
      PlatformNavigationDelegate handler) async {}

  @override
  Future<void> addJavaScriptChannel(
      JavaScriptChannelParams javaScriptChannelParams) async {}

  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {}

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}

  @override
  Future<void> loadFile(String absoluteFilePath) async {}

  @override
  Future<void> loadFlutterAsset(String key) async {}

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
  Future<void> runJavaScript(String javaScript) async {}

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async => '';

  @override
  Future<String?> getTitle() async => null;

  @override
  Future<void> scrollTo(int x, int y) async {}

  @override
  Future<void> scrollBy(int x, int y) async {}

  @override
  Future<Offset> getScrollPosition() async => Offset.zero;

  @override
  Future<void> enableZoom(bool enabled) async {}

  Future<void> setCustomUserAgent(String? userAgent) async {}

  @override
  Future<String?> getUserAgent() async => null;
}

class _MockWebViewWidget extends PlatformWebViewWidget {
  _MockWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _MockCookieManager extends PlatformWebViewCookieManager {
  _MockCookieManager(super.params) : super.implementation();

  @override
  Future<bool> clearCookies() async => true;

  @override
  Future<void> setCookie(WebViewCookie cookie) async {}
}

class _MockNavigationDelegate extends PlatformNavigationDelegate {
  _MockNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnNavigationRequest(
      NavigationRequestCallback onNavigationRequest) async {}

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  Future<void> setOnWebResourceError(
      WebResourceErrorCallback onWebResourceError) async {}

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {}

  @override
  Future<void> setOnHttpAuthRequest(
      HttpAuthRequestCallback onHttpAuthRequest) async {}

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback onHttpError) async {}
}
