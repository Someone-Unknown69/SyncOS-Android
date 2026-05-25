package com.example.mobile_controller

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

        val packageName = sbn.packageName
        val notificationId = sbn.id
        val extras = sbn.notification?.extras

        val titleText = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: "N/A"
        val bodyText = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: "N/A"
        val templateStyle = extras?.getString(Notification.EXTRA_TEMPLATE) ?: "Standard"
        val subText = extras?.getString(Notification.EXTRA_SUB_TEXT) ?: "N/A"

        val isMedia = templateStyle == """android.app.Notification${"$"}MediaStyle"""

        if(isMedia) {
            sendForMusic(sbn)
        } else {
            Log.d("NotificationAudit", "========================================")
            Log.d("NotificationAudit", "Package Name : $packageName (ID: $notificationId)")
            Log.d("NotificationAudit", "Title Text   : $titleText")
            Log.d("NotificationAudit", "SubText : $subText")        
            Log.d("NotificationAudit", "Body Content : $bodyText")
            Log.d("NotificationAudit", "Layout Style : $templateStyle")
            Log.d("NotificationAudit", "========================================")
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

    private fun sendForMusic(sbn: StatusBarNotification): Boolean {
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