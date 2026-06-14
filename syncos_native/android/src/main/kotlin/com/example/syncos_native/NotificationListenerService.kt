package com.example.syncos_native

import android.app.Notification
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class MusicNotificationListenerService : NotificationListenerService() {

    // When notification is detected we path it either to musichandler or notificationhandler
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        super.onNotificationPosted(sbn)

        val extras = sbn.notification?.extras ?: return
        val templateStyle = extras.getString(Notification.EXTRA_TEMPLATE) ?: "Standard"
        val isMedia = templateStyle == """android.app.Notification${"$"}MediaStyle"""

        if (isMedia) {
            sendForMusic(sbn)
        } else {
            sendForNotification(sbn)
        }
    }

    


    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d("MusicNotification", "Notification listener connected")
        scanActiveNotifications()
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d("MusicNotification", "Notification listener disconnected")
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
    
    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        scanActiveNotifications()
    }

    private fun scanActiveNotifications() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            val active = activeNotifications ?: return
            var found = false
            for (sbn in active) {
                if (sendForMusic(sbn)) {
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

    private fun sendForNotification(sbn: StatusBarNotification): Boolean {
        val notification = sbn.notification ?: return false
        val extras = notification.extras ?: return false

        val titleText = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val bodyText = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()

        if (titleText.isNullOrEmpty() && bodyText.isNullOrEmpty()) {
            return false
        }

        val isOngoing = (sbn.notification.flags and Notification.FLAG_ONGOING_EVENT) != 0
        val isNoClear = (sbn.notification.flags and Notification.FLAG_NO_CLEAR) != 0

        if (isOngoing || isNoClear) {
            return false
        }

        val payload = hashMapOf(
            "permissionGranted" to true,
            "titleText" to titleText,
            "bodyText" to bodyText,
            "subText" to subText,
            "packageName" to sbn.packageName
        )

        val intent = Intent("com.example.syncos_android.NEW_NOTIFICATION").apply {
            putExtra("notification_data", payload)
        }

        sendBroadcast(intent)
        return true
    }


    private fun sendForMusic(sbn: StatusBarNotification): Boolean {
        val notification = sbn.notification ?: return false
        val extras = notification.extras ?: return false
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()

        if (title.isNullOrEmpty()) return false

        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString();
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString();
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