package com.locatemeup.locatemeup

import android.app.Activity
import android.content.Intent
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.locatemeup/ringtone"
    private var mediaPlayer: MediaPlayer? = null
    private var pendingResult: MethodChannel.Result? = null
    private lateinit var ringtoneLauncher: ActivityResultLauncher<Intent>

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ringtoneLauncher = registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { result ->
            val pr = pendingResult
            pendingResult = null
            if (result.resultCode == Activity.RESULT_OK) {
                val uri: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    result.data?.getParcelableExtra(
                        RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java
                    )
                } else {
                    @Suppress("DEPRECATION")
                    result.data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
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
    }

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
                        ringtoneLauncher.launch(intent)
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
