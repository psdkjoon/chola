package ir.psdkjoon.chola

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.io.File

object EngineHolder {
    private const val MIN_REMINDER_ID = 1000
    private const val MAX_REMINDER_ID = 999_999

    private lateinit var appContext: Context

    private var engine: FlutterEngine? = null
    private var tileChannel: MethodChannel? = null
    private var themeSyncChannel: MethodChannel? = null
    private var systemChannel: MethodChannel? = null
    private var pendingToggle = false
    private var pendingExactAlarms = false
    private var pendingInstall: File? = null

    @Volatile
    var activity: android.app.Activity? = null

    private var firstLaunch = true

    fun takeFirstLaunch(): Boolean {
        val value = firstLaunch
        firstLaunch = false
        return value
    }

    fun attach(context: Context) {
        appContext = context.applicationContext
    }

    @Synchronized
    fun ensure(context: Context): FlutterEngine {
        engine?.let { return it }
        appContext = context.applicationContext
        val created = FlutterEngine(appContext)
        setUpChannels(created)
        created.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault(),
        )
        engine = created
        return created
    }

    fun toggleFromTile(context: Context) {
        if (engine != null) {
            tileChannel?.invokeMethod("toggleRequested", null)
            return
        }
        pendingToggle = true
        ensure(context)
    }

    private fun setUpChannels(e: FlutterEngine) {
        val messenger = e.dartExecutor.binaryMessenger

        PlayerChannel.register(e, appContext)
        MusicChannel.register(e, appContext)
        MediaChannel.register(e, appContext)
        WindowChannel.register(e, appContext)

        MethodChannel(messenger, "chola/paths").setMethodCallHandler { call, result ->
            when (call.method) {
                "resolve" -> result.success(
                    mapOf(
                        "nativeLibraryDir" to appContext.applicationInfo.nativeLibraryDir,
                        "filesDir" to appContext.filesDir.absolutePath,
                    ),
                )
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "chola/launcher_icon").setMethodCallHandler { call, result ->
            when (call.method) {
                "configure" -> {
                    LauncherIcon.configure(
                        call.argument<String>("mode") ?: "system",
                        call.argument<String>("accent") ?: "",
                        call.argument<Number>("updatedAt")?.toLong() ?: 0L,
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        val themeSync = MethodChannel(messenger, "chola/theme_sync")
        themeSyncChannel = themeSync
        themeSync.setMethodCallHandler { call, result ->
            when (call.method) {
                "publish" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    val accent = call.argument<String>("accent") ?: ""
                    val mode = call.argument<String>("mode") ?: "system"
                    val updatedAt = call.argument<Number>("updatedAt")?.toLong() ?: 0L
                    ThemeSync.async(result) {
                        ThemeSync.toMap(ThemeSync.publish(appContext, enabled, accent, mode, updatedAt))
                    }
                }
                "pull" -> ThemeSync.async(result) {
                    ThemeSync.toMap(ThemeSync.pull(appContext))
                }
                "current" -> ThemeSync.async(result) {
                    ThemeSync.toMap(ThemeSync.current(appContext))
                }
                else -> result.notImplemented()
            }
        }

        val system = MethodChannel(messenger, "chola/system")
        systemChannel = system
        Incoming.listener = { system.invokeMethod("incoming", null) }
        system.setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> openUrl(call.argument<String>("url"), result)
                "installApk" -> installApk(call.argument<String>("path"), result)
                "abi" -> result.success(Build.SUPPORTED_ABIS.firstOrNull())
                "openDefaultApps" -> ThemeSync.async(result) { openDefaultApps() }
                "isDefaultPlayer" -> result.success(isDefaultPlayer())
                "setQuickPlay" -> {
                    QuickGate.set(appContext, call.argument<Boolean>("on") != false)
                    result.success(null)
                }
                "closeQuick" -> {
                    (activity as? QuickActivity)?.finish()
                    result.success(null)
                }
                "openFull" -> {
                    openFull()
                    result.success(null)
                }
                "requestNotifications" -> PermissionService.request(
                    activity,
                    listOf(PermissionService.NOTIFICATIONS),
                ) { granted -> result.success(granted) }
                "requestBackgroundAccess" -> {
                    requestBackgroundAccess()
                    result.success(null)
                }
                "notify" -> {
                    notify(
                        call.argument<String>("title") ?: "",
                        call.argument<String>("body") ?: "",
                    )
                    result.success(null)
                }
                "takeIncoming" -> result.success(Incoming.take())
                "startService" -> result.success(
                    ForegroundService.start(
                        appContext,
                        call.argument<String>("title"),
                        call.argument<String>("text"),
                    ),
                )
                "stopService" -> {
                    ForegroundService.stop(appContext)
                    result.success(null)
                }
                "setBootStart" -> {
                    BootReceiver.setStartService(appContext, call.argument<Boolean>("on") != false)
                    result.success(null)
                }
                "scheduleReminder" -> {
                    val id = call.argument<Number>("id")?.toInt()
                    val at = call.argument<Number>("at")?.toLong()
                    if (id == null || at == null || id !in MIN_REMINDER_ID..MAX_REMINDER_ID) {
                        result.error(
                            "bad_reminder",
                            "A reminder needs an id from $MIN_REMINDER_ID to $MAX_REMINDER_ID and a time.",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    val reminder = Reminders.Reminder(
                        id = id,
                        title = call.argument<String>("title") ?: "",
                        body = call.argument<String>("body") ?: "",
                        at = at,
                        repeatMillis = call.argument<Number>("repeatMillis")?.toLong() ?: 0L,
                        payload = call.argument<String>("payload"),
                    )
                    ThemeSync.async(result) {
                        Reminders.add(appContext, reminder)
                        true
                    }
                }
                "cancelReminder" -> {
                    val id = call.argument<Number>("id")?.toInt()
                    if (id == null) {
                        result.error("bad_reminder", "A reminder id is required.", null)
                        return@setMethodCallHandler
                    }
                    ThemeSync.async(result) {
                        Reminders.remove(appContext, id)
                        true
                    }
                }
                else -> result.notImplemented()
            }
        }

        val tile = MethodChannel(messenger, "chola/tile")
        tileChannel = tile
        tile.setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    setTileEnabled(true)
                    result.success(null)
                }
                "setState" -> {
                    QuickTileService.setState(
                        appContext,
                        call.argument<String>("state") ?: "off",
                    )
                    result.success(null)
                }
                "consumeToggle" -> {
                    val value = pendingToggle
                    pendingToggle = false
                    result.success(value)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun firstMedia(collection: Uri): Uri? {
        return try {
            val projection = arrayOf(android.provider.MediaStore.MediaColumns._ID)
            val cursor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val args = android.os.Bundle().apply {
                    putInt(android.content.ContentResolver.QUERY_ARG_LIMIT, 1)
                }
                appContext.contentResolver.query(collection, projection, args, null)
            } else {
                appContext.contentResolver.query(collection, projection, null, null, null)
            }
            cursor?.use {
                if (it.moveToFirst()) {
                    android.content.ContentUris.withAppendedId(collection, it.getLong(0))
                } else {
                    null
                }
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun openDefaultApps(): String {
        val flags = Intent.FLAG_ACTIVITY_NEW_TASK
        val samples = listOf(
            android.provider.MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
        )
        var found = false
        for (collection in samples) {
            val uri = firstMedia(collection) ?: continue
            found = true
            val type = appContext.contentResolver.getType(uri) ?: continue
            val probe = Intent(Intent.ACTION_VIEW)
                .setDataAndType(uri, type)
                .addFlags(flags or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            val owner = appContext.packageManager
                .resolveActivity(probe, PackageManager.MATCH_DEFAULT_ONLY)
                ?.activityInfo?.packageName
            if (owner == appContext.packageName) continue
            try {
                if (owner != null && owner != "android") {
                    appContext.startActivity(
                        Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                            .setData(Uri.parse("package:$owner"))
                            .addFlags(flags),
                    )
                } else {
                    appContext.startActivity(probe)
                }
                return "opened"
            } catch (_: Exception) {
            }
        }
        return if (found) "already" else "empty"
    }

    private fun isDefaultPlayer(): Boolean {
        fun owns(type: String, name: String): Boolean {
            val probe = Intent(Intent.ACTION_VIEW)
                .setDataAndType(Uri.parse("content://media/external/$name"), type)
            val info = appContext.packageManager.resolveActivity(probe, PackageManager.MATCH_DEFAULT_ONLY)
            return info?.activityInfo?.packageName == appContext.packageName
        }
        return owns("video/mp4", "video/media/1") && owns("audio/mpeg", "audio/media/1")
    }

    private fun openFull() {
        val host = activity ?: return
        val intent = Intent(appContext, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra(MainActivity.EXTRA_HANDOFF, true)
        appContext.startActivity(intent)
        if (host is QuickActivity) host.finish()
    }

    private fun openUrl(url: String?, result: MethodChannel.Result) {
        if (url == null) {
            result.error("bad_url", "No URL.", null)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            appContext.startActivity(intent)
            result.success(null)
        } catch (_: ActivityNotFoundException) {
            result.error("no_browser", "No app can open this link.", null)
        } catch (e: Exception) {
            result.error("open_failed", e.message ?: "Could not open this link.", null)
        }
    }

    private fun canInstall(): Boolean =
        Build.VERSION.SDK_INT < 26 ||
            appContext.packageManager.canRequestPackageInstalls()

    private fun installApk(path: String?, result: MethodChannel.Result) {
        val file = path?.let { File(it) }
        if (file == null || !file.isFile) {
            result.error("no_file", "The update file is missing.", null)
            return
        }
        try {
            if (canInstall()) {
                pendingInstall = null
                launchInstaller(file)
                result.success("installing")
            } else {
                pendingInstall = file
                appContext.startActivity(
                    Intent(
                        Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                        Uri.parse("package:${appContext.packageName}"),
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                result.success("needs_permission")
            }
        } catch (e: Exception) {
            pendingInstall = null
            result.error("install_failed", e.message ?: "Could not start the installer.", null)
        }
    }

    fun installIfWaiting() {
        val file = pendingInstall ?: return
        pendingInstall = null
        if (!canInstall()) return
        try {
            launchInstaller(file)
        } catch (_: Exception) {
        }
    }

    private fun launchInstaller(file: File) {
        val uri = FileProvider.getUriForFile(appContext, "${appContext.packageName}.updates", file)
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, "application/vnd.android.package-archive")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        appContext.startActivity(intent)
    }

    private fun requestBackgroundAccess() {
        val needsBattery = !BatteryService.isIgnoring(appContext)
        if (needsBattery && BatteryService.request(appContext)) {
            pendingExactAlarms = true
        } else {
            NotificationHelper.requestExactAlarms(appContext)
        }
    }

    fun continueBackgroundAccess() {
        if (!pendingExactAlarms) return
        pendingExactAlarms = false
        NotificationHelper.requestExactAlarms(appContext)
    }

    private fun notify(title: String, body: String) {
        NotificationHelper.notify(appContext, title, body)
    }

    private fun setTileEnabled(enabled: Boolean) {
        appContext.packageManager.setComponentEnabledSetting(
            ComponentName(appContext, "ir.psdkjoon.chola.QuickTileService"),
            if (enabled) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            },
            PackageManager.DONT_KILL_APP,
        )
    }

    fun requestThemeSync(done: () -> Unit) {
        val channel = if (engine != null) themeSyncChannel else null
        if (channel == null) {
            done()
            return
        }
        channel.invokeMethod(
            "refresh",
            null,
            object : MethodChannel.Result {
                override fun success(result: Any?) = done()
                override fun error(code: String, message: String?, details: Any?) = done()
                override fun notImplemented() = done()
            },
        )
    }
}
