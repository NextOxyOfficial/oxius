package com.oxius.app

import android.app.KeyguardManager
import android.app.PictureInPictureParams
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Environment
import android.provider.MediaStore
import android.util.Rational
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
	companion object {
		/**
		 * The live call channel, so the foreground service can hand a
		 * notification tap back to the Dart side that actually owns the call.
		 * Cleared in onDestroy — a channel bound to a dead engine would throw.
		 */
		private var callChannel: MethodChannel? = null

		fun invokeCallMethod(method: String) {
			val channel = callChannel ?: return
			// Platform channels are main-thread only, and this is reached from
			// a service's onStartCommand.
			Handler(Looper.getMainLooper()).post {
				try {
					channel.invokeMethod(method, null)
				} catch (_: Exception) {
				}
			}
		}
	}

	private val mediaChannel = "com.oxius.app/media_saver"
	private val callServiceChannel = "com.oxius.app/call_service"

	/**
	 * Set when the floating call bubble is what brought the app back. Dart
	 * reads it on resume rather than being pushed to, because a tap on the
	 * bubble can arrive before the Flutter engine is up — a flag survives that
	 * wait, a method call would not.
	 */
	private var pendingCallOpen = false

	/**
	 * Whether a call is live right now, kept in sync from Dart.
	 *
	 * onUserLeaveHint has to decide instantly whether leaving the app should
	 * shrink it into a Picture-in-Picture window, and it cannot ask Dart —
	 * the answer would arrive after the activity has already stopped.
	 */
	private var callIsLive = false

	/** Portrait-ish while the call is audio, video-shaped while it is video. */
	private var callIsVideo = false

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)

		if (intent?.getBooleanExtra(CallBubbleOverlay.EXTRA_OPEN_CALL, false) == true) {
			pendingCallOpen = true
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
			setShowWhenLocked(true)
			setTurnScreenOn(true)
			val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
			keyguardManager?.requestDismissKeyguard(this, null)
		} else {
			@Suppress("DEPRECATION")
			window.addFlags(
				WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
					WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
					WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
			)
		}
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mediaChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"saveToGallery" -> {
						val sourcePath = call.argument<String>("sourcePath")
						val fileName = call.argument<String>("fileName")
						val isVideo = call.argument<Boolean>("isVideo") ?: false
						val album = call.argument<String>("album") ?: "AdsyClub"
						if (sourcePath == null || fileName == null) {
							result.error("bad_args", "sourcePath/fileName missing", null)
							return@setMethodCallHandler
						}
						try {
							val uri = saveToGallery(sourcePath, fileName, isVideo, album)
							result.success(uri)
						} catch (e: Exception) {
							result.error("save_failed", e.message, null)
						}
					}
					"openMedia" -> {
						val uriString = call.argument<String>("uri")
						val isVideo = call.argument<Boolean>("isVideo") ?: false
						if (uriString == null) {
							result.error("bad_args", "uri missing", null)
							return@setMethodCallHandler
						}
						try {
							openMedia(uriString, isVideo)
							result.success(true)
						} catch (e: Exception) {
							result.error("open_failed", e.message, null)
						}
					}
					else -> result.notImplemented()
				}
			}

		val callMethodChannel =
			MethodChannel(flutterEngine.dartExecutor.binaryMessenger, callServiceChannel)
		callChannel = callMethodChannel
		callMethodChannel
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"start" -> {
						CallForegroundService.start(
							applicationContext,
							call.argument<String>("title") ?: "AdsyClub",
							call.argument<String>("text") ?: "কল চলছে",
							call.argument<Boolean>("video") ?: false,
							// Dart sends an int, which arrives as Integer below
							// 2^31 and Long above it — read it as a Number so
							// both shapes work.
							call.argument<Number>("connectedAt")?.toLong() ?: 0L
						)
						result.success(true)
					}
					"stop" -> {
						CallForegroundService.stop(applicationContext)
						result.success(true)
					}
					"bubbleShow" -> {
						CallBubbleOverlay.show(
							applicationContext,
							call.argument<Boolean>("video") ?: false,
							call.argument<Number>("connectedAt")?.toLong() ?: 0L,
							call.argument<String>("status") ?: ""
						)
						result.success(CallBubbleOverlay.isShowing)
					}
					"bubbleHide" -> {
						CallBubbleOverlay.hide()
						result.success(true)
					}
					"canDrawOverlays" ->
						result.success(CallBubbleOverlay.canDrawOverlays(applicationContext))
					"requestOverlayPermission" -> {
						CallBubbleOverlay.requestOverlayPermission(this)
						result.success(true)
					}
					"setCallActive" -> {
						callIsLive = call.argument<Boolean>("active") ?: false
						callIsVideo = call.argument<Boolean>("video") ?: false
						result.success(true)
					}
					"pipSupported" -> result.success(pipSupported())
					"enterPip" -> result.success(enterPipNow())
					"exitPip" -> result.success(exitPipNow())
					"consumePendingCallOpen" -> {
						result.success(pendingCallOpen)
						pendingCallOpen = false
					}
					else -> result.notImplemented()
				}
			}
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		if (intent.getBooleanExtra(CallBubbleOverlay.EXTRA_OPEN_CALL, false)) {
			pendingCallOpen = true
		}
	}

	/**
	 * The user pressed Home or swiped up while a call was running.
	 *
	 * This is the whole point of Picture-in-Picture: the app shrinks into a
	 * small floating window that sits over whatever they open next, can be
	 * dragged anywhere, and taps back to full screen. It is what the overlay
	 * bubble was for — except PiP needs no permission whatsoever, so nobody
	 * is ever sent to a system Settings page to enable it.
	 *
	 * onUserLeaveHint fires only for a deliberate exit. It does NOT fire when
	 * another activity is launched on top (an incoming system dialog, the
	 * camera, a share sheet), which is exactly right — those are not the user
	 * leaving the call behind.
	 */
	override fun onUserLeaveHint() {
		super.onUserLeaveHint()
		if (callIsLive) {
			enterPipNow()
		}
	}

	override fun onPictureInPictureModeChanged(
		isInPictureInPictureMode: Boolean,
		newConfig: Configuration
	) {
		super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
		// Dart swaps the visible route for a compact call chip while the
		// window is thumbnail-sized — a full call screen scaled down to
		// 200dp is unreadable, and whatever route happened to be on top
		// (an inbox, a feed) is not what a floating call should show.
		Handler(Looper.getMainLooper()).post {
			try {
				callChannel?.invokeMethod("pipModeChanged", isInPictureInPictureMode)
			} catch (_: Exception) {
			}
		}
	}

	/**
	 * Leaves the floating window when the call it was showing has ended.
	 *
	 * Android gives no "exit PiP" call — an app's PiP window closes when its
	 * activity finishes, and finishing here would take the whole app with it.
	 * moveTaskToBack dismisses the window and leaves the app where the user
	 * left it, which is what "the call is over" should mean.
	 */
	private fun exitPipNow(): Boolean {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
		if (!isInPictureInPictureMode) return false
		return try {
			moveTaskToBack(true)
		} catch (_: Exception) {
			false
		}
	}

	private fun pipSupported(): Boolean =
		Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
			packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)

	/**
	 * Enters PiP, returning whether the window actually took.
	 *
	 * A false here is not a failure to handle — the ongoing-call notification
	 * is still in the shade and still taps back into the call. It only means
	 * this device or this moment (the activity is already stopping, PiP is
	 * switched off for the app) cannot host a floating window.
	 */
	private fun enterPipNow(): Boolean {
		// Inlined rather than delegated to pipSupported() so the compiler can
		// see the API-26 guard covering enterPictureInPictureMode below.
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
		if (!packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)) {
			return false
		}
		if (isInPictureInPictureMode) return true
		return try {
			// Android clamps the aspect ratio to between 1:2.39 and 2.39:1.
			// A voice call has nothing to show but a face, so it goes square;
			// a video call keeps a phone-shaped window.
			val ratio = if (callIsVideo) Rational(9, 16) else Rational(1, 1)
			enterPictureInPictureMode(
				PictureInPictureParams.Builder().setAspectRatio(ratio).build()
			)
		} catch (_: Exception) {
			false
		}
	}

	override fun onDestroy() {
		// The bubble is a window this activity's process owns; leaving it up
		// after the app is gone would strand a control with nothing behind it.
		CallBubbleOverlay.hide()
		callChannel = null
		super.onDestroy()
	}

	/**
	 * Copies an already-downloaded file into the device's shared media
	 * collection (Pictures/<album> for images, Movies/<album> for videos) via
	 * MediaStore so it shows up in the phone's Gallery/Photos app. On Android 10+
	 * this needs no storage permission because the app only writes its own media.
	 * Returns the inserted content:// URI as a String.
	 */
	private fun saveToGallery(
		sourcePath: String,
		fileName: String,
		isVideo: Boolean,
		album: String
	): String {
		val source = File(sourcePath)
		if (!source.exists()) {
			throw IllegalStateException("Source file not found")
		}

		val mimeType = mimeTypeFor(fileName, isVideo)
		val resolver = applicationContext.contentResolver

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			val relativeDir =
				(if (isVideo) Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_PICTURES) +
					File.separator + album
			val collection = if (isVideo) {
				MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
			} else {
				MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
			}

			val values = ContentValues().apply {
				put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
				put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
				put(MediaStore.MediaColumns.RELATIVE_PATH, relativeDir)
				put(MediaStore.MediaColumns.IS_PENDING, 1)
			}

			val itemUri = resolver.insert(collection, values)
				?: throw IllegalStateException("MediaStore insert returned null")

			resolver.openOutputStream(itemUri)?.use { out ->
				source.inputStream().use { input -> input.copyTo(out) }
			} ?: throw IllegalStateException("Could not open MediaStore output stream")

			values.clear()
			values.put(MediaStore.MediaColumns.IS_PENDING, 0)
			resolver.update(itemUri, values, null, null)
			return itemUri.toString()
		}

		// Pre-Android 10 fallback: insert via the legacy MediaStore columns.
		val collection = if (isVideo) {
			MediaStore.Video.Media.EXTERNAL_CONTENT_URI
		} else {
			MediaStore.Images.Media.EXTERNAL_CONTENT_URI
		}
		val values = ContentValues().apply {
			put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
			put(MediaStore.MediaColumns.TITLE, fileName)
			put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
		}
		val itemUri = resolver.insert(collection, values)
			?: throw IllegalStateException("MediaStore insert returned null")
		resolver.openOutputStream(itemUri)?.use { out ->
			source.inputStream().use { input -> input.copyTo(out) }
		} ?: throw IllegalStateException("Could not open MediaStore output stream")
		return itemUri.toString()
	}

	/** Opens the saved media item in the device gallery / photo viewer. */
	private fun openMedia(uriString: String, isVideo: Boolean) {
		val intent = Intent(Intent.ACTION_VIEW).apply {
			setDataAndType(Uri.parse(uriString), if (isVideo) "video/*" else "image/*")
			addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}
		startActivity(intent)
	}

	private fun mimeTypeFor(fileName: String, isVideo: Boolean): String {
		val ext = fileName.substringAfterLast('.', "").lowercase()
		return when (ext) {
			"jpg", "jpeg" -> "image/jpeg"
			"png" -> "image/png"
			"webp" -> "image/webp"
			"gif" -> "image/gif"
			"heic" -> "image/heic"
			"mp4" -> "video/mp4"
			"mov" -> "video/quicktime"
			"webm" -> "video/webm"
			"mkv" -> "video/x-matroska"
			else -> if (isVideo) "video/mp4" else "image/jpeg"
		}
	}
}
