import 'dart:async';
import 'dart:convert';
import 'package:axeptio_sdk/src/exceptions/axeptio_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Duration in days for the Axeptio user cookie consent window.
const int _axUserCookiesDurationDays = 190;

/// Polyfill bridging the Axeptio web page's `window.axeptioAppSdk.onEvent()`
/// to the Flutter JS channel on Android (via `addJavaScriptChannel`).
const String _androidPolyfillScript = r'''
window.axeptioAppSdk = window.axeptioAppSdk || {};
if (typeof window.axeptioAppSdk.onEvent !== 'function') {
  window.axeptioAppSdk.onEvent = function(event, payload) {
    if (window.axeptioSdk) {
      window.axeptioSdk.postMessage(JSON.stringify({ name: event, payload: payload }));
    }
  };
}
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
  // iOS: native PlatformView channel
  MethodChannel? _channel;

  // Android: webview_flutter controller
  WebViewController? _androidController;
  bool _androidInjected = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onError?.call(
          const AxeptioWebViewException(
            'Consent webview is not supported on web',
          ),
        );
        widget.onClose();
      });
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      _initAndroidWebView();
    } else if (defaultTargetPlatform != TargetPlatform.iOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onError?.call(
          AxeptioWebViewException(
            'Consent webview is not supported on ${defaultTargetPlatform.name}',
          ),
        );
        widget.onClose();
      });
    }
  }

  void _initAndroidWebView() {
    _androidController = WebViewController()
      ..setBackgroundColor(Colors.transparent)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'axeptioSdk',
        onMessageReceived: _onAndroidJsMessage,
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          _androidInjected = false;
          _androidInjectScripts();
        },
        onPageFinished: (_) => _androidInjectScripts(),
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null) return NavigationDecision.prevent;
          if (uri.scheme == 'https') return NavigationDecision.navigate;
          if (uri.scheme == 'about') return NavigationDecision.navigate;
          return NavigationDecision.prevent;
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame ?? false) {
            widget.onError?.call(
              AxeptioNetworkException(
                'WebView failed to load: ${error.description}',
                cause: error,
              ),
            );
          }
        },
        onHttpError: (error) {
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
        },
      ))
      ..loadRequest(widget.consentUrl);
  }

  Future<void> _androidInjectScripts() async {
    if (_androidInjected) return;
    final controller = _androidController;
    if (controller == null) return;
    bool localStorageOk = false;
    try {
      await _androidInjectLocalStorage(controller);
      localStorageOk = true;
    } on Exception {
      // May fail at onPageStarted; onPageFinished will retry.
    }
    try {
      await controller.runJavaScript(_androidPolyfillScript);
      if (localStorageOk) {
        _androidInjected = true;
      }
    } on Exception catch (e) {
      widget.onError?.call(
        AxeptioWebViewException('Failed to inject polyfill: $e', cause: e),
      );
    }
  }

  Future<void> _androidInjectLocalStorage(WebViewController controller) async {
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
    await controller.runJavaScript(script);
  }

  void _onAndroidJsMessage(JavaScriptMessage message) {
    try {
      final decoded = jsonDecode(message.message) as Map<String, dynamic>;
      final name = decoded['name'] as String?;
      if (name == null) return;
      _handleEvent(name, decoded['payload']);
    } catch (_) {}
  }

  // iOS: native PlatformView callbacks

  void _onPlatformViewCreated(int viewId) {
    _channel = MethodChannel('axeptio/consent_webview_$viewId');
    _channel!.setMethodCallHandler(handleNativeCall);
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    _channel = null;
    _androidController = null;
    super.dispose();
  }

  @visibleForTesting
  Future<dynamic> handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onJsEvent':
        final args = call.arguments;
        if (args is! Map) return;
        final name = args['name'];
        if (name is! String) return;
        _handleEvent(name, args['payload']);
        return;
      case 'onError':
        final args = call.arguments;
        if (args is! Map) return;
        final message = args['message'] is String
            ? args['message'] as String
            : 'Unknown error';
        final type = args['type'] is String ? args['type'] as String : null;
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

  // Shared event handling

  void _handleEvent(String name, dynamic payloadRaw) {
    // The native/JS side may send payload as a JSON string or a structured
    // Map/List, depending on how the bridge serializes the data.
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
        if (_androidController != null) {
          await _androidController!.runJavaScript(
              "window.axeptioSDK?.requestShow?.('consentManager')");
        } else {
          await _channel?.invokeMethod<void>(
            'runJavaScript',
            "window.axeptioSDK?.requestShow?.('consentManager')",
          );
        }
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
    if (kIsWeb) {
      return const Center(child: Text('Consent webview not available'));
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
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
    if (_androidController != null) {
      return WebViewWidget(controller: _androidController!);
    }
    return const Center(child: Text('Consent webview not available'));
  }
}
