package com.example.mobile_controller

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class GlobalNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val pkg = sbn.packageName
        val extras = sbn.notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()

        Log.d("GlobalNotification", "App: $pkg | Title: $title")

        if (MusicDetectionHandler.isMusicApp(pkg)) {
            MusicDetectionHandler.getInstance()?.processMusicNotification(sbn)
        } else if (!title.isNullOrEmpty()) {
            MusicDetectionHandler.sendGeneralNotificationEvent(mapOf(
                "title" to title,
                "text" to extras.getCharSequence(Notification.EXTRA_TEXT)?.toString(),
                "packageName" to pkg
            ))
        }
    }
}