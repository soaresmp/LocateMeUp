package com.locatemeup.locatemeup

import android.app.Activity
import android.content.Intent
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.locatemeup/ringtone"
    private val RINGTONE_REQUEST = 9001
    private var mediaPlayer: MediaPlayer? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickRingtone" -> {
                        pendingResult = result
                        val currentUri = call.argument<String>("currentUri")
                        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALL)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                            if (currentUri != null) {
                                putExtra(
                                    RingtoneManager.EXTRA_RINGTONE_EXISTING_URI,
                                    Uri.parse(currentUri)
                                )
                            }
                        }
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, RINGTONE_REQUEST)
                    }

                    "playRingtone" -> {
                        releasePlayer()
                        try {
                            val uriStr = call.argument<String>("uri")
                            val uri = if (uriStr != null)
                                Uri.parse(uriStr)
                            else
                                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                            mediaPlayer = MediaPlayer().apply {
                                setDataSource(applicationContext, uri)
                                isLooping = true
                                prepare()
                                start()
                            }
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("PLAY_ERROR", e.message, null)
                        }
                    }

                    "stopRingtone" -> {
                        releasePlayer()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != RINGTONE_REQUEST) return
        val pr = pendingResult
        pendingResult = null
        if (resultCode == Activity.RESULT_OK) {
            val uri: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
            }
            if (uri != null) {
                val title = RingtoneManager.getRingtone(applicationContext, uri)
                    ?.getTitle(applicationContext) ?: "Ringtone"
                pr?.success(mapOf("uri" to uri.toString(), "title" to title))
            } else {
                pr?.success(null)
            }
        } else {
            pr?.success(null)
        }
    }

    private fun releasePlayer() {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
        } catch (_: Exception) {}
        mediaPlayer = null
    }

    override fun onDestroy() {
        releasePlayer()
        super.onDestroy()
    }
}
