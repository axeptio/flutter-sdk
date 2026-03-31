import 'dart:async';
import 'dart:convert';
import 'package:axeptio_sdk/src/exceptions/axeptio_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Duration in days for the Axeptio user cookie consent window.
const int _axUserCookiesDurationDays = 190;

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
  MethodChannel? _channel;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onError?.call(
          const AxeptioWebViewException(
            'Consent webview is only supported on iOS',
          ),
        );
      });
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _channel = MethodChannel('axeptio/consent_webview_$viewId');
    _channel!.setMethodCallHandler(handleNativeCall);
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    _channel = null;
    super.dispose();
  }

  @visibleForTesting
  Future<dynamic> handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onJsEvent':
        final args = call.arguments as Map;
        final name = args['name'] as String?;
        final payloadRaw = args['payload'];
        if (name == null) return;
        _handleEvent(name, payloadRaw);
        return;
      case 'onError':
        final args = call.arguments as Map;
        final message = args['message'] as String? ?? 'Unknown error';
        final type = args['type'] as String?;
        widget.onError?.call(
          AxeptioWebViewException(
            'WebView error: $message${type != null ? ' (type=$type)' : ''}',
          ),
        );
        return;
      default:
        return;
    }
  }

  void _handleEvent(String name, dynamic payloadRaw) {
    // The native side sends payload as a JSON string (from the web page).
    // Parse it into a Map if possible.
    Map<String, dynamic>? payload;
    if (payloadRaw is String && payloadRaw.isNotEmpty) {
      try {
        payload = jsonDecode(payloadRaw) as Map<String, dynamic>?;
      } catch (_) {}
    } else if (payloadRaw is Map) {
      payload = Map<String, dynamic>.from(payloadRaw);
    }

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
      try {
        await _channel?.invokeMethod<void>(
          'runJavaScript',
          "window.axeptioSDK?.requestShow?.('consentManager')",
        );
      } on PlatformException catch (e) {
        widget.onError?.call(
          AxeptioWebViewException('Failed to show consent manager: $e',
              cause: e),
        );
      }
      return;
    }
    final showCmp = payload['showCmp'] as bool? ?? false;
    if (!showCmp) {
      widget.onClose();
    }
  }

  @visibleForTesting
  void simulateJsEvent(String name, dynamic payload) =>
      _handleEvent(name, payload);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _buildWebView(),
      ),
    );
  }

  Widget _buildWebView() {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const Center(child: Text('Consent webview not available'));
    }
    return UiKitView(
      viewType: 'axeptio/consent_webview',
      creationParams: <String, dynamic>{
        'url': widget.consentUrl.toString(),
        'attDenied': widget.attDenied,
        'storedTcString': widget.storedTcString,
        'showConsentManager': widget.showConsentManager,
        'cookiesDurationDays': _axUserCookiesDurationDays,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }
}
