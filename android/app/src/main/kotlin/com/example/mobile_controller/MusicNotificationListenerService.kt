package com.example.mobile_controller

import android.app.Notification
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class MusicNotificationListenerService : NotificationListenerService() {

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.i("MusicNotification", "Notification listener connected")
        scanActiveNotifications()
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.i("MusicNotification", "Notification listener disconnected")
        MusicDetectionHandler.sendMusicEvent(mapOf(
            "permissionGranted" to false,
            "isPlaying" to false,
            "title" to null,
            "artist" to null,
            "album" to null,
            "packageName" to null,
            "duration" to null,
            "currentPosition" to null
        ))
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName
        val extras = sbn.notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()

        Log.d("AllNotifications", "App: $packageName | Title: $title")

        if (isMusicApp(packageName)) {
            sendFromNotification(sbn)
        } else if (!title.isNullOrEmpty()) {
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            MusicDetectionHandler.sendGeneralNotificationEvent(mapOf(
                "title" to title,
                "text" to text,
                "packageName" to packageName
            ))
        }
    }

    private fun isMusicApp(pkg: String): Boolean {
        // Expand this shi
        return pkg.contains("spotify") || pkg.contains("music") || pkg.contains("youtube")
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        scanActiveNotifications()
    }

    private fun scanActiveNotifications() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            val active = activeNotifications ?: return
            var found = false
            for (sbn in active) {
                if (sendFromNotification(sbn)) {
                    found = true
                    break
                }
            }
            if (!found) {
                MusicDetectionHandler.sendMusicEvent(mapOf(
                    "permissionGranted" to true,
                    "isPlaying" to false,
                    "title" to null,
                    "artist" to null,
                    "album" to null,
                    "packageName" to null,
                    "duration" to null,
                    "currentPosition" to null
                ))
            }
        }
    }

    private fun sendFromNotification(sbn: StatusBarNotification): Boolean {
        val notification = sbn.notification ?: return false
        val extras = notification.extras ?: return false
        val title = extras.getString(Notification.EXTRA_TITLE)

        if (title.isNullOrEmpty()) return false

        val text = extras.getString(Notification.EXTRA_TEXT)
        val subText = extras.getString(Notification.EXTRA_SUB_TEXT)
        val artist = when {
            !subText.isNullOrEmpty() -> subText
            !text.isNullOrEmpty() -> text
            else -> null
        }

        MusicDetectionHandler.sendMusicEvent(mapOf(
            "permissionGranted" to true,
            "isPlaying" to true,
            "title" to title,
            "artist" to artist,
            "album" to subText,
            "packageName" to sbn.packageName,
            "duration" to null,
            "currentPosition" to null
        ))

        // Re-register playback callbacks so the new session is tracked for play/pause and seek
        MusicDetectionHandler.getInstance()?.registerPlaybackCallbacks()

        return true
    }
}
