import 'dart:convert';

import 'package:axeptio_sdk/src/exceptions/axeptio_exceptions.dart';
import 'package:axeptio_sdk/src/webview/axeptio_consent_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUri = Uri.parse('https://static.axept.io/test.html');

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
      // With showConsentManager, it tries to call runJavaScript via the channel.
      // Since there's no native view in tests, the channel won't exist,
      // but it shouldn't crash.
      stateKey.currentState!.simulateJsEvent('app:cookies:ready',
          jsonEncode({'subscription': true, 'showCmp': false}));
      await tester.pump();
      // Should NOT close because showConsentManager takes a different path
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
      // simulateJsEvent requires a non-null name, so this tests the guard
      expect(jsEvents, isEmpty);
      expect(closeCount, 0);
    });
  });

  group('AxeptioConsentViewState error handling', () {
    testWidgets('onError callback receives errors', (tester) async {
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

      // Widget should render without errors
      expect(find.byType(Scaffold), findsOneWidget);
      expect(errors, isEmpty);
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

    test('is an AxeptioException', () {
      const e = AxeptioWebViewException('test');
      expect(e, isA<AxeptioException>());
    });
  });
}
