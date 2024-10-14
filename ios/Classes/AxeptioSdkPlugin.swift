import UIKit

import AxeptioSDK
import Flutter

public class AxeptioSdkPlugin: NSObject, FlutterPlugin {

  static var eventStreamHandler: AxeptioEventStreamHandler? = nil

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "axeptio_sdk", binaryMessenger: registrar.messenger())
    let instance = AxeptioSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

     let eventStreamHandler = AxeptioEventStreamHandler()
     AxeptioSdkPlugin.eventStreamHandler = eventStreamHandler
     Axeptio.shared.setEventListener(eventStreamHandler.axeptioEventListener)

     let eventChannel = FlutterEventChannel(name: "axeptio_sdk/events", binaryMessenger: registrar.messenger())
     eventChannel.setStreamHandler(eventStreamHandler)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
        print("getPlatformVersion called")
        result("iOS " + UIDevice.current.systemVersion)
    case "axeptioToken":
        result(Axeptio.shared.axeptioToken)

    case "initialize":
        initialize(call, result: result)
        result(nil)

    case "setupUI":
        Axeptio.shared.setupUI()
        result(nil)

    case "setUserDeniedTracking":
        Axeptio.shared.setUserDeniedTracking()
        result(nil)

    case "showConsentScreen":
        Axeptio.shared.showConsentScreen()
        result(nil)

    case "clearConsent":
        Axeptio.shared.clearConsent()
        result(nil)

    case "appendAxeptioTokenURL":
        guard let arguments = call.arguments as? [String: String],
            let urlArg = arguments["url"],
            let url = URL(string: urlArg),
            let token = arguments["token"] else {
            result(nil)
            return
        }

        let axeptioUrl = Axeptio.shared.appendAxeptioTokenToURL(url, token: token)
        result(axeptioUrl.absoluteString)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func initialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? Dictionary<String, Any> else {
      result(FlutterError.init(code: "invalid_args", message: "Wrong arguments for initialize", details: nil))
      return
    }

    guard let clientId = args["clientId"] as? String else {
      result(FlutterError.init(code: "invalid_args", message: "initialize: Missing argument clientId", details: nil))
      return
    }

    guard let cookiesVersion = args["cookiesVersion"] as? String else {
      result(FlutterError.init(code: "invalid_args", message: "initialize: Missing argument cookiesVersion", details: nil))
      return
    }

    guard let targetService = args["targetService"] as? String else {
      result(FlutterError.init(code: "invalid_args", message: "initialize: Missing argument targetService", details: nil))
      return
    }

      let axeptioService = targetService == "brands" ? AxeptioService.brands : AxeptioService.publisherTcf

    let token = args["token"] as? String

    if let token = args["token"] as? String {
      Axeptio.shared.initialize(targetService: axeptioService, clientId: clientId, cookiesVersion: cookiesVersion, token: token)
    } else {
      Axeptio.shared.initialize(targetService: axeptioService, clientId: clientId, cookiesVersion: cookiesVersion)
    }

    result(nil)
  }
}
