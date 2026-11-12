package ir.psdkjoon.chola

import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

class QuickTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        live = this
        render()
    }

    override fun onStopListening() {
        if (live === this) live = null
        super.onStopListening()
    }

    override fun onClick() {
        super.onClick()
        val previous = state
        state = if (previous == "off") "busy" else "off"
        render()
        EngineHolder.toggleFromTile(applicationContext)
        if (state == "busy") {
            mainHandler.postDelayed(
                {
                    if (state == "busy") {
                        state = previous
                        live?.render()
                    }
                },
                BUSY_TIMEOUT_MS,
            )
        }
    }

    private fun render() {
        val tile = qsTile ?: return
        tile.state = if (state == "off") Tile.STATE_INACTIVE else Tile.STATE_ACTIVE
        tile.label = getString(R.string.app_name)
        if (Build.VERSION.SDK_INT >= 29) {
            tile.subtitle = when (state) {
                "busy" -> getString(R.string.tile_busy)
                "on" -> getString(R.string.tile_on)
                else -> getString(R.string.tile_off)
            }
        }
        tile.updateTile()
    }

    companion object {
        private const val BUSY_TIMEOUT_MS = 10_000L

        private val mainHandler = Handler(Looper.getMainLooper())

        @Volatile
        private var state = "off"

        @Volatile
        private var live: QuickTileService? = null

        fun setState(context: Context, value: String) {
            state = value
            val current = live
            if (current != null) {
                current.render()
            } else {
                requestListeningState(
                    context,
                    ComponentName(context, QuickTileService::class.java),
                )
            }
        }
    }
}
