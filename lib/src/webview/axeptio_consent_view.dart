import 'dart:async';
import 'dart:convert';

import 'package:axeptio_sdk/src/exceptions/axeptio_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'js_bridge_message_parser.dart';

/// Duration in days for the Axeptio user cookie consent window.
const int _axUserCookiesDurationDays = 190;

/// Bridges the Axeptio web page's `window.axeptioAppSdk.onEvent()` calls to
/// the Flutter JS channel (`window.axeptioSdk`), which is registered by
/// `addJavaScriptChannel('axeptioSdk')` at document start.
const String _polyfillScript = r'''
window.axeptioAppSdk = {
  onEvent: function(event, payload) {
    if (window.axeptioSdk) {
      window.axeptioSdk.postMessage(JSON.stringify({ name: event, payload: payload }));
    } else if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.axeptioSdk) {
      window.webkit.messageHandlers.axeptioSdk.postMessage(JSON.stringify({ name: event, payload: payload }));
    }
  }
};
''';

class AxeptioConsentView extends StatefulWidget {
  final Uri consentUrl;
  final bool attDenied;
  final String? storedTcString;
  final bool showConsentManager;
  final void Function(String name, Map<String, dynamic>? payload) onJsEvent;
  final void Function() onClose;
  final void Function(AxeptioException error)? onError;

  const AxeptioConsentView({
    super.key,
    required this.consentUrl,
    required this.onJsEvent,
    required this.onClose,
    this.attDenied = false,
    this.storedTcString,
    this.showConsentManager = false,
    this.onError,
  });

  @override
  State<AxeptioConsentView> createState() => AxeptioConsentViewState();
}

/// Public state class to allow testing of message handling logic.
@visibleForTesting
class AxeptioConsentViewState extends State<AxeptioConsentView> {
  final _parser = JsBridgeMessageParser();
  late final WebViewController _controller;
  bool _injected = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'axeptioSdk',
        onMessageReceived: _onMessage,
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => _injectScripts(),
        onPageFinished: (_) => _injectScripts(),
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri?.scheme == 'https' && uri?.host == 'static.axept.io') {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
        onWebResourceError: _onWebResourceError,
        onHttpError: _onHttpError,
      ))
      ..loadRequest(widget.consentUrl);
  }

  Future<void> _injectScripts() async {
    if (_injected) return;
    try {
      await _injectLocalStorage();
    } on Exception {
      // localStorage injection may fail at onPageStarted when the JS context
      // is not yet ready.  This is expected — onPageFinished will retry.
    }
    try {
      await _injectPolyfill();
      _injected = true;
    } on Exception catch (e) {
      widget.onError?.call(
        AxeptioWebViewException('Failed to inject polyfill: $e', cause: e),
      );
    }
  }

  Future<void> _injectLocalStorage() async {
    final items = <String, String>{
      '_ax_app_sdk_mode': 'true',
      '_ax_user_cookies_duration': _axUserCookiesDurationDays.toString(),
      if (widget.attDenied) '_ax_app_att_denied': 'true',
      if (widget.storedTcString != null) '_ax_tcstring': widget.storedTcString!,
    };
    final script = items.entries
        .map((e) =>
            "localStorage.setItem(${jsonEncode(e.key)}, ${jsonEncode(e.value)});")
        .join('\n');
    await _controller.runJavaScript(script);
  }

  Future<void> _injectPolyfill() async {
    await _controller.runJavaScript(_polyfillScript);
  }

  @visibleForTesting
  void handleWebResourceError(WebResourceError error) {
    if (error.isForMainFrame ?? false) {
      widget.onError?.call(
        AxeptioNetworkException(
          'WebView failed to load: ${error.description}',
          cause: error,
        ),
      );
    }
  }

  void _onWebResourceError(WebResourceError error) =>
      handleWebResourceError(error);

  @visibleForTesting
  void handleHttpError(HttpResponseError error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 400) {
      widget.onError?.call(
        AxeptioNetworkException(
          'WebView HTTP error: $statusCode',
          statusCode: statusCode,
          cause: error,
        ),
      );
    }
  }

  void _onHttpError(HttpResponseError error) => handleHttpError(error);

  void _onMessage(JavaScriptMessage message) {
    final parsed = _parser.parse(message.message);
    if (parsed == null) return;

    final name = parsed.name;
    final payload = parsed.payload;

    if (name == 'app:cookies:ready') {
      unawaited(_handleCookiesReady(payload));
    } else if (name == 'cookies:close') {
      widget.onJsEvent(name, payload);
      widget.onClose();
    } else {
      widget.onJsEvent(name, payload);
    }
  }

  Future<void> _handleCookiesReady(Map<String, dynamic>? payload) async {
    if (payload == null) {
      widget.onClose();
      return;
    }
    final subscription = payload['subscription'];
    if (subscription == false) {
      widget.onClose();
      return;
    }
    if (widget.showConsentManager) {
      await _controller
          .runJavaScript("window.axeptioSDK?.requestShow?.('consentManager')");
      return;
    }
    final showCmp = payload['showCmp'] as bool? ?? false;
    if (!showCmp) {
      widget.onClose();
    }
  }

  @visibleForTesting
  Future<void> simulatePageFinished() async {
    _injected = false;
    await _injectScripts();
  }

  @visibleForTesting
  void simulateJsMessage(String rawJson) =>
      _onMessage(JavaScriptMessage(message: rawJson));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
