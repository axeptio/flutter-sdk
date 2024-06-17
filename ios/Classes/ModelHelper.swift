import Foundation

import AxeptioSDK

class ModelHelper {
    static func dictionary(from consents: GoogleConsentV2) -> [String: Bool] {
        return [
            "analyticsStorage": consents.adPersonalization == .granted,
            "adStorage": consents.adStorage == .granted,
            "adUserData": consents.adUserData == .granted,
            "adPersonalization": consents.adPersonalization == .granted
        ]
    }
}
