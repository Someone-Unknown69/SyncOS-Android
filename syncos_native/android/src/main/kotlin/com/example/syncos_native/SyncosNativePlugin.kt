package com.example.syncos_native

import android.content.Context
import android.content.Intent              // Required for Intent
import android.provider.Settings          // Required for Settings
import androidx.core.app.NotificationManagerCompat // Required for Notification access check
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel // Required for MethodChannel
import io.flutter.plugin.common.MethodCall    // Required for call
import io.flutter.plugin.common.MethodChannel.Result // Required for result

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

        val permChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.example/permissions")
        
        permChannel.setMethodCallHandler { call: MethodCall, result: Result ->
            when (call.method) {
                "requestNotificationListener" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    result.success(true)
                }
                "checkNotificationListener" -> {
                    val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(context)
                    result.success(enabledPackages.contains(context.packageName))
                }
                else -> result.notImplemented()
            }
        }

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
