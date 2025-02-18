import Flutter
import AxeptioSDK

class AxeptioEventStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    let axeptioEventListener = AxeptioEventListener()

    override init() {
        super.init()

        axeptioEventListener.onPopupClosedEvent = { [weak self] in
           guard let self else { return }
           self.sendEvent(event: "onPopupClosedEvent")
        }

        axeptioEventListener.onConsentCleared = { [weak self] in
            guard let self else { return }
            self.sendEvent(event: "onConsentCleared")
        }

        axeptioEventListener.onGoogleConsentModeUpdate = { [weak self] consents in
            guard let self else { return }
            let encoded = ModelHelper.dictionary(from: consents)
            self.sendEvent(event: "onGoogleConsentModeUpdate", arguments: ["googleConsentV2": encoded])
        }
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    func sendEvent(event: String, arguments: Dictionary<String, Any?>? = nil) {
        let eventDictionary: NSMutableDictionary = NSMutableDictionary()
        eventDictionary.setValue(event, forKey: "type")
        if let arguments = arguments {
            for (name, value) in arguments {
                if let value = value {
                    eventDictionary.setValue(value, forKey: name)
                }
            }
        }

        DispatchQueue.main.async {
            self.eventSink?(eventDictionary)
        }
    }
}
