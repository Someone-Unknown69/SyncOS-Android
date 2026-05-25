package com.example.mobile_controller

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
        private var instance: NotificationHandler? = null

        fun getInstance(): NotificationHandler? = instance

        fun sendNotification(notificationInfo: Map<String, Any?>) {
            val currentInstance = instance
            if (currentInstance == null) {
                Log.e("Notification", "CRITICAL: Cannot send notification. Instance companion slot is NULL.")
                return
            }
            if (currentInstance.eventSink == null) {
                Log.w("Notification", "WARNING: eventSink is NULL. Dart stream listener is not attached.")
                return
            }
            currentInstance.eventSink?.success(notificationInfo)
        }
    }

    fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        instance = this
        Log.d("Notification", "NotificationHandler instance successfully bound to singleton slot")
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeNotificationDetection" -> {
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
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    Log.d("Notification", "Dart is now listening")
                    registerLocalReceiver()
                }
                override fun onCancel(arguments: Any?) {
                    unregisterLocalReceiver()
                    eventSink = null
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
        eventSink = null
        if (instance == this) {
            instance = null
        }
    }
}