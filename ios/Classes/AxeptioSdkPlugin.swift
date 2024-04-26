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

    let token = args["token"] as? String

    print("initialize method called")
    print("initialize method called with clientId: \(clientId)")
    print("initialize method called with cookiesVersion: \(cookiesVersion)")
    print("initialize method called with token: \(String(describing: token ))")

//    TODO: import last framework version to test init
//      Axeptio.shared.initialize(clientId: clientId, cookiesVersion: cookiesVersion, token: token)
    result(nil)
  }
}
