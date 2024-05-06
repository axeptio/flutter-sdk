import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatelessWidget {
  WebViewPage({super.key, required String url}) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(url));
  }

  late final WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: _controller),
    );
  }
}
