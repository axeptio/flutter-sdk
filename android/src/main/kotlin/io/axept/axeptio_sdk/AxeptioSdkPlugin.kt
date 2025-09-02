package io.axept.axeptio_sdk

import android.app.Activity
import android.net.Uri
import io.axept.android.library.AxeptioSDK
import io.axept.android.library.AxeptioService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** AxeptioSdkPlugin */
class AxeptioSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    private lateinit var eventChannel: EventChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "axeptio_sdk")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "axeptio_sdk/events")
        eventChannel.setStreamHandler(AxeptioEventStreamHandler)
        
        // Initialize GVL Manager
        AxeptioGVLManager.initialize(flutterPluginBinding.applicationContext)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "initialize" -> {
                val arguments =
                        call.arguments?.let { it as? HashMap<String, Any> }
                                ?: run {
                                    result.error(
                                            "invalid_args",
                                            "Wrong arguments for initialize",
                                            null
                                    )
                                    return
                                }

                val clientId = arguments.get("clientId") as String
                val cookiesVersion = arguments.get("cookiesVersion") as String
                val token = arguments.get("token") as? String?
                val targetService = arguments.get("targetService") as String
                val axeptioService =
                        when (targetService) {
                            "brands" -> AxeptioService.BRANDS
                            "publishers" -> AxeptioService.PUBLISHERS_TCF
                            else -> AxeptioService.PUBLISHERS_TCF
                        }

                AxeptioSDK.instance()
                        .initialize(activity!!, axeptioService, clientId, cookiesVersion, token)

                result.success(null)
            }
            "showConsentScreen" -> {
                AxeptioSDK.instance().showConsentScreen(activity!!, true)
                result.success(null)
            }
            "axeptioToken" -> {
                result.success(AxeptioSDK.instance().token)
            }
            "appendAxeptioTokenURL" -> {
                val arguments =
                        call.arguments?.let { it as? HashMap<String, Any> }
                                ?: run {
                                    result.error(
                                            "invalid_args",
                                            "Wrong arguments for appendAxeptioTokenURL",
                                            null
                                    )
                                    return
                                }

                val urlStr = arguments.get("url") as String
                val uri = Uri.parse(urlStr)
                val token = arguments.get("token") as String

                val response = AxeptioSDK.instance().appendAxeptioToken(uri = uri, token = token)
                result.success(response.toString())
            }
            "clearConsent" -> {
                AxeptioSDK.instance().clearConsents()
                result.success(null)
            }
            "getConsentSavedData" -> {
                val preferenceKey = call.argument<String>("preferenceKey")
                val response = AxeptioSDK.instance().getConsentDebugInfo(preferenceKey)
                val safeResponse = sanitizeForFlutter(response)
                result.success(safeResponse)
            }
            "getConsentDebugInfo" -> {
                val preferenceKey = call.argument<String>("preferenceKey")
                val response = AxeptioSDK.instance().getConsentDebugInfo(preferenceKey)
                val safeResponse = sanitizeForFlutter(response)
                result.success(safeResponse)
            }
            "getVendorConsents" -> {
                val vendorConsents = AxeptioSDK.instance().getVendorConsents()
                val safeResponse = sanitizeForFlutter(vendorConsents)
                result.success(safeResponse)
            }
            "getConsentedVendors" -> {
                val consentedVendors = AxeptioSDK.instance().getConsentedVendors()
                val safeResponse = sanitizeForFlutter(consentedVendors)
                result.success(safeResponse)
            }
            "getRefusedVendors" -> {
                val refusedVendors = AxeptioSDK.instance().getRefusedVendors()
                val safeResponse = sanitizeForFlutter(refusedVendors)
                result.success(safeResponse)
            }
            "isVendorConsented" -> {
                val vendorId = call.argument<Int>("vendorId")
                if (vendorId != null) {
                    val isConsented = AxeptioSDK.instance().isVendorConsented(vendorId)
                    result.success(isConsented)
                } else {
                    result.error("invalid_args", "isVendorConsented: Missing argument 'vendorId'", null)
                }
            }


            // iOS specific
            "setupUI",
            "setUserDeniedTracking" -> {
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    fun sanitizeForFlutter(value: Any?): Any? {
        return when (value) {
            null, is Boolean, is Int, is Long, is Double, is String, is ByteArray -> value
            is java.util.Date ->
                    java.time.format.DateTimeFormatter.ISO_INSTANT.format(
                            value.toInstant()
                    ) // convert Date to ISO string
            is android.net.Uri -> value.toString() // convert Uri to string
            is List<*> -> value.mapNotNull { sanitizeForFlutter(it) }
            is Map<*, *> -> {
                val safeMap = mutableMapOf<String, Any?>()
                value.forEach { (k, v) ->
                    val key = k?.toString() ?: "null"
                    safeMap[key] = sanitizeForFlutter(v)
                }
                safeMap
            }
            else -> value.toString() // fallback for any unsupported type
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
