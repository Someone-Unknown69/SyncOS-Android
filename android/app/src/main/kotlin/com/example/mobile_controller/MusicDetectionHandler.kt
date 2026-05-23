package com.example.mobile_controller

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.provider.Settings
import android.util.Base64
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.acommon.MethodChannel
import java.io.ByteArrayOutputStream

class MusicDetectionHandler(private val context: Context) {
    private val CHANNEL = "com.example.music_detection"
    private val EVENT_CHANNEL = "com.example.music_detection/events"
    private var mediaSessionManager: MediaSessionManager? = null

    private var eventSink: EventChannel.EventSink? = null // for music 
    private var generalEventSink: EventChannel.EventSink? = null // for notification

    private val registeredCallbacks = mutableMapOf<MediaController, MediaController.Callback>()
    
    // Cache to prevent redundant image encoding
    private var cachedAlbumArt: String? = null
    private var cachedMetadataId: String? = null

    companion object {
        private var instance: MusicDetectionHandler? = null

        fun getInstance(): MusicDetectionHandler? = instance

        fun sendMusicEvent(musicInfo: Map<String, Any?>) {
            instance?.eventSink?.success(musicInfo)
        }

        fun sendGeneralNotificationEvent(info: Map<String, Any?>) {
            instance?.generalEventSink?.success(info)
        }
    }

    init {
        instance = this
    }

    fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeMusicDetection" -> {
                    initializeMusicDetection()
                    result.success(mapOf("permissionGranted" to isNotificationListenerEnabled()))
                }
                "getCurrentMusicInfo" -> {
                    result.success(getCurrentMusicInfo())
                }
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(true)
                }
                "playPause" -> {
                    sendMediaCommand("playPause")
                    result.success(true)
                }
                "next" -> {
                    sendMediaCommand("next")
                    result.success(true)
                }
                "previous" -> {
                    sendMediaCommand("previous")
                    result.success(true)
                }
                "seek" -> {
                    val position = call.argument<Number>("position")?.toLong() ?: 0L
                    sendMediaCommand("seek", position)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    Log.d("MusicDetection", "Dart is now listening")
                    registerPlaybackCallbacks()
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    unregisterPlaybackCallbacks()
                }
            }
        )

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.general_notifications/events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    generalEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    generalEventSink = null
                }
            }
        )
    }

    private fun initializeMusicDetection() {
        try {
            mediaSessionManager = context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
        } catch (e: Exception) {
            Log.e("MusicDetection", "Failed to get MediaSessionManager: ${e.message}")
        }
    }

    private fun getAlbumArtBase64(metadata: MediaMetadata): String? {
        val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE) ?: "Unknown"
        val artist = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST) ?: "Unknown"
        val currentId = "$title-$artist"

        // Return cached art if it's the same song
        if (currentId == cachedMetadataId) {
            return cachedAlbumArt
        }

        try {
            val bitmap = metadata.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
                ?: metadata.getBitmap(MediaMetadata.METADATA_KEY_ART)
            
            if (bitmap != null) {
                val baos = ByteArrayOutputStream()
                val scale = Math.min(300f / bitmap.width, 300f / bitmap.height)
                val scaled = if (scale < 1) Bitmap.createScaledBitmap(bitmap, (bitmap.width * scale).toInt(), (bitmap.height * scale).toInt(), true) else bitmap
                scaled.compress(Bitmap.CompressFormat.JPEG, 70, baos) // Slightly lower quality for much faster speed
                val encoded = Base64.encodeToString(baos.toByteArray(), Base64.NO_WRAP)
                
                // Update cache
                cachedMetadataId = currentId
                cachedAlbumArt = encoded
                return encoded
            }
        } catch (e: Exception) {
            Log.e("MusicDetection", "Error encoding album art: ${e.message}")
        }
        
        return null
    }

    internal fun registerPlaybackCallbacks() {
        if (!isNotificationListenerEnabled() || mediaSessionManager == null) return
        unregisterPlaybackCallbacks()
        try {
            val componentName = ComponentName(context, MusicNotificationListenerService::class.java)
            val controllers = mediaSessionManager!!.getActiveSessions(componentName)
            for (controller in controllers) {
                val callback = object : MediaController.Callback() {
                    override fun onPlaybackStateChanged(state: PlaybackState?) {
                        val metadata = controller.metadata ?: return
                        val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE) ?: return
                        sendMusicEvent(mapOf(
                            "permissionGranted" to true,
                            "isPlaying" to (state?.state == PlaybackState.STATE_PLAYING),
                            "title" to title,
                            "artist" to metadata.getString(MediaMetadata.METADATA_KEY_ARTIST),
                            "album" to metadata.getString(MediaMetadata.METADATA_KEY_ALBUM),
                            "packageName" to controller.packageName,
                            "duration" to if (metadata.containsKey(MediaMetadata.METADATA_KEY_DURATION))
                                metadata.getLong(MediaMetadata.METADATA_KEY_DURATION) else null,
                            "currentPosition" to state?.position,
                            "albumArtBase64" to getAlbumArtBase64(metadata)
                        ))
                    }
                }
                controller.registerCallback(callback)
                registeredCallbacks[controller] = callback
            }
        } catch (e: Exception) {
            Log.e("MusicDetection", "Error registering callbacks: ${e.message}")
        }
    }

    private fun unregisterPlaybackCallbacks() {
        for ((controller, callback) in registeredCallbacks) {
            try { controller.unregisterCallback(callback) } catch (_: Exception) {}
        }
        registeredCallbacks.clear()
    }

    private fun isNotificationListenerEnabled(): Boolean {
        return NotificationManagerCompat.getEnabledListenerPackages(context).contains(context.packageName)
    }

    private fun openNotificationSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    private fun sendMediaCommand(command: String, position: Long = 0L) {
        if (!isNotificationListenerEnabled() || mediaSessionManager == null) return
        try {
            val componentName = ComponentName(context, MusicNotificationListenerService::class.java)
            val controllers = mediaSessionManager!!.getActiveSessions(componentName)
            if (controllers.isNotEmpty()) {
                var targetController = controllers.firstOrNull { it.playbackState?.state == PlaybackState.STATE_PLAYING }
                if (targetController == null) {
                    targetController = controllers.first()
                }

                when (command) {
                    "playPause" -> {
                        if (targetController.playbackState?.state == PlaybackState.STATE_PLAYING) {
                            targetController.transportControls.pause()
                        } else {
                            targetController.transportControls.play()
                        }
                    }
                    "next" -> targetController.transportControls.skipToNext()
                    "previous" -> targetController.transportControls.skipToPrevious()
                    "seek" -> targetController.transportControls.seekTo(position)
                }
            }
        } catch (e: Exception) {
            Log.e("MusicDetection", "Error sending media command: ${e.message}")
        }
    }

    private fun getCurrentMusicInfo(): Map<String, Any?> {
        val result = mutableMapOf<String, Any?>(
            "permissionGranted" to isNotificationListenerEnabled(),
            "isPlaying" to false,
            "title" to null,
            "artist" to null,
            "album" to null,
            "packageName" to null,
            "duration" to null,
            "currentPosition" to null,
            "albumArtBase64" to null
        )

        if (isNotificationListenerEnabled() && mediaSessionManager != null) {
            try {
                val componentName = ComponentName(context, MusicNotificationListenerService::class.java)
                val controllers = mediaSessionManager!!.getActiveSessions(componentName)
                for (controller in controllers) {
                    val metadata = controller.metadata
                    val playbackState = controller.playbackState
                    if (metadata != null) {
                        val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE)
                        if (!title.isNullOrEmpty()) {
                            result["title"] = title
                            result["artist"] = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST)
                            result["album"] = metadata.getString(MediaMetadata.METADATA_KEY_ALBUM)
                            result["packageName"] = controller.packageName
                            result["isPlaying"] = playbackState?.state == PlaybackState.STATE_PLAYING
                            if (metadata.containsKey(MediaMetadata.METADATA_KEY_DURATION))
                                result["duration"] = metadata.getLong(MediaMetadata.METADATA_KEY_DURATION)
                            result["currentPosition"] = playbackState?.position
                            result["albumArtBase64"] = getAlbumArtBase64(metadata)
                            break
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("MusicDetection", "Error reading sessions: ${e.message}")
            }
        }

        return result
    }
}
