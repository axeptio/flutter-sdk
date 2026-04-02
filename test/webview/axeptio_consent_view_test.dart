import 'dart:convert';

import 'package:axeptio_sdk/src/exceptions/axeptio_exceptions.dart';
import 'package:axeptio_sdk/src/webview/axeptio_consent_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUri = Uri.parse('https://static.axept.io/test.html');

  setUpAll(() {
    // Provide a minimal WebView mock so Android code path doesn't crash
    WebViewPlatform.instance = _CapturingWebViewPlatform();
  });

  group('AxeptioConsentView widget', () {
    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          consentUrl: testUri,
          onJsEvent: (_, __) {},
          onClose: () {},
        ),
      ));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('accepts attDenied and storedTcString parameters',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          consentUrl: testUri,
          attDenied: true,
          storedTcString: 'CPXx',
          onJsEvent: (_, __) {},
          onClose: () {},
        ),
      ));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has correct default values', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          consentUrl: testUri,
          onJsEvent: (_, __) {},
          onClose: () {},
        ),
      ));

      final widget =
          tester.widget<AxeptioConsentView>(find.byType(AxeptioConsentView));
      expect(widget.attDenied, false);
      expect(widget.storedTcString, isNull);
      expect(widget.showConsentManager, false);
      expect(widget.onError, isNull);
    });

    testWidgets('accepts onError parameter', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          consentUrl: testUri,
          onJsEvent: (_, __) {},
          onClose: () {},
          onError: (_) {},
        ),
      ));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('unsupported platform calls onError and onClose',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      final errors = <AxeptioException>[];
      int closeCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          consentUrl: testUri,
          onJsEvent: (_, __) {},
          onClose: () => closeCount++,
          onError: (e) => errors.add(e),
        ),
      ));
      await tester.pump(); // process post-frame callback

      expect(errors, hasLength(1));
      expect(errors.first, isA<AxeptioWebViewException>());
      expect(errors.first.message, contains('linux'));
      expect(closeCount, 1);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('unsupported platform shows fallback text and calls onClose',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      int closeCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          consentUrl: testUri,
          onJsEvent: (_, __) {},
          onClose: () => closeCount++,
          onError: (_) {},
        ),
      ));
      await tester.pump();

      expect(closeCount, 1);
      expect(find.text('Consent webview not available'), findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('AxeptioConsentViewState event handling', () {
    late GlobalKey<AxeptioConsentViewState> stateKey;
    late List<String> jsEvents;
    late int closeCount;

    Future<void> buildWidget(WidgetTester tester,
        {bool attDenied = false,
        String? storedTcString,
        bool showConsentManager = false}) async {
      stateKey = GlobalKey<AxeptioConsentViewState>();
      jsEvents = [];
      closeCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          key: stateKey,
          consentUrl: testUri,
          onJsEvent: (name, _) => jsEvents.add(name),
          onClose: () => closeCount++,
          attDenied: attDenied,
          storedTcString: storedTcString,
          showConsentManager: showConsentManager,
        ),
      ));
    }

    testWidgets('unknown event fires onJsEvent callback', (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.simulateJsEvent('some:event', null);
      expect(jsEvents, contains('some:event'));
    });

    testWidgets('cookies:close fires onJsEvent and onClose', (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.simulateJsEvent('cookies:close', null);
      expect(jsEvents, contains('cookies:close'));
      expect(closeCount, 1);
    });

    testWidgets('app:cookies:ready with subscription==false calls onClose',
        (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.simulateJsEvent('app:cookies:ready',
          jsonEncode({'subscription': false, 'showCmp': true}));
      await tester.pump();
      expect(closeCount, 1);
    });

    testWidgets('app:cookies:ready with showCmp==false calls onClose',
        (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.simulateJsEvent('app:cookies:ready',
          jsonEncode({'subscription': true, 'showCmp': false}));
      await tester.pump();
      expect(closeCount, 1);
    });

    testWidgets('app:cookies:ready with showCmp==true does NOT close',
        (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.simulateJsEvent('app:cookies:ready',
          jsonEncode({'subscription': true, 'showCmp': true}));
      await tester.pump();
      expect(closeCount, 0);
    });

    testWidgets(
        'app:cookies:ready with showConsentManager==true bypasses showCmp check',
        (tester) async {
      await buildWidget(tester, showConsentManager: true);
      stateKey.currentState!.simulateJsEvent('app:cookies:ready',
          jsonEncode({'subscription': true, 'showCmp': false}));
      await tester.pump();
      expect(closeCount, 0);
    });

    testWidgets('app:cookies:ready with null payload calls onClose',
        (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.simulateJsEvent('app:cookies:ready', null);
      await tester.pump();
      expect(closeCount, 1);
    });

    testWidgets('payload as Map is handled', (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.simulateJsEvent(
          'app:cookies:ready', {'subscription': false, 'showCmp': true});
      await tester.pump();
      expect(closeCount, 1);
    });

    testWidgets('payload as JSON string is decoded', (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.simulateJsEvent(
          'app:cookies:ready', jsonEncode({'subscription': false}));
      await tester.pump();
      expect(closeCount, 1);
    });

    testWidgets('null event name is ignored', (tester) async {
      await buildWidget(tester);
      stateKey.currentState!.handleNativeCall(
        const MethodCall('onJsEvent', {'name': null, 'payload': null}),
      );
      expect(jsEvents, isEmpty);
      expect(closeCount, 0);
    });
  });

  group('AxeptioConsentViewState error handling', () {
    testWidgets('onError callback receives native errors', (tester) async {
      final errors = <AxeptioException>[];
      final stateKey = GlobalKey<AxeptioConsentViewState>();
      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          key: stateKey,
          consentUrl: Uri.parse('https://static.axept.io/test.html'),
          onJsEvent: (_, __) {},
          onClose: () {},
          onError: (e) => errors.add(e),
        ),
      ));
      // Clear any platform-related errors from build
      errors.clear();
      await stateKey.currentState!.handleNativeCall(
        const MethodCall('onError', {'type': 'navigation', 'message': 'fail'}),
      );
      expect(errors, hasLength(1));
      expect(errors.first, isA<AxeptioWebViewException>());
    });
  });

  group('AxeptioConsentViewState handleNativeCall', () {
    late GlobalKey<AxeptioConsentViewState> stateKey;
    late List<String> jsEvents;
    late int closeCount;
    late List<AxeptioException> errors;

    Future<void> buildWidget(WidgetTester tester) async {
      stateKey = GlobalKey<AxeptioConsentViewState>();
      jsEvents = [];
      closeCount = 0;
      errors = [];

      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          key: stateKey,
          consentUrl: Uri.parse('https://static.axept.io/test.html'),
          onJsEvent: (name, _) => jsEvents.add(name),
          onClose: () => closeCount++,
          onError: (e) => errors.add(e),
        ),
      ));
      // Clear any platform-related errors from build
      errors.clear();
    }

    testWidgets('onJsEvent method call dispatches event', (tester) async {
      await buildWidget(tester);
      await stateKey.currentState!.handleNativeCall(
        const MethodCall(
            'onJsEvent', {'name': 'cookies:close', 'payload': null}),
      );
      expect(jsEvents, contains('cookies:close'));
      expect(closeCount, 1);
    });

    testWidgets('onJsEvent with null name is ignored', (tester) async {
      await buildWidget(tester);
      await stateKey.currentState!.handleNativeCall(
        const MethodCall('onJsEvent', {'name': null, 'payload': null}),
      );
      expect(jsEvents, isEmpty);
      expect(closeCount, 0);
    });

    testWidgets('onError method call dispatches error', (tester) async {
      await buildWidget(tester);
      await stateKey.currentState!.handleNativeCall(
        const MethodCall(
            'onError', {'type': 'navigation', 'message': 'timeout'}),
      );
      expect(errors, hasLength(1));
      expect(errors.first, isA<AxeptioWebViewException>());
      expect(errors.first.message, contains('timeout'));
    });

    testWidgets('onError with missing message uses default', (tester) async {
      await buildWidget(tester);
      await stateKey.currentState!.handleNativeCall(
        const MethodCall('onError', {'type': 'navigation'}),
      );
      expect(errors, hasLength(1));
      expect(errors.first.message, contains('Unknown error'));
    });

    testWidgets('unknown method call is ignored', (tester) async {
      await buildWidget(tester);
      await stateKey.currentState!.handleNativeCall(
        const MethodCall('unknownMethod', null),
      );
      expect(jsEvents, isEmpty);
      expect(closeCount, 0);
      expect(errors, isEmpty);
    });

    testWidgets('onJsEvent with string payload parses JSON', (tester) async {
      await buildWidget(tester);
      await stateKey.currentState!.handleNativeCall(
        MethodCall('onJsEvent', {
          'name': 'app:cookies:ready',
          'payload': jsonEncode({'subscription': false}),
        }),
      );
      await tester.pump();
      expect(closeCount, 1);
    });

    testWidgets('onJsEvent with map payload is handled', (tester) async {
      await buildWidget(tester);
      await stateKey.currentState!.handleNativeCall(
        const MethodCall('onJsEvent', {
          'name': 'app:cookies:ready',
          'payload': {'subscription': false},
        }),
      );
      await tester.pump();
      expect(closeCount, 1);
    });

    testWidgets('onJsEvent with non-Map arguments is ignored', (tester) async {
      await buildWidget(tester);
      await stateKey.currentState!.handleNativeCall(
        const MethodCall('onJsEvent', 'not a map'),
      );
      expect(jsEvents, isEmpty);
    });

    testWidgets('onError with non-Map arguments is ignored', (tester) async {
      await buildWidget(tester);
      await stateKey.currentState!.handleNativeCall(
        const MethodCall('onError', 'not a map'),
      );
      expect(errors, isEmpty);
    });

    testWidgets('onError without type omits type suffix', (tester) async {
      await buildWidget(tester);
      await stateKey.currentState!.handleNativeCall(
        const MethodCall('onError', {'message': 'plain error'}),
      );
      expect(errors, hasLength(1));
      expect(errors.first.message, contains('plain error'));
      expect(errors.first.message, isNot(contains('type=')));
    });
  });

  group('Android WebView navigation delegate callbacks', () {
    late _CapturingNavigationDelegate capturedDelegate;
    late _CapturingWebViewController capturedController;
    late List<AxeptioException> errors;
    late int closeCount;

    Future<void> buildAndroidWidget(
      WidgetTester tester, {
      bool attDenied = false,
      String? storedTcString,
    }) async {
      errors = [];
      closeCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          consentUrl: testUri,
          onJsEvent: (_, __) {},
          onClose: () => closeCount++,
          onError: (e) => errors.add(e),
          attDenied: attDenied,
          storedTcString: storedTcString,
        ),
      ));

      // Retrieve captured mocks from the platform
      final platform = WebViewPlatform.instance! as _CapturingWebViewPlatform;
      capturedDelegate = platform.lastDelegate!;
      capturedController = platform.lastController!;
    }

    testWidgets('onPageStarted resets injection and injects scripts',
        (tester) async {
      await buildAndroidWidget(tester);
      final onPageStarted = capturedDelegate.capturedOnPageStarted!;

      // First call: scripts injected
      capturedController.runJavaScriptCalls.clear();
      onPageStarted('https://example.com');
      await tester.pump();
      // Should have called runJavaScript for localStorage + polyfill
      expect(capturedController.runJavaScriptCalls.length,
          greaterThanOrEqualTo(1));
    });

    testWidgets('onPageFinished injects scripts', (tester) async {
      await buildAndroidWidget(tester);
      final onPageFinished = capturedDelegate.capturedOnPageFinished!;

      capturedController.runJavaScriptCalls.clear();
      onPageFinished('https://example.com');
      await tester.pump();
      expect(capturedController.runJavaScriptCalls.length,
          greaterThanOrEqualTo(1));
    });

    testWidgets('onPageStarted resets _androidInjected for re-navigation',
        (tester) async {
      await buildAndroidWidget(tester);
      final onPageStarted = capturedDelegate.capturedOnPageStarted!;
      final onPageFinished = capturedDelegate.capturedOnPageFinished!;

      // First: complete a full navigation
      onPageStarted('https://example.com');
      await tester.pump();
      onPageFinished('https://example.com');
      await tester.pump();
      final callsAfterFirst = capturedController.runJavaScriptCalls.length;

      // Second navigation: onPageStarted should reset and re-inject
      onPageStarted('https://example.com/page2');
      await tester.pump();
      expect(capturedController.runJavaScriptCalls.length,
          greaterThan(callsAfterFirst));
    });

    testWidgets('onNavigationRequest allows https and about schemes',
        (tester) async {
      await buildAndroidWidget(tester);
      final onNavRequest = capturedDelegate.capturedOnNavigationRequest!;

      final httpsResult = await onNavRequest(const NavigationRequest(
          url: 'https://example.com', isMainFrame: true));
      expect(httpsResult, NavigationDecision.navigate);

      final aboutResult = await onNavRequest(
          const NavigationRequest(url: 'about:blank', isMainFrame: true));
      expect(aboutResult, NavigationDecision.navigate);
    });

    testWidgets('onNavigationRequest blocks non-https/about schemes',
        (tester) async {
      await buildAndroidWidget(tester);
      final onNavRequest = capturedDelegate.capturedOnNavigationRequest!;

      final httpResult = await onNavRequest(const NavigationRequest(
          url: 'http://example.com', isMainFrame: true));
      expect(httpResult, NavigationDecision.prevent);

      final jsResult = await onNavRequest(const NavigationRequest(
          url: 'javascript:void(0)', isMainFrame: true));
      expect(jsResult, NavigationDecision.prevent);
    });

    testWidgets('onWebResourceError for main frame reports error',
        (tester) async {
      await buildAndroidWidget(tester);
      final onWebResourceError = capturedDelegate.capturedOnWebResourceError!;

      onWebResourceError(const WebResourceError(
        errorCode: -2,
        description: 'net::ERR_FAILED',
        isForMainFrame: true,
        errorType: WebResourceErrorType.connect,
      ));
      expect(errors, hasLength(1));
      expect(errors.first, isA<AxeptioNetworkException>());
      expect(errors.first.message, contains('net::ERR_FAILED'));
    });

    testWidgets('onWebResourceError for sub-frame is ignored', (tester) async {
      await buildAndroidWidget(tester);
      final onWebResourceError = capturedDelegate.capturedOnWebResourceError!;

      onWebResourceError(const WebResourceError(
        errorCode: -2,
        description: 'sub-frame error',
        isForMainFrame: false,
        errorType: WebResourceErrorType.connect,
      ));
      expect(errors, isEmpty);
    });

    testWidgets('onHttpError with status >= 400 reports error', (tester) async {
      await buildAndroidWidget(tester);
      final onHttpError = capturedDelegate.capturedOnHttpError!;

      onHttpError(HttpResponseError(
        response: WebResourceResponse(
            uri: Uri.parse('https://example.com'), statusCode: 500),
      ));
      expect(errors, hasLength(1));
      expect(errors.first, isA<AxeptioNetworkException>());
      expect(errors.first.message, contains('500'));
    });

    testWidgets('onHttpError with status < 400 is ignored', (tester) async {
      await buildAndroidWidget(tester);
      final onHttpError = capturedDelegate.capturedOnHttpError!;

      onHttpError(HttpResponseError(
        response: WebResourceResponse(
            uri: Uri.parse('https://example.com'), statusCode: 200),
      ));
      expect(errors, isEmpty);
    });

    testWidgets('localStorage injection includes attDenied and tcString',
        (tester) async {
      await buildAndroidWidget(tester,
          attDenied: true, storedTcString: 'TC123');

      // Trigger page finished to inject scripts
      capturedController.runJavaScriptCalls.clear();
      capturedDelegate.capturedOnPageFinished!('https://example.com');
      await tester.pump();

      // Check that localStorage calls include attDenied and tcString
      final lsCalls = capturedController.runJavaScriptCalls
          .where((s) => s.contains('localStorage'))
          .toList();
      expect(lsCalls, isNotEmpty);
      final lsScript = lsCalls.first;
      expect(lsScript, contains('_ax_app_att_denied'));
      expect(lsScript, contains('_ax_tcstring'));
      expect(lsScript, contains('TC123'));
    });

    testWidgets('polyfill injection failure does not set _androidInjected',
        (tester) async {
      await buildAndroidWidget(tester);

      // Make polyfill injection fail
      capturedController.shouldFailRunJavaScript = true;

      capturedDelegate.capturedOnPageFinished!('https://example.com');
      await tester.pump();
      expect(errors, hasLength(1));
      expect(errors.first.message, contains('Failed to inject polyfill'));

      // Reset failure and try again - should retry since not marked injected
      capturedController.shouldFailRunJavaScript = false;
      errors.clear();
      capturedController.runJavaScriptCalls.clear();
      capturedDelegate.capturedOnPageFinished!('https://example.com');
      await tester.pump();
      expect(capturedController.runJavaScriptCalls, isNotEmpty);
      expect(errors, isEmpty);
    });

    testWidgets(
        'localStorage failure prevents _androidInjected even if polyfill succeeds',
        (tester) async {
      await buildAndroidWidget(tester);

      // Make localStorage injection fail (first runJavaScript call)
      capturedController.failOnLocalStorage = true;

      capturedDelegate.capturedOnPageFinished!('https://example.com');
      await tester.pump();
      // Polyfill should still have been injected
      final polyfillCalls = capturedController.runJavaScriptCalls
          .where((s) => s.contains('axeptioAppSdk'))
          .toList();
      expect(polyfillCalls, isNotEmpty);

      // But _androidInjected should NOT be true, so retry works
      capturedController.failOnLocalStorage = false;
      capturedController.runJavaScriptCalls.clear();
      capturedDelegate.capturedOnPageFinished!('https://example.com');
      await tester.pump();
      // Should have injected again since localStorageOk was false last time
      expect(capturedController.runJavaScriptCalls, isNotEmpty);
    });

    testWidgets('JS message with valid JSON dispatches event', (tester) async {
      final jsEvents = <String>[];
      int evCloseCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          consentUrl: testUri,
          onJsEvent: (name, _) => jsEvents.add(name),
          onClose: () => evCloseCount++,
          onError: (e) => errors.add(e),
        ),
      ));

      final platform = WebViewPlatform.instance! as _CapturingWebViewPlatform;
      final controller = platform.lastController!;
      final jsChannel = controller.capturedJsChannel!;

      jsChannel.onMessageReceived(JavaScriptMessage(
          message: jsonEncode({'name': 'cookies:close', 'payload': null})));
      expect(jsEvents, contains('cookies:close'));
      expect(evCloseCount, 1);
    });

    testWidgets('JS message with invalid JSON is ignored', (tester) async {
      final jsEvents = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          consentUrl: testUri,
          onJsEvent: (name, _) => jsEvents.add(name),
          onClose: () {},
        ),
      ));

      final platform = WebViewPlatform.instance! as _CapturingWebViewPlatform;
      final jsChannel = platform.lastController!.capturedJsChannel!;

      jsChannel.onMessageReceived(const JavaScriptMessage(message: 'not json'));
      expect(jsEvents, isEmpty);
    });

    testWidgets('JS message with null name is ignored', (tester) async {
      final jsEvents = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          consentUrl: testUri,
          onJsEvent: (name, _) => jsEvents.add(name),
          onClose: () {},
        ),
      ));

      final platform = WebViewPlatform.instance! as _CapturingWebViewPlatform;
      final jsChannel = platform.lastController!.capturedJsChannel!;

      jsChannel.onMessageReceived(JavaScriptMessage(
          message: jsonEncode({'name': null, 'payload': null})));
      expect(jsEvents, isEmpty);
    });

    testWidgets('loadRequest is called with consent URL', (tester) async {
      await buildAndroidWidget(tester);
      expect(capturedController.loadedUrl, testUri.toString());
    });
  });

  group('AxeptioConsentView build for different platforms', () {
    testWidgets('Android renders WebViewWidget', (tester) async {
      // default test platform is android
      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          consentUrl: testUri,
          onJsEvent: (_, __) {},
          onClose: () {},
        ),
      ));

      // The mock WebViewWidget renders SizedBox.shrink
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('macOS calls onError and onClose', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      final errors = <AxeptioException>[];
      int closeCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: AxeptioConsentView(
          consentUrl: testUri,
          onJsEvent: (_, __) {},
          onClose: () => closeCount++,
          onError: (e) => errors.add(e),
        ),
      ));
      await tester.pump();

      expect(errors, hasLength(1));
      expect(errors.first.message, contains('macOS'));
      expect(closeCount, 1);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}

// ============================================================================
// Capturing mock infrastructure
// ============================================================================

class _CapturingWebViewPlatform extends WebViewPlatform {
  _CapturingNavigationDelegate? lastDelegate;
  _CapturingWebViewController? lastController;

  @override
  PlatformWebViewController createPlatformWebViewController(
      PlatformWebViewControllerCreationParams params) {
    lastController = _CapturingWebViewController(params);
    return lastController!;
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
    lastDelegate = _CapturingNavigationDelegate(params);
    return lastDelegate!;
  }
}

class _CapturingWebViewController extends PlatformWebViewController {
  _CapturingWebViewController(super.params) : super.implementation();

  final List<String> runJavaScriptCalls = [];
  bool shouldFailRunJavaScript = false;
  bool failOnLocalStorage = false;
  String? loadedUrl;
  JavaScriptChannelParams? capturedJsChannel;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}
  @override
  Future<void> setBackgroundColor(Color color) async {}
  @override
  Future<void> setPlatformNavigationDelegate(
      PlatformNavigationDelegate handler) async {}
  @override
  Future<void> addJavaScriptChannel(
      JavaScriptChannelParams javaScriptChannelParams) async {
    capturedJsChannel = javaScriptChannelParams;
  }

  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {}
  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    loadedUrl = params.uri.toString();
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    if (failOnLocalStorage && javaScript.contains('localStorage')) {
      throw Exception('localStorage not available');
    }
    if (shouldFailRunJavaScript && javaScript.contains('axeptioAppSdk')) {
      throw Exception('JS injection failed');
    }
    runJavaScriptCalls.add(javaScript);
  }

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async => '';
}

class _MockWebViewWidget extends PlatformWebViewWidget {
  _MockWebViewWidget(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _MockCookieManager extends PlatformWebViewCookieManager {
  _MockCookieManager(super.params) : super.implementation();
}

class _CapturingNavigationDelegate extends PlatformNavigationDelegate {
  _CapturingNavigationDelegate(super.params) : super.implementation();

  PageEventCallback? capturedOnPageStarted;
  PageEventCallback? capturedOnPageFinished;
  NavigationRequestCallback? capturedOnNavigationRequest;
  WebResourceErrorCallback? capturedOnWebResourceError;
  HttpResponseErrorCallback? capturedOnHttpError;

  @override
  Future<void> setOnNavigationRequest(
      NavigationRequestCallback onNavigationRequest) async {
    capturedOnNavigationRequest = onNavigationRequest;
  }

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {
    capturedOnPageStarted = onPageStarted;
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    capturedOnPageFinished = onPageFinished;
  }

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}
  @override
  Future<void> setOnWebResourceError(
      WebResourceErrorCallback onWebResourceError) async {
    capturedOnWebResourceError = onWebResourceError;
  }

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {}
  @override
  Future<void> setOnHttpAuthRequest(
      HttpAuthRequestCallback onHttpAuthRequest) async {}
  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback onHttpError) async {
    capturedOnHttpError = onHttpError;
  }
}
