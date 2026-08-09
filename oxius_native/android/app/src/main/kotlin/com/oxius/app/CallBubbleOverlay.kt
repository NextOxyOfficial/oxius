package com.oxius.app

import android.animation.ValueAnimator
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowManager
import android.widget.Chronometer
import android.widget.ImageView
import android.widget.TextView
import kotlin.math.abs

/**
 * The floating call bubble: a small draggable circle that sits over whatever
 * app the user has moved on to, and takes one tap to get back to the call.
 *
 * It is native rather than a Flutter overlay on purpose. A Flutter overlay
 * window needs a second engine running beside the one already handling the
 * call, which is exactly the weight this feature should not add — and the
 * bubble shows only while the app is *not* in the foreground, when that second
 * engine would be competing for a backgrounded process's budget.
 *
 * The bubble draws on top of other apps, which needs SYSTEM_ALERT_WINDOW.
 * That permission is a user trip to Settings, so everything here degrades
 * quietly when it is missing — the ongoing-call notification is still a way
 * back to the call.
 */
object CallBubbleOverlay {

    private const val TAG = "CallBubbleOverlay"

    /** Set on the launch intent so the app knows the bubble is what opened it. */
    const val EXTRA_OPEN_CALL = "com.oxius.app.OPEN_ACTIVE_CALL"

    private var view: View? = null
    private var params: WindowManager.LayoutParams? = null
    private var windowManager: WindowManager? = null

    fun canDrawOverlays(context: Context): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }

    /** Opens the system page where "display over other apps" is granted. */
    fun requestOverlayPermission(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        try {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${context.packageName}")
            ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.w(TAG, "could not open overlay settings: ${e.message}")
        }
    }

    val isShowing: Boolean
        get() = view != null

    /**
     * Shows the bubble, or refreshes the one already up. [connectedAt] is the
     * wall-clock millisecond the media connected, or 0 while the call is still
     * ringing — the chronometer only runs once there is something to count.
     */
    fun show(context: Context, video: Boolean, connectedAt: Long, status: String) {
        if (!canDrawOverlays(context)) {
            Log.w(TAG, "not showing: overlay permission missing")
            return
        }

        val existing = view
        if (existing != null) {
            bind(existing, video, connectedAt, status)
            return
        }

        val manager = context.getSystemService(Context.WINDOW_SERVICE) as? WindowManager ?: return
        val bubble = LayoutInflater.from(context).inflate(R.layout.call_bubble, null)

        val layout = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            },
            // Not focusable: the bubble must never take key events away from
            // the app underneath it — the user is in the middle of using it.
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            val metrics = context.resources.displayMetrics
            x = metrics.widthPixels - dp(context, 84)
            y = (metrics.heightPixels * 0.35f).toInt()
        }

        bind(bubble, video, connectedAt, status)
        attachDragAndTap(context, bubble, layout, manager)

        try {
            manager.addView(bubble, layout)
        } catch (e: Exception) {
            Log.w(TAG, "addView failed: ${e.message}")
            return
        }

        view = bubble
        params = layout
        windowManager = manager
    }

    fun hide() {
        val bubble = view ?: return
        try {
            windowManager?.removeView(bubble)
        } catch (e: Exception) {
            Log.w(TAG, "removeView failed: ${e.message}")
        }
        view = null
        params = null
        windowManager = null
    }

    private fun bind(bubble: View, video: Boolean, connectedAt: Long, status: String) {
        bubble.findViewById<ImageView>(R.id.bubble_icon)?.setImageResource(
            if (video) R.drawable.ic_video_call_bubble else R.drawable.ic_call_notification
        )

        val timer = bubble.findViewById<Chronometer>(R.id.bubble_timer)
        val label = bubble.findViewById<TextView>(R.id.bubble_status)

        if (connectedAt > 0L) {
            label?.visibility = View.GONE
            timer?.apply {
                visibility = View.VISIBLE
                // Chronometer counts from elapsedRealtime, so the wall-clock
                // connect time has to be rebased onto that clock.
                base = SystemClock.elapsedRealtime() - (System.currentTimeMillis() - connectedAt)
                start()
            }
        } else {
            timer?.apply {
                stop()
                visibility = View.GONE
            }
            label?.apply {
                text = status
                visibility = if (status.isEmpty()) View.GONE else View.VISIBLE
            }
        }
    }

    private fun attachDragAndTap(
        context: Context,
        bubble: View,
        layout: WindowManager.LayoutParams,
        manager: WindowManager
    ) {
        val touchSlop = ViewConfiguration.get(context).scaledTouchSlop
        var downX = 0f
        var downY = 0f
        var startX = 0
        var startY = 0
        var dragging = false

        bubble.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.rawX
                    downY = event.rawY
                    startX = layout.x
                    startY = layout.y
                    dragging = false
                    true
                }

                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - downX
                    val dy = event.rawY - downY
                    if (!dragging && (abs(dx) > touchSlop || abs(dy) > touchSlop)) {
                        dragging = true
                    }
                    if (dragging) {
                        layout.x = startX + dx.toInt()
                        layout.y = startY + dy.toInt()
                        try {
                            manager.updateViewLayout(bubble, layout)
                        } catch (_: Exception) {
                        }
                    }
                    true
                }

                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    if (dragging) {
                        snapToEdge(context, bubble, layout, manager)
                    } else {
                        openCall(context)
                    }
                    true
                }

                else -> false
            }
        }
    }

    /** Slides the bubble to whichever screen edge it ended up nearest. */
    private fun snapToEdge(
        context: Context,
        bubble: View,
        layout: WindowManager.LayoutParams,
        manager: WindowManager
    ) {
        val metrics = context.resources.displayMetrics
        val width = if (bubble.width > 0) bubble.width else dp(context, 76)
        val margin = dp(context, 8)
        val target = if (layout.x + width / 2 < metrics.widthPixels / 2) {
            margin
        } else {
            metrics.widthPixels - width - margin
        }

        // Keep it on screen vertically too — a bubble dragged past the bottom
        // edge would be the only way back to the call, and unreachable.
        layout.y = layout.y.coerceIn(0, (metrics.heightPixels - width - margin).coerceAtLeast(0))

        ValueAnimator.ofInt(layout.x, target).apply {
            duration = 180
            addUpdateListener { animation ->
                layout.x = animation.animatedValue as Int
                try {
                    manager.updateViewLayout(bubble, layout)
                } catch (_: Exception) {
                    cancel()
                }
            }
        }.start()
    }

    private fun openCall(context: Context) {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_OPEN_CALL, true)
        }
        try {
            // Holding SYSTEM_ALERT_WINDOW with a visible overlay is one of the
            // exemptions from the background activity-start restriction, which
            // is what lets this tap work at all from another app.
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.w(TAG, "could not return to the call: ${e.message}")
        }
    }

    private fun dp(context: Context, value: Int): Int =
        (value * context.resources.displayMetrics.density).toInt()
}
