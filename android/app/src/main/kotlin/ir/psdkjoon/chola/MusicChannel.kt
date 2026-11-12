package ir.psdkjoon.chola

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object MusicChannel {
    private const val CHANNEL = "chola/music"
    private const val VOLUME = 0.45f

    private val TRACKS = intArrayOf(
        R.raw.chola_loop,
        R.raw.chola_dawn,
        R.raw.chola_rain,
        R.raw.chola_lofi,
        R.raw.chola_musicbox,
        R.raw.chola_night,
        R.raw.chola_focus,
        R.raw.chola_breeze,
        R.raw.chola_piano,
        R.raw.chola_forest,
        R.raw.chola_ocean,
        R.raw.chola_cafe,
        R.raw.chola_snow,
        R.raw.chola_star,
        R.raw.chola_zen,
        R.raw.chola_camp,
        R.raw.chola_deep,
        R.raw.chola_sunny,
    )

    private lateinit var appContext: Context
    private var player: MediaPlayer? = null
    private var selection = -1
    private var index = 0

    fun register(engine: FlutterEngine, context: Context) {
        appContext = context.applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "play" -> play(call.argument<Int>("track") ?: -1)
            "pause" -> pause()
            "stop" -> release()
            "next" -> next()
            else -> {
                result.notImplemented()
                return
            }
        }
        result.success(null)
    }

    private fun play(track: Int) {
        try {
            val wanted = if (track in TRACKS.indices) track else -1
            val current = player
            if (current != null && wanted == selection) {
                if (!current.isPlaying) current.start()
                return
            }
            release()
            selection = wanted
            index = if (wanted >= 0) wanted else TRACKS.indices.random()
            start()
        } catch (_: Exception) {
            release()
        }
    }

    private fun start() {
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()
        val created = MediaPlayer.create(appContext, TRACKS[index], attributes, 0) ?: return
        created.isLooping = selection >= 0
        created.setVolume(VOLUME, VOLUME)
        created.setOnCompletionListener { advance() }
        created.start()
        player = created
    }

    private fun advance() {
        try {
            release()
            index = (index + 1) % TRACKS.size
            start()
        } catch (_: Exception) {
            release()
        }
    }

    private fun next() {
        if (player != null && selection < 0) advance()
    }

    private fun pause() {
        try {
            val current = player ?: return
            if (current.isPlaying) current.pause()
        } catch (_: Exception) {
            release()
        }
    }

    private fun release() {
        try {
            player?.release()
        } catch (_: Exception) {
        }
        player = null
    }
}
