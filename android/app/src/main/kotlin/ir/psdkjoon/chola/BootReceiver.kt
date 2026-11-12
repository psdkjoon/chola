package ir.psdkjoon.chola

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        if (!isStartServiceEnabled(context)) return
        val blocked = Build.VERSION.SDK_INT >= 35 && context.applicationInfo.targetSdkVersion >= 35
        if (!blocked) ForegroundService.start(context)
    }

    companion object {
        private const val PREFS = "boot"
        private const val KEY = "start_service"

        fun isStartServiceEnabled(context: Context): Boolean =
            prefs(context).getBoolean(KEY, false)

        fun setStartService(context: Context, enabled: Boolean) {
            prefs(context).edit().putBoolean(KEY, enabled).apply()
        }

        private fun prefs(context: Context) =
            context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    }
}
