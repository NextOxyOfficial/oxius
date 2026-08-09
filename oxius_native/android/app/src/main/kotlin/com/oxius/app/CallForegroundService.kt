package com.oxius.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat

/**
 * Keeps a call running while the user is in another app.
 *
 * On Android 14 the microphone is a "while in use" resource: the moment the
 * app stops being visible the mic is muted unless a foreground service with
 * the `microphone` type is running. Neither of the two services already in the
 * project covers a call:
 *
 *  - `flutter_background_service` is declared with `foregroundServiceType`
 *    `location` and is only used by rideshare. Adding `microphone` to it would
 *    make every call also claim the location type, so a user who denied
 *    location would get a SecurityException instead of a call.
 *  - `flutter_callkit_incoming`'s service runs only for a call accepted from
 *    the CallKit notification, and even then the app dismisses it right after
 *    accepting so the shade stays clean. Outgoing calls and calls accepted
 *    inside the app never had a foreground service at all.
 *
 * So calls get their own service, claiming exactly the types the call needs
 * and holds permission for: microphone always, camera only for a video call.
 * Declaring a type whose permission is missing is itself a crash on Android
 * 14, which is why the types are computed at start time rather than taken
 * wholesale from the manifest.
 */
class CallForegroundService : Service() {

    companion object {
        private const val TAG = "CallForegroundService"
        private const val CHANNEL_ID = "adsyclub_ongoing_call"
        private const val NOTIFICATION_ID = 0x0A11

        /// Tapped "Hang up" on the ongoing-call notification.
        const val ACTION_HANGUP = "com.oxius.app.call.HANGUP"

        private const val EXTRA_TITLE = "title"
        private const val EXTRA_TEXT = "text"
        private const val EXTRA_VIDEO = "video"
        private const val EXTRA_CONNECTED_AT = "connectedAt"

        /**
         * Starts the service, or updates its notification when it is already
         * running. [connectedAt] is the wall-clock millisecond the media
         * connected, or 0 while the call is still ringing — when set, the
         * notification shows a live timer that the system ticks for us.
         */
        fun start(
            context: Context,
            title: String,
            text: String,
            video: Boolean,
            connectedAt: Long
        ) {
            // A call without the microphone cannot happen, and a typed
            // foreground service whose permission is missing throws on
            // Android 14. Let the call screen's own permission flow surface
            // the problem instead of crashing here.
            if (!hasPermission(context, Manifest.permission.RECORD_AUDIO)) {
                Log.w(TAG, "not starting: RECORD_AUDIO not granted")
                return
            }
            val intent = Intent(context, CallForegroundService::class.java).apply {
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_TEXT, text)
                putExtra(EXTRA_VIDEO, video)
                putExtra(EXTRA_CONNECTED_AT, connectedAt)
            }
            // Android 12+ can refuse a foreground service started from the
            // background. Every path that reaches here is either user-visible
            // or inside the temporary allowlist a high-priority FCM message
            // grants, but a refusal must not take the call down with it.
            try {
                ContextCompat.startForegroundService(context, intent)
            } catch (e: Exception) {
                Log.w(TAG, "startForegroundService refused: ${e.message}")
            }
        }

        fun stop(context: Context) {
            try {
                context.stopService(Intent(context, CallForegroundService::class.java))
            } catch (e: Exception) {
                Log.w(TAG, "stopService failed: ${e.message}")
            }
        }

        private fun hasPermission(context: Context, permission: String): Boolean =
            ContextCompat.checkSelfPermission(context, permission) ==
                PackageManager.PERMISSION_GRANTED
    }

    /// True once this service has successfully gone foreground at least once.
    private var isForeground = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_HANGUP) {
            // Dart owns the call — the LiveKit room, the peer notification and
            // the call log all live there — so this only forwards the tap. The
            // engine is necessarily alive: it is the thing carrying the call.
            MainActivity.invokeCallMethod("hangup")
            stopEverything()
            return START_NOT_STICKY
        }

        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "AdsyClub"
        val text = intent?.getStringExtra(EXTRA_TEXT) ?: "কল চলছে"
        val video = intent?.getBooleanExtra(EXTRA_VIDEO, false) ?: false
        val connectedAt = intent?.getLongExtra(EXTRA_CONNECTED_AT, 0L) ?: 0L

        if (!hasPermission(this, Manifest.permission.RECORD_AUDIO)) {
            // Nothing legal to claim. Stopping now also satisfies the
            // five-second startForeground deadline of startForegroundService.
            stopEverything()
            return START_NOT_STICKY
        }

        try {
            startForegroundCompat(buildNotification(title, text, connectedAt), video)
            isForeground = true
        } catch (e: Exception) {
            Log.w(TAG, "startForeground failed: ${e.message}")
            // A call upgraded from audio to video re-enters here to add the
            // camera type, and Android can refuse that while the app is in the
            // background. Tearing the service down over a refused *upgrade*
            // would take the microphone with it and silence a call that was
            // working perfectly well a moment ago. Only a service that never
            // managed to go foreground at all has nothing to keep.
            if (!isForeground) {
                stopEverything()
            }
        }
        // A restarted service with no call to attach to would be a phantom
        // notification, so never let the system revive it on its own.
        return START_NOT_STICKY
    }

    private fun stopEverything() {
        isForeground = false
        try {
            ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        } catch (_: Exception) {
        }
        stopSelf()
    }

    private fun startForegroundCompat(notification: Notification, video: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            var types = ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            if (video && hasPermission(this, Manifest.permission.CAMERA)) {
                types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA
            }
            startForeground(NOTIFICATION_ID, notification, types)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(
        title: String,
        text: String,
        connectedAt: Long
    ): Notification {
        createChannel()

        // singleTask + the launcher intent resumes the existing task rather
        // than starting a second copy of the app, so the tap lands on the call
        // screen the user left behind.
        val launch = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val contentIntent = PendingIntent.getActivity(
            this,
            0,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_call_notification)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(contentIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)

        if (connectedAt > 0L) {
            // Let the system tick the duration; pushing a notification update
            // every second just to redraw a clock would be wasteful.
            builder.setShowWhen(true)
                .setWhen(connectedAt)
                .setUsesChronometer(true)
        }

        // Ending a call should not require finding the app first.
        val hangupIntent = Intent(this, CallForegroundService::class.java).apply {
            action = ACTION_HANGUP
        }
        builder.addAction(
            // A zero resource id is not a valid icon and some OEM shades treat
            // it as a broken action rather than an icon-less one.
            R.drawable.ic_call_notification,
            "কল শেষ",
            PendingIntent.getService(
                this,
                1,
                hangupIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )

        return builder.build()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "চলমান কল",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "অন্য অ্যাপে থাকা অবস্থায়ও কল চালু রাখে"
            setShowBadge(false)
            setSound(null, null)
            enableVibration(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        // Swiping the app away takes the Flutter engine — and with it the
        // LiveKit room — down. Leaving the service up would only strand an
        // ongoing-call notification for a call that no longer exists.
        stopEverything()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
