package io.axept.axeptio_sdk

import io.flutter.plugin.common.EventChannel

/** No-op stream handler — events are emitted by the Flutter WebView layer. */
object AxeptioEventStreamHandler : EventChannel.StreamHandler {
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {}
    override fun onCancel(arguments: Any?) {}
}
