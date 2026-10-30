import Flutter
import UIKit

public class AxeptioSdkPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "axeptio_sdk", binaryMessenger: registrar.messenger())
    let instance = AxeptioSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let factory = AxeptioConsentWebViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "axeptio/consent_webview")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
