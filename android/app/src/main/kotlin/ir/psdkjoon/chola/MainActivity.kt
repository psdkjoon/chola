package ir.psdkjoon.chola

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return EngineHolder.ensure(context)
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        Hosts.claim(this)
        super.onCreate(savedInstanceState)
        EngineHolder.activity = this
        WindowChannel.reapply(this)
        if (savedInstanceState == null) {
            Thread { FileService.trimTemporaryFiles(applicationContext) }.start()
            if (EngineHolder.takeFirstLaunch()) {
                MediaChannel.setLaunch(intent)
            } else {
                WindowChannel.sendCommand("home")
                MediaChannel.deliver(intent)
            }
            announceHandoff(intent)
            handleIncoming(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        MediaChannel.deliver(intent)
        announceHandoff(intent)
        handleIncoming(intent)
    }

    override fun onPostResume() {
        super.onPostResume()
        EngineHolder.activity = this
        EngineHolder.installIfWaiting()
        EngineHolder.continueBackgroundAccess()
    }

    private var taskLabel: String? = null
    private var taskColor = 0

    @Suppress("DEPRECATION")
    override fun setTaskDescription(taskDescription: ActivityManager.TaskDescription?) {
        if (taskDescription != null) {
            taskLabel = taskDescription.label
            taskColor = taskDescription.primaryColor
        }
        super.setTaskDescription(withIcon(taskLabel, taskColor))
    }

    fun refreshTaskDescription() {
        super.setTaskDescription(withIcon(taskLabel, taskColor))
    }

    @Suppress("DEPRECATION")
    private fun withIcon(label: String?, color: Int): ActivityManager.TaskDescription {
        val icon = LauncherIcon.currentIconRes(this)
        return if (android.os.Build.VERSION.SDK_INT >= 33) {
            ActivityManager.TaskDescription.Builder()
                .setLabel(label)
                .setIcon(icon)
                .setPrimaryColor(color)
                .build()
        } else {
            ActivityManager.TaskDescription(label, icon, color)
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        WindowChannel.onUserLeaveHint()
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        WindowChannel.notifyPip(isInPictureInPictureMode)
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        Hosts.onActivityResult(this, requestCode, resultCode, data)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        Hosts.onPermissionResult(requestCode, grantResults)
    }

    override fun onDestroy() {
        if (EngineHolder.activity === this) EngineHolder.activity = null
        Hosts.release(this)
        super.onDestroy()
    }

    private fun announceHandoff(intent: Intent?) {
        if (intent?.getBooleanExtra(EXTRA_HANDOFF, false) == true) {
            intent.removeExtra(EXTRA_HANDOFF)
            WindowChannel.sendCommand("handoff")
        }
    }

    private fun handleIncoming(intent: Intent?) {
        if (intent == null) return
        if (DeepLinkHandler.handle(this, intent)) Incoming.changed()
        ShareService.handle(this, intent)
        val payload = intent.getStringExtra(NotificationHelper.EXTRA_PAYLOAD)
        if (payload != null) {
            intent.removeExtra(NotificationHelper.EXTRA_PAYLOAD)
            Incoming.setPayload(payload)
        }
    }

    companion object {
        const val EXTRA_HANDOFF = "ir.psdkjoon.chola.HANDOFF"
    }
}
