import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  final void Function(String name, Map<String, dynamic>? payload) onJsEvent;
  final void Function() onClose;

  const AxeptioConsentView({
    super.key,
    required this.consentUrl,
    required this.onJsEvent,
    required this.onClose,
    this.attDenied = false,
    this.storedTcString,
  });

  @override
  State<AxeptioConsentView> createState() => AxeptioConsentViewState();
}

/// Public state class to allow testing of message handling logic.
@visibleForTesting
class AxeptioConsentViewState extends State<AxeptioConsentView> {
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
        onPageFinished: (_) => _onPageFinished(),
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
      '_ax_user_cookies_duration': '190',
      if (widget.attDenied) '_ax_app_att_denied': 'true',
      if (widget.storedTcString != null) '_ax_tcstring': widget.storedTcString!,
    };
    final script = items.entries
        .map((e) => "localStorage.setItem('${e.key}', '${e.value}');")
        .join('\n');
    await _controller.runJavaScript(script);
  }

  Future<void> _injectPolyfill() async {
    await _controller.runJavaScript(_polyfillScript);
  }

  void _onMessage(JavaScriptMessage message) {
    try {
      final decoded = jsonDecode(message.message) as Map<String, dynamic>;
      final name = decoded['name'] as String?;
      if (name == null) return;

      final payloadRaw = decoded['payload'];
      Map<String, dynamic>? payload;
      if (payloadRaw is String && payloadRaw.isNotEmpty) {
        payload = jsonDecode(payloadRaw) as Map<String, dynamic>?;
      } else if (payloadRaw is Map) {
        payload = Map<String, dynamic>.from(payloadRaw);
      }

      if (name == 'app:cookies:ready') {
        _handleCookiesReady(payload);
      } else if (name == 'cookies:close') {
        widget.onJsEvent(name, payload);
        widget.onClose();
      } else {
        widget.onJsEvent(name, payload);
      }
    } catch (_) {}
  }

  void _handleCookiesReady(Map<String, dynamic>? payload) {
    if (payload == null) {
      widget.onClose();
      return;
    }
    final subscription = payload['subscription'];
    if (subscription == false) {
      widget.onClose();
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
