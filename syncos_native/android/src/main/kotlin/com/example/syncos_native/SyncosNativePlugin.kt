// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

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
        // onAttachedToEngine() is called on every engine so the MethodChannels are
        // always reachable from whichever engine needs them (main or background).
        private var musicDetectionHandler: MusicDetectionHandler? = null
        private var notificationHandler: NotificationHandler? = null
        private var mediaNotificationHandler: MediaNotificationHandler? = null

        // Single lock manager instance shared across engines. Lives for the entire
        // process lifetime so locks survive Dart isolate restarts and Doze window
        // recycling of the background engine.
        private var connectionLockManager: ConnectionLockManager? = null
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        val engine = binding.flutterEngine

        // --- Permissions channel ---
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

        // --- Connection lock channel ---
        // Registered here (in the plugin) rather than in MainActivity so that it is
        // available on BOTH the main engine and the background engine that
        // flutter_background_service spins up for the Dart isolate. MainActivity's
        // engine only receives calls from the main isolate; the background isolate
        // uses its own separate engine whose channels are populated via
        // GeneratedPluginRegistrant — which registers every FlutterPlugin, including this one.
        if (connectionLockManager == null) {
            connectionLockManager = ConnectionLockManager(context)
        }
        val lockManager = connectionLockManager!!

        val lockChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "android_channel")
        lockChannel.setMethodCallHandler { call: MethodCall, result: Result ->
            when (call.method) {
                "acquireConnectionLocks" -> {
                    lockManager.acquire()
                    result.success(true)
                }
                "releaseConnectionLocks" -> {
                    lockManager.release()
                    result.success(true)
                }
                "areLocksHeld" -> {
                    result.success(lockManager.isHeld)
                }
                else -> result.notImplemented()
            }
        }

        // --- Feature handlers (singletons) ---
        if (musicDetectionHandler == null) {
            musicDetectionHandler = MusicDetectionHandler(context)
        }
        musicDetectionHandler?.configureFlutterEngine(engine)

        if (notificationHandler == null) {
            notificationHandler = NotificationHandler(context)
        }
        notificationHandler?.configureFlutterEngine(engine)

        if (mediaNotificationHandler == null) {
            mediaNotificationHandler = MediaNotificationHandler(context)
        }
        mediaNotificationHandler?.configureFlutterEngine(engine)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Never dispose — handlers are process-scoped background services.
        android.util.Log.d("SyncosNative", "onDetachedFromEngine — handlers remain alive.")
    }
}
