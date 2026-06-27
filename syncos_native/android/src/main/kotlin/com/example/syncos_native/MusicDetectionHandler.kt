package com.example.syncos_native
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MusicDetectionHandler(private val context: Context) {
    private val CHANNEL = "com.example.music_detection"
    private val EVENT_CHANNEL = "com.example.music_detection/events"
    private var mediaSessionManager: MediaSessionManager? = null
    private var eventSink: EventChannel.EventSink? = null
    private val registeredCallbacks = mutableMapOf<MediaController, MediaController.Callback>()
    private val mainHandler = Handler(Looper.getMainLooper())
    
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
            // Ensure data maps stream back to the Dart UI context thread explicitly
            activeInstance?.mainHandler?.post {
                try {
                    currentSink.success(musicInfo)
                } catch (e: Exception) {
                    Log.e("MusicDetection", "Failed parsing event to stream sink: ${e.message}")
                }
            }
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

    private fun saveAlbumArtToTmpFile(metadata: MediaMetadata): String? {
        val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE) ?: "Unknown"
        val artist = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST) ?: "Unknown"
        val currentId = "$title-$artist"

        if (currentId == cachedMetadataId && cachedAlbumArt != null) {
            return cachedAlbumArt
        }

        try {
            val bitmap = metadata.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
                ?: metadata.getBitmap(MediaMetadata.METADATA_KEY_ART)

            if (bitmap != null) {
                val targetFile = File(context.cacheDir, "local_album_art.jpg")
                FileOutputStream(targetFile).use { fos ->
                    val scale = Math.min(300f / bitmap.width, 300f / bitmap.height)
                    val scaled = if (scale < 1f) {
                        Bitmap.createScaledBitmap(bitmap, (bitmap.width * scale).toInt(), (bitmap.height * scale).toInt(), true)
                    } else {
                        bitmap
                    }

                    scaled.compress(Bitmap.CompressFormat.JPEG, 70, fos)
                    fos.flush()
                }

                cachedMetadataId = currentId
                cachedAlbumArt = android.net.Uri.fromFile(targetFile).toString() 
                return cachedAlbumArt
            }
        } catch (e: Exception) {
            Log.e("MusicDetection", "Error saving album art: ${e.message}")
        }
        return null
    }


    internal fun registerPlaybackCallbacks() {
        val managerCopy = mediaSessionManager
        if (managerCopy == null) {
            Log.w("MusicDetection", "Cannot register callbacks: mediaSessionManager is null")
            return
        }
        unregisterPlaybackCallbacks()
        
        try {
            val controllers = managerCopy.getActiveSessions(listenerComponent)
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
        
        val artPath = saveAlbumArtToTmpFile(metadata)
        val duration = if (metadata.containsKey(MediaMetadata.METADATA_KEY_DURATION))
            metadata.getLong(MediaMetadata.METADATA_KEY_DURATION) else 0L

        val artMissing = artPath == null
        
        // Fix: Query if the metadata track itself changed during the delay loop execution
        if (artMissing && attempt < 5) {
            mainHandler.postDelayed({
                val currentMetadata = controller.metadata
                if (currentMetadata != null) {
                    val oldTitle = metadata.getString(MediaMetadata.METADATA_KEY_TITLE)
                    val newTitle = currentMetadata.getString(MediaMetadata.METADATA_KEY_TITLE)
                    if (oldTitle == newTitle) {
                        emitMetadata(controller, controller.playbackState, attempt + 1)
                    }
                }
            }, 300)
        } else {
            sendMusicEvent(createPayload(controller, state, metadata, artPath, duration))
        }
    }

    private fun createPayload(controller: MediaController, state: PlaybackState?, metadata: MediaMetadata, art: String?, duration: Long): Map<String, Any?> {
        val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE)

        return mapOf(
            "isValid" to !title.isNullOrEmpty(),
            "permissionGranted" to true,
            "status" to (state?.state == PlaybackState.STATE_PLAYING),
            "title" to title,
            "artist" to metadata.getString(MediaMetadata.METADATA_KEY_ARTIST),
            "album" to metadata.getString(MediaMetadata.METADATA_KEY_ALBUM),
            "packageName" to controller.packageName,
            "duration" to duration,
            "position" to state?.position,
            "albumArtUri" to art
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
        val result = mutableMapOf<String, Any?>(
            "isValid" to false,
            "permissionGranted" to isNotificationListenerEnabled(),
            "status" to false, "title" to null, "artist" to null, "album" to null,
            "packageName" to null, "duration" to null, "position" to null, "albumArtUri" to null
        )

        val managerCopy = mediaSessionManager
        val isEnabled = isNotificationListenerEnabled()
        if (isEnabled && managerCopy != null) {
            try {
                val controllers = managerCopy.getActiveSessions(listenerComponent)
                if (controllers.isEmpty()) return result

                for (controller in controllers) {
                    val metadata = controller.metadata
                    val playbackState = controller.playbackState
                    if (metadata != null) {
                        val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE)
                        if (!title.isNullOrEmpty()) {
                            result["isValid"] = true
                            result["title"] = title
                            result["artist"] = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST)
                            result["album"] = metadata.getString(MediaMetadata.METADATA_KEY_ALBUM)
                            result["packageName"] = controller.packageName
                            result["status"] = playbackState?.state == PlaybackState.STATE_PLAYING
                            if (metadata.containsKey(MediaMetadata.METADATA_KEY_DURATION))
                                result["duration"] = metadata.getLong(MediaMetadata.METADATA_KEY_DURATION)
                            result["position"] = playbackState?.position
                            result["albumArtUri"] = saveAlbumArtToTmpFile(metadata)
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
        mainHandler.removeCallbacksAndMessages(null)
        eventSink = null
        cachedAlbumArt = null
        cachedMetadataId = null
    }
}
