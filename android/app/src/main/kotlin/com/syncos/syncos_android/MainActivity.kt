// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

package com.syncos.syncos_android

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "android_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // NOTE: The lock acquisition/release handlers (acquireConnectionLocks,
        // releaseConnectionLocks, areLocksHeld) are registered in SyncosNativePlugin
        // so they are reachable from BOTH the main engine and the background isolate's
        // engine. Do not re-register them here; duplicate registrations on the same
        // channel cause the last-registered handler to silently shadow the others.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestBatteryOptimization" -> {
                        requestBatteryOptimizationIfNeeded()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        // Automatically check and show the native notification permission dialog on startup.
        requestNotificationPermissionIfNeeded()
        // Automatically prompt for battery optimization exemption on startup.
        // Without this, even foreground services can be killed by OEM power managers
        // (Xiaomi MIUI, OPPO ColorOS, Realme UI, etc.) when the screen turns off.
        requestBatteryOptimizationIfNeeded()
    }

    private fun requestNotificationPermissionIfNeeded() {
        // POST_NOTIFICATIONS only exists on Android 13 (API 33) and above.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 101)
            }
        }
    }

    /**
     * On Realme/OPPO/Xiaomi and other OEM devices, even declared foreground services can be
     * killed when the screen turns off unless the app is explicitly exempted from battery
     * optimization. This opens the system dialog directly to the app's battery settings page.
     *
     * This is now called automatically from [onResume] in addition to being available via
     * the MethodChannel for manual triggering from Dart.
     */
    private fun requestBatteryOptimizationIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                val intent = Intent().apply {
                    action = android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                    data = Uri.parse("package:$packageName")
                }
                startActivity(intent)
            }
        }
    }
}