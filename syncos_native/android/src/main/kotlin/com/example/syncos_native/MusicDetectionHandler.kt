package com.example.syncos_native

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
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MusicDetectionHandler(private val context: Context) {
    private val CHANNEL = "com.example.music_detection"
    private val EVENT_CHANNEL = "com.example.music_detection/events"
    private var mediaSessionManager: MediaSessionManager? = null
    private var eventSink: EventChannel.EventSink? = null
    private val registeredCallbacks = mutableMapOf<MediaController, MediaController.Callback>()
    
    private val listenerComponent = ComponentName(context, MusicNotificationListenerService::class.java)
    
    private var cachedAlbumArt: String? = null
    private var cachedMetadataId: String? = null

    companion object {
        @Volatile
        var activeInstance: MusicDetectionHandler? = null

        fun getInstance(): MusicDetectionHandler? = activeInstance

        fun sendMusicEvent(musicInfo: Map<String, Any?>) {
            if (activeInstance == null) {
                Log.w("MusicDetection", "sendMusicEvent: activeInstance is NULL!")
                return
            }
            val currentSink = activeInstance?.eventSink
            if (currentSink == null) {
                Log.w("MusicDetection", "sendMusicEvent: activeInstance exists but eventSink is NULL!")
                return
            }
            currentSink.success(musicInfo)
        }
    }

    fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        activeInstance = this
        Log.d("MusicDetection", "MusicDetectionHandler globally configured.")
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeMusicDetection" -> {
                    initializeMusicDetection()
                    result.success(isNotificationListenerEnabled())
                }
                "getCurrentMusicInfo" -> {
                    result.success(getCurrentMusicInfo())
                }
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(true)
                }
                "playPause", "next", "previous" -> {
                    sendMediaCommand(call.method)
                    result.success(true)
                }
                "seek" -> {
                    val position = call.argument<Number>("position")?.toLong() ?: 0L
                    sendMediaCommand("seek", position)
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
                    Log.d("MusicDetection", "Dart is now listening")
                    registeredSink = events
                    eventSink = events
                    registerPlaybackCallbacks()
                }
                override fun onCancel(arguments: Any?) {
                    if (eventSink === registeredSink) {
                        Log.d("MusicDetection", "Dart cancelled stream")
                        eventSink = null
                        unregisterPlaybackCallbacks()
                    } else {
                        Log.d("MusicDetection", "onCancel ignored (sink belongs to another engine)")
                    }
                    registeredSink = null
                }
            }
        )
    }

    private fun initializeMusicDetection() {
        Log.d("MusicDetection", "initializeMusicDetection called from Flutter")
        try {
            if (mediaSessionManager == null) {
                mediaSessionManager = context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
                Log.d("MusicDetection", "MediaSessionManager acquired successfully")
            }
        } catch (e: Exception) {
            Log.e("MusicDetection", "Failed to get MediaSessionManager: ${e.message}")
        }
    }

    private fun getAlbumArtBase64(metadata: MediaMetadata): String? {
        val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE) ?: "Unknown"
        val artist = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST) ?: "Unknown"
        val currentId = "$title-$artist"

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
                scaled.compress(Bitmap.CompressFormat.JPEG, 70, baos)
                val encoded = Base64.encodeToString(baos.toByteArray(), Base64.NO_WRAP)
                
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
        Log.d("MusicDetection", "registerPlaybackCallbacks called")
        val managerCopy = mediaSessionManager
        if (managerCopy == null) {
            Log.w("MusicDetection", "Cannot register callbacks: mediaSessionManager is null (initializeMusicDetection not yet called)")
            return
        }
        unregisterPlaybackCallbacks()
        
        try {
            val controllers = managerCopy.getActiveSessions(listenerComponent)
            Log.d("MusicDetection", "registerPlaybackCallbacks: Found ${controllers.size} active sessions")
            for (controller in controllers) {
                val callback = object : MediaController.Callback() {
                    override fun onPlaybackStateChanged(state: PlaybackState?) {
                        emitMetadata(controller, state)
                    }

                    override fun onMetadataChanged(metadata: MediaMetadata?) {
                        emitMetadata(controller, controller.playbackState)
                    }
                }
                controller.registerCallback(callback)
                registeredCallbacks[controller] = callback
            }
        } catch (e: Exception) {
            Log.e("MusicDetection", "Error registering callbacks: ${e.message}")
        }
    }

    private fun emitMetadata(controller: MediaController, state: PlaybackState?, attempt: Int = 0) {
        val metadata = controller.metadata ?: return
        
        val art = getAlbumArtBase64(metadata)
        val duration = if (metadata.containsKey(MediaMetadata.METADATA_KEY_DURATION))
            metadata.getLong(MediaMetadata.METADATA_KEY_DURATION) else 0L

        // Retry if art or duration is missing (both can arrive late from the app)
        val artMissing = art == null
        val durationMissing = duration <= 0L
        Log.d("MusicDetection", "emitMetadata: current artMissing=$artMissing, durationMissing=$durationMissing")

        if (artMissing && attempt < 5) {
            Log.d("MusicDetection", "emitMetadata: Retrying (attempt $attempt), artMissing=$artMissing, durationMissing=$durationMissing")
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                emitMetadata(controller, controller.playbackState, attempt + 1)
            }, 300)
        } else {
            if (durationMissing) Log.w("MusicDetection", "emitMetadata: Sending event with no duration after $attempt retries")
            sendMusicEvent(createPayload(controller, state, metadata, art, duration))
        }
    }

    private fun createPayload(controller: MediaController, state: PlaybackState?, metadata: MediaMetadata, art: String?, duration: Long): Map<String, Any?> {
        return mapOf(
            "permissionGranted" to true,
            "isPlaying" to (state?.state == PlaybackState.STATE_PLAYING),
            "title" to metadata.getString(MediaMetadata.METADATA_KEY_TITLE),
            "artist" to metadata.getString(MediaMetadata.METADATA_KEY_ARTIST),
            "album" to metadata.getString(MediaMetadata.METADATA_KEY_ALBUM),
            "packageName" to controller.packageName,
            "duration" to duration,
            "currentPosition" to state?.position,
            "albumArtBase64" to art
        )
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
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    private fun sendMediaCommand(command: String, position: Long = 0L) {
        val managerCopy = mediaSessionManager
        if (!isNotificationListenerEnabled() || managerCopy == null) return
        try {
            val controllers = managerCopy.getActiveSessions(listenerComponent)
            if (controllers.isNotEmpty()) {
                val targetController = controllers.firstOrNull { it.playbackState?.state == PlaybackState.STATE_PLAYING } ?: controllers.first()

                when (command) {
                    "playPause" -> {
                        val transport = targetController.transportControls
                        if (targetController.playbackState?.state == PlaybackState.STATE_PLAYING) {
                            transport.pause()
                        } else {
                            transport.play()
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
        Log.d("MusicDetection", "getCurrentMusicInfo called")
        val result = mutableMapOf<String, Any?>(
            "permissionGranted" to isNotificationListenerEnabled(),
            "isPlaying" to false, "title" to null, "artist" to null, "album" to null,
            "packageName" to null, "duration" to null, "currentPosition" to null, "albumArtBase64" to null
        )

        val managerCopy = mediaSessionManager
        val isEnabled = isNotificationListenerEnabled()
        if (isEnabled && managerCopy != null) {
            try {
                val controllers = managerCopy.getActiveSessions(listenerComponent)
                Log.d("MusicDetection", "getCurrentMusicInfo: Found ${controllers.size} active sessions")
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

    fun dispose() {
        Log.d("MusicDetection", "Disposing handler context resources")
        unregisterPlaybackCallbacks()
        eventSink = null
        cachedAlbumArt = null
        cachedMetadataId = null
    }
}