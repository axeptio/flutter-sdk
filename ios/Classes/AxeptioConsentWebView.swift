import Flutter
import UIKit
import WebKit

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
            if let data = try? JSONSerialization.data(withJSONObject: [key: value]),
               let json = String(data: data, encoding: .utf8) {
                contentController.addUserScript(WKUserScript(
                    source: "Object.assign(window.localStorage, \(json));",
                    injectionTime: .atDocumentStart,
                    forMainFrameOnly: true
                ))
            }
        }

        // 2. axeptioAppSdk polyfill at document end (before deferred scripts)
        let polyfill = """
        var axeptioAppSdk = {
            onEvent: function (name, payload) {
                var handler = window.webkit.messageHandlers.axeptioSdk;
                if (handler) {
                    handler.postMessage({name: name, payload: payload});
                }
            }
        };
        """
        contentController.addUserScript(WKUserScript(
            source: polyfill,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        ))

        // 3. Configure WKWebView
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.websiteDataStore = .nonPersistent()
        webView = WKWebView(frame: frame, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        channel = FlutterMethodChannel(
            name: "axeptio/consent_webview_\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        contentController.add(self, name: Self.handlerName)
        webView.navigationDelegate = self

        // 4. Handle method calls from Dart (e.g. runJavaScript)
        channel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "runJavaScript":
                if let js = call.arguments as? String {
                    self?.webView.evaluateJavaScript(js) { _, error in
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
        let payload = body["payload"]
        channel.invokeMethod("onJsEvent", arguments: [
            "name": event,
            "payload": payload as Any,
        ])
    }

    // MARK: - WKNavigationDelegate

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let host = navigationAction.request.url?.host,
           host == "static.axept.io" {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
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
