package ir.psdkjoon.chola

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri

object DeepLinkHandler {
    val scheme = "chola".replace('_', '-')

    @Volatile
    private var pending: String? = null

    fun uri(host: String, path: String): Uri =
        Uri.Builder().scheme(scheme).authority(host).appendPath(path).build()

    fun handle(context: Context, intent: Intent?): Boolean {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return false
        val data = intent.data ?: return false
        val accepted = when (data.scheme) {
            scheme -> true
            "https" -> webLinksEnabled(context) &&
                data.host.equals(webHost(context), ignoreCase = true)
            else -> false
        }
        if (!accepted) return false
        pending = data.toString()
        return true
    }

    fun consume(): String? {
        val link = pending
        pending = null
        return link
    }

    fun setWebLinksEnabled(context: Context, enabled: Boolean) {
        context.packageManager.setComponentEnabledSetting(
            ComponentName(context, "ir.psdkjoon.chola.WebLink"),
            if (enabled) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            },
            PackageManager.DONT_KILL_APP,
        )
    }

    private fun webLinksEnabled(context: Context): Boolean =
        context.packageManager.getComponentEnabledSetting(
            ComponentName(context, "ir.psdkjoon.chola.WebLink"),
        ) == PackageManager.COMPONENT_ENABLED_STATE_ENABLED

    @Suppress("DEPRECATION")
    private fun webHost(context: Context): String? =
        try {
            context.packageManager
                .getApplicationInfo(context.packageName, PackageManager.GET_META_DATA)
                .metaData?.getString("deep_link_host")
        } catch (_: Exception) {
            null
        }
}
