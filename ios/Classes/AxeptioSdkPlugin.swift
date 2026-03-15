import Flutter
import UIKit

/// Stub plugin — consent is handled by the Flutter WebView layer.
public class AxeptioSdkPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "axeptio_sdk", binaryMessenger: registrar.messenger())
    let instance = AxeptioSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let eventStreamHandler = AxeptioEventStreamHandler()
    let eventChannel = FlutterEventChannel(
      name: "axeptio_sdk/events", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(eventStreamHandler)
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
