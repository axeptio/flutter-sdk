import Flutter
import UIKit
import WebKit

private class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(controller, didReceive: message)
    }
}

class AxeptioConsentWebView: NSObject, FlutterPlatformView, WKScriptMessageHandler, WKNavigationDelegate {
    private let webView: WKWebView
    private let channel: FlutterMethodChannel
    private static let handlerName = "axeptioSdk"

    init(frame: CGRect, viewId: Int64, args: [String: Any], messenger: FlutterBinaryMessenger) {
        let contentController = WKUserContentController()

        // 1. localStorage injection at document start
        var localStorageItems: [String: Any] = [
            "_ax_app_sdk_mode": true,
            "_ax_user_cookies_duration": args["cookiesDurationDays"] as? Int ?? 190,
        ]
        if let attDenied = args["attDenied"] as? Bool, attDenied {
            localStorageItems["_ax_app_att_denied"] = true
        }
        if let tcString = args["storedTcString"] as? String {
            localStorageItems["_ax_tcstring"] = tcString
        }
        for (key, value) in localStorageItems {
            let stringValue = "\(value)"
            let escaped = stringValue.replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
            contentController.addUserScript(WKUserScript(
                source: "window.localStorage.setItem('\(key)', '\(escaped)');",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            ))
        }

        // 2. axeptioAppSdk polyfill — inject at document start so it's available
        // before the page's deferred scripts initialize
        let polyfill = """
        window.axeptioAppSdk = window.axeptioAppSdk || {};
        if (typeof window.axeptioAppSdk.onEvent !== 'function') {
            window.axeptioAppSdk.onEvent = function (name, payload) {
                var handler = window.webkit.messageHandlers.axeptioSdk;
                if (handler) {
                    handler.postMessage({name: name, payload: payload});
                }
            };
        }
        """
        contentController.addUserScript(WKUserScript(
            source: polyfill,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))

        // 3. Configure WKWebView
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.websiteDataStore = .nonPersistent()
        // The consent widget renders a muted, looping cover video and calls
        // play() once, without a user gesture. WKWebView defaults block that on
        // iPhone (inline playback off, every media type needs a gesture), so the
        // video area stays empty. Allow muted inline autoplay.
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        webView = WKWebView(frame: frame, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        channel = FlutterMethodChannel(
            name: "axeptio/consent_webview_\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        contentController.add(WeakScriptMessageHandler(delegate: self), name: Self.handlerName)
        webView.navigationDelegate = self

        // 4. Handle method calls from Dart (e.g. runJavaScript)
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else {
                result(FlutterError(code: "DISPOSED", message: "WebView disposed", details: nil))
                return
            }
            switch call.method {
            case "runJavaScript":
                if let js = call.arguments as? String {
                    self.webView.evaluateJavaScript(js) { _, error in
                        if let error = error {
                            result(FlutterError(code: "JS_ERROR", message: error.localizedDescription, details: nil))
                        } else {
                            result(nil)
                        }
                    }
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Expected String", details: nil))
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // 5. Load the consent URL
        if let urlString = args["url"] as? String, let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        } else {
            channel.invokeMethod("onError", arguments: [
                "type": "argument",
                "message": "Missing or invalid URL argument",
            ])
        }
    }

    func view() -> UIView { webView }

    // MARK: - WKScriptMessageHandler

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let body = message.body as? [String: Any],
              let event = body["name"] as? String else { return }
        var arguments: [String: Any] = ["name": event]
        if let payload = body["payload"] {
            arguments["payload"] = payload
        }
        channel.invokeMethod("onJsEvent", arguments: arguments)
    }

    // MARK: - WKNavigationDelegate

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url,
           url.scheme == "https",
           url.host == "static.axept.io" {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if let httpResponse = navigationResponse.response as? HTTPURLResponse,
           navigationResponse.isForMainFrame,
           httpResponse.statusCode >= 400 {
            channel.invokeMethod("onError", arguments: [
                "type": "http",
                "message": "HTTP error \(httpResponse.statusCode)",
            ])
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        channel.invokeMethod("onError", arguments: [
            "type": "navigation",
            "message": error.localizedDescription,
        ])
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        channel.invokeMethod("onError", arguments: [
            "type": "navigation",
            "message": error.localizedDescription,
        ])
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Self.handlerName)
        channel.setMethodCallHandler(nil)
    }
}
