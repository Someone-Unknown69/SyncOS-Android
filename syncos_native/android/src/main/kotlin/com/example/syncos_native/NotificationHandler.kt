package com.example.syncos_native

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.Serializable

class NotificationHandler(private val context: Context) {
    private val CHANNEL = "com.example.notification_detection"
    private val EVENT_CHANNEL = "com.example.notification_detection/events"
    private var eventSink: EventChannel.EventSink? = null
    private var notificationReceiver: BroadcastReceiver? = null

    companion object {
        @Volatile
        var activeInstance: NotificationHandler? = null

        fun getInstance(): NotificationHandler? = activeInstance

        fun sendNotification(notificationInfo: Map<String, Any?>) {
            val currentSink = activeInstance?.eventSink
            if (currentSink == null) {
                Log.w("Notification", "sendNotification: No active eventSink found")
                return
            }
            currentSink.success(notificationInfo)
        }
    }

    fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        activeInstance = this
        Log.d("Notification", "NotificationHandler globally configured.")
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeNotificationDetection" -> {
                    Log.d("Notification", "initializeNotificationDetection called from Flutter")
                    result.success(isNotificationListenerEnabled())
                }
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(true)
                }
                "dispose" -> {
                    dispose()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var registeredSink: EventChannel.EventSink? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    registeredSink = events
                    eventSink = events
                    Log.d("Notification", "Dart is now listening")
                    registerLocalReceiver()
                }
                override fun onCancel(arguments: Any?) {
                    if (eventSink === registeredSink) {
                        unregisterLocalReceiver()
                        eventSink = null
                    } else {
                        Log.d("Notification", "onCancel ignored (sink belongs to another engine)")
                    }
                    registeredSink = null
                }
            }
        )
    }

    private fun registerLocalReceiver() {
        if (notificationReceiver != null) return
        notificationReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                intent?.getSerializableExtra("notification_data")?.let { data ->
                    @Suppress("UNCHECKED_CAST")
                    eventSink?.success(data as Map<String, Any?>)
                }
            }
        }
        
        val filter = IntentFilter("com.example.mobile_controller.NEW_NOTIFICATION")
        context.registerReceiver(notificationReceiver, filter, Context.RECEIVER_EXPORTED)
    }

    private fun unregisterLocalReceiver() {
        notificationReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (e: Exception) {
                Log.e("NotificationHandler", "Error removing broadcast receiver: ${e.message}")
            }
            notificationReceiver = null
        }
    }

    private fun isNotificationListenerEnabled(): Boolean {
        return NotificationManagerCompat.getEnabledListenerPackages(context).contains(context.packageName)
    }

    private fun openNotificationSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    fun dispose() {
        Log.d("Notification", "Disposing handler context resources")
        unregisterLocalReceiver()
        eventSink = null
    }
}