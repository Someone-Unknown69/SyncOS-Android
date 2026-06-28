package com.example.syncos_native

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Base64
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MediaNotificationHandler(private val context: Context) {

    companion object {
        private const val TAG = "MediaNotification"
        const val CHANNEL_ID = "syncos_media_channel"
        const val NOTIFICATION_ID = 777
        const val METHOD_CHANNEL = "com.example.media_notification"
        const val EVENT_CHANNEL = "com.example.media_notification/controls"

        const val ACTION_PLAY_PAUSE = "com.example.syncos_native.MEDIA_PLAY_PAUSE"
        const val ACTION_NEXT      = "com.example.syncos_native.MEDIA_NEXT"
        const val ACTION_PREVIOUS  = "com.example.syncos_native.MEDIA_PREVIOUS"

        @Volatile
        var activeInstance: MediaNotificationHandler? = null
    }

    private val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val mainHandler = Handler(Looper.getMainLooper())

    private var eventSink: EventChannel.EventSink? = null
    private var mediaSession: MediaSessionCompat? = null
    private var controlReceiver: BroadcastReceiver? = null

    // ── Init ─────────────────────────────────────────────────────────────────

    init {
        createNotificationChannel()
        // Register receiver eagerly so notification button taps are never missed,
        // even if Dart hasn't opened the EventChannel subscription yet.
        registerControlReceiver()
    }

    // ── Flutter engine wiring ─────────────────────────────────────────────────

    fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        activeInstance = this

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showMediaNotification" -> {
                        showNotification(
                            title       = call.argument("title") ?: "",
                            artist      = call.argument("artist") ?: "",
                            album       = call.argument("album") ?: "",
                            isPlaying   = call.argument("isPlaying") ?: false,
                            albumArtB64 = call.argument("albumArtBase64"),
                            positionMs  = (call.argument<Number>("position")?.toLong()) ?: 0L,
                            durationMs  = (call.argument<Number>("duration")?.toLong()) ?: 0L
                        )
                        result.success(true)
                    }
                    "updateMediaNotification" -> {
                        showNotification(
                            title       = call.argument("title") ?: "",
                            artist      = call.argument("artist") ?: "",
                            album       = call.argument("album") ?: "",
                            isPlaying   = call.argument("isPlaying") ?: false,
                            albumArtB64 = call.argument("albumArtBase64"),
                            positionMs  = (call.argument<Number>("position")?.toLong()) ?: 0L,
                            durationMs  = (call.argument<Number>("duration")?.toLong()) ?: 0L
                        )
                        result.success(true)
                    }
                    "removeMediaNotification" -> {
                        removeNotification()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                private var registeredSink: EventChannel.EventSink? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    registeredSink = events
                    eventSink = events
                    Log.d(TAG, "Dart is listening for control events")
                }

                override fun onCancel(arguments: Any?) {
                    if (eventSink === registeredSink) {
                        eventSink = null
                    } else {
                        Log.d(TAG, "onCancel ignored (sink belongs to another engine)")
                    }
                    registeredSink = null
                }
            })
    }

    // ── Notification channel ──────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Media Playback",
                // DEFAULT importance is required for the seekbar and interactive
                // controls to render. LOW suppresses them on many OEM skins.
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Remote media currently playing via SyncOS"
                setShowBadge(false)
                setSound(null, null)           // no sound even at DEFAULT importance
                enableVibration(false)          // no vibration
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    // ── Notification display ──────────────────────────────────────────────────

    private fun showNotification(
        title: String,
        artist: String,
        album: String,
        isPlaying: Boolean,
        albumArtB64: String?,
        positionMs: Long = 0L,
        durationMs: Long = 0L
    ) {
        // Lazily creates a MediaSession so the notification gets lock-screen / quick-settings support
        if (mediaSession == null) {
            mediaSession = MediaSessionCompat(context, "SyncOSRemote").apply {
                setCallback(object : MediaSessionCompat.Callback() {
                    override fun onPlay() {
                        mainHandler.post { eventSink?.success("play_pause") }
                    }
                    override fun onPause() {
                        mainHandler.post { eventSink?.success("play_pause") }
                    }
                    override fun onSkipToNext() {
                        mainHandler.post { eventSink?.success("next") }
                    }
                    override fun onSkipToPrevious() {
                        mainHandler.post { eventSink?.success("previous") }
                    }
                    override fun onSeekTo(pos: Long) {
                        mainHandler.post { eventSink?.success("seek:${pos / 1000}") }
                    }
                })
                isActive = true
            }
        }

        // Provide real position + elapsedRealtime anchor so Android can animate the seek bar
        // without us needing to push updates every second.
        mediaSession!!.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY_PAUSE or
                    PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                    PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                    PlaybackStateCompat.ACTION_SEEK_TO
                )
                .setState(
                    if (isPlaying) PlaybackStateCompat.STATE_PLAYING
                    else           PlaybackStateCompat.STATE_PAUSED,
                    positionMs,
                    if (isPlaying) 1f else 0f,
                    SystemClock.elapsedRealtime()
                )
                .build()
        )

        // Decode base-64 album art if provided
        val albumArt: Bitmap? = albumArtB64?.let {
            try {
                val bytes = Base64.decode(it, Base64.DEFAULT)
                BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to decode album art: ${e.message}")
                null
            }
        }

        val metadataBuilder = MediaMetadataCompat.Builder()
            .putString(MediaMetadataCompat.METADATA_KEY_TITLE,    title)
            .putString(MediaMetadataCompat.METADATA_KEY_ARTIST,   artist)
            .putString(MediaMetadataCompat.METADATA_KEY_ALBUM,    album)
            .putLong(MediaMetadataCompat.METADATA_KEY_DURATION,   durationMs)
            
        if (albumArt != null) {
            metadataBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, albumArt)
        }

        mediaSession!!.setMetadata(metadataBuilder.build())

        // Resolve the host app's launcher icon for the small status-bar icon
        val smallIconRes = context.resources
            .getIdentifier("launcher_icon", "mipmap", context.packageName)
            .takeIf { it != 0 } ?: android.R.drawable.ic_media_play

        val playPauseIcon = if (isPlaying) android.R.drawable.ic_media_pause
                            else           android.R.drawable.ic_media_play

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(smallIconRes)
            .setContentTitle(title.ifBlank { "SyncOS" })
            .setContentText(artist)
            .setSubText(album.ifBlank { null })
            .setLargeIcon(albumArt)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            // Do NOT call setSilent(true)  it suppresses the interactive controls
            // on many Android skins. Sound/vibration are already disabled on the channel.
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            // Previous
            .addAction(
                android.R.drawable.ic_media_previous, "Previous",
                makePendingIntent(ACTION_PREVIOUS, 0)
            )
            // Play / Pause
            .addAction(
                playPauseIcon, if (isPlaying) "Pause" else "Play",
                makePendingIntent(ACTION_PLAY_PAUSE, 1)
            )
            // Next
            .addAction(
                android.R.drawable.ic_media_next, "Next",
                makePendingIntent(ACTION_NEXT, 2)
            )
            .setStyle(
                MediaStyle()
                    .setMediaSession(mediaSession!!.sessionToken)
                    .setShowActionsInCompactView(0, 1, 2)
            )
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
        Log.d(TAG, "Notification posted: $title – $artist [playing=$isPlaying]")
    }

    private fun removeNotification() {
        notificationManager.cancel(NOTIFICATION_ID)
        mediaSession?.release()
        mediaSession = null
        Log.d(TAG, "Notification removed")
    }

    // ── Control BroadcastReceiver ─────────────────────────────────────────────
    // Registered eagerly in init{} so it is never absent when a button is tapped.

    private fun registerControlReceiver() {
        if (controlReceiver != null) return

        controlReceiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                val control = when (intent?.action) {
                    ACTION_PLAY_PAUSE -> "play_pause"
                    ACTION_NEXT       -> "next"
                    ACTION_PREVIOUS   -> "previous"
                    else              -> return
                }
                Log.d(TAG, "Control button tapped: $control (sink=${eventSink != null})")
                // Always post on mainHandler the EventSink must be called on the
                // thread that owns the Flutter engine's binary messenger.
                mainHandler.post {
                    eventSink?.success(control)
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(ACTION_PLAY_PAUSE)
            addAction(ACTION_NEXT)
            addAction(ACTION_PREVIOUS)
        }

        // RECEIVER_EXPORTED is required here: PendingIntent from a notification is
        // considered an "external" send path on API 33+, so NOT_EXPORTED would drop it.
        // The intent is protected from third-party abuse by setPackage() in makePendingIntent.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(controlReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            context.registerReceiver(controlReceiver, filter)
        }
        Log.d(TAG, "Control receiver registered")
    }

    private fun unregisterControlReceiver() {
        controlReceiver?.let {
            try { context.unregisterReceiver(it) } catch (_: Exception) {}
            controlReceiver = null
        }
    }

    // ── PendingIntent helper ──────────────────────────────────────────────────

    private fun makePendingIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(action).apply { setPackage(context.packageName) }
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    // ── Cleanup ───────────────────────────────────────────────────────────────

    fun dispose() {
        removeNotification()
        unregisterControlReceiver()
        eventSink = null
    }
}
