package io.axept.axeptio_sdk

import io.axept.android.googleconsent.GoogleConsentStatus
import io.axept.android.googleconsent.GoogleConsentType
import io.axept.android.library.AxeptioEventListener
import io.axept.android.library.AxeptioSDK
import io.flutter.plugin.common.EventChannel


object AxeptioEventStreamHandler : EventChannel.StreamHandler {

    private var axeptioEventListener: AxeptioEventListener? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        axeptioEventListener = object : AxeptioEventListener {

            override fun onPopupClosedEvent() {
                super.onPopupClosedEvent()
                events?.success(hashMapOf("type" to "onPopupClosedEvent"))
            }

            override fun onGoogleConsentModeUpdate(consentMap: Map<GoogleConsentType, GoogleConsentStatus>) {
                super.onGoogleConsentModeUpdate(consentMap)
                val event = hashMapOf<String, Any>()
                event["type"] = "onGoogleConsentModeUpdate"
                event["googleConsentV2"] = mapOf(
                    "analyticsStorage" to (consentMap[GoogleConsentType.ANALYTICS_STORAGE] == GoogleConsentStatus.GRANTED),
                    "adStorage" to (consentMap[GoogleConsentType.AD_STORAGE] == GoogleConsentStatus.GRANTED),
                    "adUserData" to (consentMap[GoogleConsentType.AD_USER_DATA] == GoogleConsentStatus.GRANTED),
                    "adPersonalization" to (consentMap[GoogleConsentType.AD_PERSONALIZATION] == GoogleConsentStatus.GRANTED),
                )
                events?.success(event)
            }

            override fun onConsentCleared() {
                super.onConsentCleared()
                events?.success(hashMapOf("type" to "onConsentCleared"))
            }
        }
        axeptioEventListener?.let { AxeptioSDK.instance().setEventListener(it) }
    }

    override fun onCancel(arguments: Any?) {
        axeptioEventListener = null
    }
}