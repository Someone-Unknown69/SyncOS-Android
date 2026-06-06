package com.example.mobile_controller

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.os.PowerManager
import android.util.Log
import io.flutter.app.FlutterApplication

class MainApplication : FlutterApplication() {

    companion object {
        private var wakeLock: PowerManager.WakeLock? = null
        private var wifiLock: WifiManager.WifiLock? = null
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        acquireLocks()
    }

    /**
     * Acquires a PARTIAL_WAKE_LOCK and a high-performance WifiLock at the application level.
     *
     * This is intentionally done in Application.onCreate() rather than in a plugin or service,
     * because it runs at the absolute earliest point in the process lifecycle — before any
     * Flutter engine, background service, or Activity is created.
     *
     * On aggressive OEM devices (Realme/OPPO/Xiaomi), Android's Doze Mode and the OEM's own
     * memory manager can kill background services within ~1 second of the screen turning off.
     * Holding locks here ensures the CPU and Wi-Fi radio stay alive from process start.
     *
     * The WakeLock is never explicitly released; it is held for the lifetime of the process.
     * This is correct behavior for a persistent background controller app.
     */
    private fun acquireLocks() {
        try {
            if (wakeLock == null) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = powerManager.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "SyncOS::ApplicationWakeLock"
                )
                @Suppress("WakelockTimeout")
                wakeLock?.acquire()
                Log.d("MainApplication", "PARTIAL_WAKE_LOCK acquired at application start")
            }
        } catch (e: Exception) {
            Log.e("MainApplication", "Failed to acquire WakeLock: $e")
        }

        try {
            if (wifiLock == null) {
                val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                wifiLock = wifiManager.createWifiLock(
                    WifiManager.WIFI_MODE_FULL_HIGH_PERF,
                    "SyncOS::ApplicationWifiLock"
                )
                wifiLock?.acquire()
                Log.d("MainApplication", "WIFI_MODE_FULL_HIGH_PERF lock acquired at application start")
            }
        } catch (e: Exception) {
            Log.e("MainApplication", "Failed to acquire WifiLock: $e")
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "syncos_background_service",
                "SyncOS Background Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps SyncOS connected in the background"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
