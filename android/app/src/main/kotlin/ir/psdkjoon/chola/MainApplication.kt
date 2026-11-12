package ir.psdkjoon.chola

import android.app.Application
import androidx.work.Configuration
import java.io.File
import java.util.Date

class MainApplication : Application(), Configuration.Provider {
    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder().setDefaultProcessName(packageName).build()

    override fun onCreate() {
        super.onCreate()
        if (ThemeSync.isSyncProcess()) return
        logCrashes()
        EngineHolder.attach(this)
        LauncherIcon.install(this)
        ThemeSync.watchInstalls(this)
    }

    private fun logCrashes() {
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            try {
                File(filesDir, "errors.log").appendText(
                    "--- ${Date()} [native]\n${error.stackTraceToString()}\n",
                )
            } catch (_: Exception) {
            }
            previous?.uncaughtException(thread, error)
        }
    }
}
