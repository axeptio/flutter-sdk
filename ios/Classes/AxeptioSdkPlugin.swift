import AxeptioSDK
import Flutter
import UIKit

public class AxeptioSdkPlugin: NSObject, FlutterPlugin {

  static var eventStreamHandler: AxeptioEventStreamHandler? = nil

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "axeptio_sdk", binaryMessenger: registrar.messenger())
    let instance = AxeptioSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let eventStreamHandler = AxeptioEventStreamHandler()
    AxeptioSdkPlugin.eventStreamHandler = eventStreamHandler
    Axeptio.shared.setEventListener(eventStreamHandler.axeptioEventListener)

    let eventChannel = FlutterEventChannel(
      name: "axeptio_sdk/events", binaryMessenger: registrar.messenger())
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
      guard let args = call.arguments as? [String: Any],
        let denied = args["denied"] as? Bool
      else {
        result(
          FlutterError.init(
            code: "invalid_args", message: "setUserDeniedTracking: Missing argument 'denied'",
            details: nil))
        return
      }
      Axeptio.shared.setUserDeniedTracking(denied: denied)
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
        let token = arguments["token"]
      else {
        result(nil)
        return
      }

      let axeptioUrl = Axeptio.shared.appendAxeptioTokenToURL(url, token: token)
      result(axeptioUrl.absoluteString)

    case "getConsentSavedData":
      let arguments = call.arguments as? [String: Any]
      let preferenceKey = arguments?["preferenceKey"] as? String

      let response = Axeptio.shared.getConsentDebugInfo(preferenceKey: preferenceKey)

      let safeResponse = sanitizeForFlutter(response)
      result(safeResponse)

    case "getConsentDebugInfo":
      let arguments = call.arguments as? [String: Any]
      let preferenceKey = arguments?["preferenceKey"] as? String

      let response = Axeptio.shared.getConsentDebugInfo(preferenceKey: preferenceKey)

      let safeResponse = sanitizeForFlutter(response)
      result(safeResponse)

    case "getVendorConsents":
      let vendorConsents = Axeptio.shared.getVendorConsents()
      let safeResponse = sanitizeForFlutter(vendorConsents)
      result(safeResponse)

    case "getConsentedVendors":
      let consentedVendors = Axeptio.shared.getConsentedVendors()
      let safeResponse = sanitizeForFlutter(consentedVendors)
      result(safeResponse)

    case "getRefusedVendors":
      let refusedVendors = Axeptio.shared.getRefusedVendors()
      let safeResponse = sanitizeForFlutter(refusedVendors)
      result(safeResponse)

    case "isVendorConsented":
      guard let arguments = call.arguments as? [String: Any],
        let vendorId = arguments["vendorId"] as? Int
      else {
        result(
          FlutterError.init(
            code: "invalid_args", message: "isVendorConsented: Missing argument 'vendorId'",
            details: nil))
        return
      }
      let isConsented = Axeptio.shared.isVendorConsented(vendorId)
      result(isConsented)


    default:
      result(FlutterMethodNotImplemented)
    }
  }


  /// Recursively converts values to Flutter-supported types,
  /// preventing codec crashes.
  func sanitizeForFlutter(_ value: Any) -> Any? {
    switch value {
    case is NSNull, is Bool, is Int, is Double, is String,
      is FlutterStandardTypedData:
      return value
    case let date as Date:
      // fallback conversion, e.g. ISO string
      return ISO8601DateFormatter().string(from: date)
    case let array as [Any]:
      return array.compactMap { sanitizeForFlutter($0) }
    case let dict as [String: Any]:
      return dict.mapValues { sanitizeForFlutter($0) }
    case let dict as [Int: Bool]:
      // Convert [Int: Bool] to [String: Bool] for Flutter compatibility
      return Dictionary(uniqueKeysWithValues: dict.map { (String($0), $1) })
    default:
      // unsupported type, stringify as fallback
      return String(describing: value)
    }
  }

  func initialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(
        FlutterError.init(
          code: "invalid_args", message: "Wrong arguments for initialize", details: nil))
      return
    }

    guard let clientId = args["clientId"] as? String else {
      result(
        FlutterError.init(
          code: "invalid_args", message: "initialize: Missing argument clientId", details: nil))
      return
    }

    guard let cookiesVersion = args["cookiesVersion"] as? String else {
      result(
        FlutterError.init(
          code: "invalid_args", message: "initialize: Missing argument cookiesVersion", details: nil
        ))
      return
    }

    guard let targetService = args["targetService"] as? String else {
      result(
        FlutterError.init(
          code: "invalid_args", message: "initialize: Missing argument targetService", details: nil)
      )
      return
    }

    let axeptioService =
      targetService == "brands" ? AxeptioService.brands : AxeptioService.publisherTcf

    _ = args["token"] as? String

    if let token = args["token"] as? String {
      Axeptio.shared.initialize(
        targetService: axeptioService, clientId: clientId, cookiesVersion: cookiesVersion,
        token: token)
    } else {
      Axeptio.shared.initialize(
        targetService: axeptioService, clientId: clientId, cookiesVersion: cookiesVersion)
    }

    result(nil)
  }
}
