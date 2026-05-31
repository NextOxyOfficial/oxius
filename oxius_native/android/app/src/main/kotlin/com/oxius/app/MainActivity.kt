package com.oxius.app

import android.app.KeyguardManager
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
	private val mediaChannel = "com.oxius.app/media_saver"

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)

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
