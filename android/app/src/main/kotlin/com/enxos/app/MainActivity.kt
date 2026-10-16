package com.enxos.app

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "enxos/pigeon_audio"
        private const val RECORD_PERMISSION_REQUEST = 7214
    }

    private var recorder: MediaRecorder? = null
    private var recordingFile: File? = null
    private var pendingRecordResult: MethodChannel.Result? = null
    private var player: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> startRecording(result)
                "stopRecording" -> stopRecording(result)
                "play" -> play(call.argument<String>("url"), result)
                "stop" -> {
                    stopPlayback()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startRecording(result: MethodChannel.Result) {
        if (recorder != null) {
            result.error("already_recording", "Já existe uma gravação ativa.", null)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED
        ) {
            pendingRecordResult = result
            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), RECORD_PERMISSION_REQUEST)
            return
        }
        beginRecording(result)
    }

    private fun beginRecording(result: MethodChannel.Result) {
        val file = File(cacheDir, "pigeon-ptt-${System.currentTimeMillis()}.m4a")
        try {
            val audioRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }
            audioRecorder.setAudioSource(MediaRecorder.AudioSource.MIC)
            audioRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            audioRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            audioRecorder.setAudioEncodingBitRate(64000)
            audioRecorder.setAudioSamplingRate(44100)
            audioRecorder.setOutputFile(file.absolutePath)
            audioRecorder.prepare()
            audioRecorder.start()
            recorder = audioRecorder
            recordingFile = file
            result.success(null)
        } catch (error: Exception) {
            recorder?.release()
            recorder = null
            file.delete()
            result.error("record_start_failed", error.localizedMessage, null)
        }
    }

    private fun stopRecording(result: MethodChannel.Result) {
        val activeRecorder = recorder
        val file = recordingFile
        if (activeRecorder == null || file == null) {
            result.error("not_recording", "Não há gravação ativa.", null)
            return
        }
        recorder = null
        recordingFile = null
        try {
            activeRecorder.stop()
            result.success(file.absolutePath)
        } catch (error: RuntimeException) {
            file.delete()
            result.error("record_stop_failed", error.localizedMessage, null)
        } finally {
            activeRecorder.reset()
            activeRecorder.release()
        }
    }

    private fun play(rawUrl: String?, result: MethodChannel.Result) {
        if (rawUrl.isNullOrBlank()) {
            result.error("missing_url", "O endereço do áudio está vazio.", null)
            return
        }
        val audioUrl = when {
            rawUrl.startsWith("/") -> "https://pigeon.enxos.online$rawUrl"
            rawUrl.startsWith("https://pigeon.enxos.online/") -> rawUrl
            else -> {
                result.error("invalid_url", "Endereço de áudio Pigeon inválido.", null)
                return
            }
        }
        stopPlayback()
        try {
            val audioPlayer = MediaPlayer()
            player = audioPlayer
            audioPlayer.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
            )
            audioPlayer.setDataSource(audioUrl)
            audioPlayer.setOnPreparedListener { it.start() }
            audioPlayer.setOnCompletionListener {
                stopPlayback()
                result.success(null)
            }
            audioPlayer.setOnErrorListener { _, what, extra ->
                stopPlayback()
                result.error(
                    "playback_failed",
                    "Falha ao reproduzir o áudio ($what/$extra).",
                    null
                )
                true
            }
            audioPlayer.prepareAsync()
        } catch (error: IOException) {
            stopPlayback()
            result.error("playback_failed", error.localizedMessage, null)
        }
    }

    private fun stopPlayback() {
        player?.let { activePlayer ->
            try {
                if (activePlayer.isPlaying) activePlayer.stop()
            } catch (_: IllegalStateException) {
                // O player pode ainda estar preparando a fonte.
            } finally {
                activePlayer.release()
            }
        }
        player = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != RECORD_PERMISSION_REQUEST) return
        val result = pendingRecordResult ?: return
        pendingRecordResult = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            beginRecording(result)
        } else {
            result.error(
                "microphone_permission_denied",
                "Permita o acesso ao microfone para enviar um PTT.",
                null
            )
        }
    }

    override fun onDestroy() {
        recorder?.run {
            try {
                stop()
            } catch (_: RuntimeException) {
                // Uma gravação interrompida muito cedo pode não produzir áudio.
            }
            release()
        }
        recorder = null
        stopPlayback()
        super.onDestroy()
    }
}