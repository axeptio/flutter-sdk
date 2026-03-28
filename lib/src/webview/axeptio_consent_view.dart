import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'js_bridge_message_parser.dart';

/// Duration in days for the Axeptio user cookie consent window.
const int _axUserCookiesDurationDays = 190;

const String _polyfillScript = r'''
window.webkit = window.webkit || {};
window.webkit.messageHandlers = window.webkit.messageHandlers || {};
window.webkit.messageHandlers.axeptioSdk = {
  postMessage: function(data) { axeptioSdk.postMessage(JSON.stringify(data)); }
};
''';

class AxeptioConsentView extends StatefulWidget {
  final Uri consentUrl;
  final bool attDenied;
  final String? storedTcString;
  final bool showConsentManager;
  final void Function(String name, Map<String, dynamic>? payload) onJsEvent;
  final void Function() onClose;

  const AxeptioConsentView({
    super.key,
    required this.consentUrl,
    required this.onJsEvent,
    required this.onClose,
    this.attDenied = false,
    this.storedTcString,
    this.showConsentManager = false,
  });

  @override
  State<AxeptioConsentView> createState() => AxeptioConsentViewState();
}

/// Public state class to allow testing of message handling logic.
@visibleForTesting
class AxeptioConsentViewState extends State<AxeptioConsentView> {
  final _parser = JsBridgeMessageParser();
  late final WebViewController _controller;

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
        // onPageStarted fires before the page's scripts execute, ensuring
        // localStorage values (_ax_app_att_denied etc.) and the webkit polyfill
        // are in place before app/index.js reads them synchronously on startup.
        // onPageFinished is too late: init() has already run by then.
        onPageStarted: (_) => _onPageFinished(),
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri?.scheme == 'https' && uri?.host == 'static.axept.io') {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(widget.consentUrl);
  }

  Future<void> _onPageFinished() async {
    await _injectLocalStorage();
    await _injectPolyfill();
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
  Future<void> simulatePageFinished() => _onPageFinished();

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
