package com.example.syncos_native

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin

class SyncosNativePlugin : FlutterPlugin {
    companion object {
        // Handler objects are singletons — created once, shared across all engines.
        // configureFlutterEngine() is called on every engine so the MethodChannel and
        // EventChannel are always reachable from whichever engine needs them.
        // Only the background Dart ever subscribes to the EventChannel, so the
        // UI engine's registration is inert (onListen never fires on it).
        private var musicDetectionHandler: MusicDetectionHandler? = null
        private var notificationHandler: NotificationHandler? = null
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        val engine = binding.flutterEngine

        if (musicDetectionHandler == null) {
            musicDetectionHandler = MusicDetectionHandler(context)
        }
        musicDetectionHandler?.configureFlutterEngine(engine)

        if (notificationHandler == null) {
            notificationHandler = NotificationHandler(context)
        }
        notificationHandler?.configureFlutterEngine(engine)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Never dispose — handlers are process-scoped background services.
        android.util.Log.d("SyncosNative", "onDetachedFromEngine — handlers remain alive.")
    }
}
