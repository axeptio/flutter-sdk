package io.axept.axeptio_sdk

import android.app.Activity
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugins.webviewflutter.WebViewFlutterAndroidExternalApi

/** AxeptioSdkPlugin — stub implementation; consent is handled by the Flutter WebView layer. */
class AxeptioSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var engine: FlutterEngine? = null

    @Suppress("DEPRECATION")
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "axeptio_sdk")
        channel.setMethodCallHandler(this)
        engine = flutterPluginBinding.flutterEngine
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
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "addDocumentStartScript" -> result.success(addDocumentStartScript(call))
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        engine = null
    }

    private fun addDocumentStartScript(call: MethodCall): Boolean {
        val engine = engine ?: return false
        val webViewId = call.argument<Number>("webViewId")?.toLong() ?: return false
        val script = call.argument<String>("script") ?: return false
        val origin = call.argument<String>("origin") ?: return false
        if (!WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT)) return false
        val webView = WebViewFlutterAndroidExternalApi.getWebView(engine, webViewId) ?: return false
        return try {
            WebViewCompat.addDocumentStartJavaScript(webView, script, setOf(origin))
            true
        } catch (e: IllegalArgumentException) {
            false
        }
    }
}
