package io.axept.axeptio_sdk


import android.app.Activity
import android.net.Uri
import androidx.preference.PreferenceManager
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
                val arguments = call.arguments?.let { it as? HashMap<String, Any> } ?: run {
                    result.error("invalid_args", "Wrong arguments for initialize", null)
                    return
                }

                val clientId = arguments.get("clientId") as String
                val cookiesVersion = arguments.get("cookiesVersion") as String
                val token = arguments.get("token") as? String?
                val targetService = arguments.get("targetService") as String
                val axeptioService = when (targetService) {
                    "brands" -> AxeptioService.BRANDS
                    "publishers" -> AxeptioService.PUBLISHERS_TCF
                    else -> AxeptioService.PUBLISHERS_TCF
                }

                AxeptioSDK.instance().initialize(activity!!, axeptioService, clientId, cookiesVersion, token)

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
                val arguments = call.arguments?.let { it as? HashMap<String, Any> } ?: run {
                    result.error("invalid_args", "Wrong arguments for appendAxeptioTokenURL", null)
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

            // Android specific
            "getDefaultPreference" -> {
                val key = call.argument<String>("key")
                if (key == null) {
                    result.error("invalid_args", "Key is required", null)
                    return
                }

                val sharedPreferences = PreferenceManager.getDefaultSharedPreferences(activity!!)
                val value = sharedPreferences.all[key]
                result.success(value)
            }

            // iOS specific
            "setupUI", "setUserDeniedTracking" -> {
                result.success(null)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
