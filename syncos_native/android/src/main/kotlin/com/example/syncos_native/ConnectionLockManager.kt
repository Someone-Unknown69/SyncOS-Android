// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

package com.example.syncos_native

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.os.PowerManager
import android.util.Log

private const val TAG = "SyncOS:LockManager"

/**
 * Manages a [WifiManager.WifiLock] and [PowerManager.WakeLock] pair for the duration
 * of an active SyncOS connection session.
 *
 * ## Why both locks are needed
 * - [PowerManager.PARTIAL_WAKE_LOCK] keeps the CPU running so the Dart isolate and the
 *   heartbeat timer remain scheduled.
 * - [WifiManager.WIFI_MODE_FULL_LOW_LATENCY] / [WifiManager.WIFI_MODE_FULL_HIGH_PERF]
 *   prevents the Wi-Fi radio from entering 802.11 PS-Poll (power-save) mode, which would
 *   cause the AP to buffer/drop TCP ACKs, eventually timing out the open socket.
 *
 * ## Lifecycle
 * Call [acquire] when the WebSocket enters the `connected` state.
 * Call [release] when the WebSocket enters `disconnected` or `listening` state.
 * Both methods are idempotent and safe to call multiple times.
 */
class ConnectionLockManager(context: Context) {

    private val appContext: Context = context.applicationContext

    private val wifiManager: WifiManager by lazy {
        appContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
    }

    private val powerManager: PowerManager by lazy {
        appContext.getSystemService(Context.POWER_SERVICE) as PowerManager
    }

    private var wifiLock: WifiManager.WifiLock? = null
    private var wakeLock: PowerManager.WakeLock? = null

    val isHeld: Boolean
        get() = wifiLock?.isHeld == true || wakeLock?.isHeld == true

    /**
     * Acquires the WifiLock and WakeLock.
     *
     * Uses [WifiManager.WIFI_MODE_FULL_LOW_LATENCY] on API 29+ (Android 10+), which is the
     * most aggressive mode and fully disables DTIM periods and scan throttling.
     * Falls back to [WifiManager.WIFI_MODE_FULL_HIGH_PERF] on older devices, which keeps
     * the radio in continuous-receive mode without entering PS-Poll.
     *
     * Note: LOW_LATENCY is only effective when the calling app is in the foreground OR
     * running as a foreground service — which SyncOS always is. It will gracefully degrade
     * to HIGH_PERF behaviour if this contract is violated.
     */
    fun acquire() {
        // --- WifiLock ---
        if (wifiLock?.isHeld != true) {
            @Suppress("DEPRECATION")
            val lockMode = WifiManager.WIFI_MODE_FULL_HIGH_PERF

            wifiLock = wifiManager.createWifiLock(lockMode, "syncos:wifi_lock").apply {
                setReferenceCounted(false)
                acquire()
            }
            Log.i(TAG, "WifiLock acquired (mode=HIGH_PERF)")
        }

        // --- WakeLock ---
        if (wakeLock?.isHeld != true) {
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "syncos:wake_lock"
            ).apply {
                setReferenceCounted(false)
                acquire() // Indefinite — released explicitly on disconnect.
            }
            Log.i(TAG, "WakeLock acquired")
        }
    }

    /**
     * Releases both locks if currently held. Safe to call when not held.
     */
    fun release() {
        wifiLock?.let {
            if (it.isHeld) {
                it.release()
                Log.i(TAG, "WifiLock released")
            }
        }
        wifiLock = null

        wakeLock?.let {
            if (it.isHeld) {
                it.release()
                Log.i(TAG, "WakeLock released")
            }
        }
        wakeLock = null
    }
}
