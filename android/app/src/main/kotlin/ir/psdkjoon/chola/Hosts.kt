package ir.psdkjoon.chola

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager

object Hosts {
    private val live = mutableListOf<Activity>()

    fun claim(host: Activity) {
        live.removeAll { it.isFinishing || it.isDestroyed }
        live.filter { it !== host }.forEach { it.finish() }
        live.clear()
        live.add(host)
    }

    fun release(host: Activity) {
        live.remove(host)
    }

    fun onActivityResult(host: Activity, requestCode: Int, resultCode: Int, data: Intent?) {
        FileService.onResult(host, requestCode, resultCode, data)
        MediaChannel.onActivityResult(requestCode, resultCode, data)
    }

    fun onPermissionResult(requestCode: Int, grantResults: IntArray) {
        PermissionService.onResult(requestCode, grantResults)
        if (requestCode == MediaChannel.REQUEST_PERMISSION) {
            MediaChannel.onPermissionResult(
                grantResults.isNotEmpty() &&
                    grantResults.all { it == PackageManager.PERMISSION_GRANTED },
            )
        }
    }
}
