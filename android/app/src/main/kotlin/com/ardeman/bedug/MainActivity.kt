package com.ardeman.bedug

import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /// The Dart call waiting for the system sound picker to close.
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pick" -> pickSound(call.argument<String>("current"), result)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateDir" -> result.success(File(cacheDir, "updates").path)
                    "installApk" -> result.success(installApk(call.argument<String>("path")))
                    else -> result.notImplemented()
                }
            }
    }

    /// Hands a downloaded update to the system installer, which asks the user
    /// to confirm. Only GitHub builds declare the install permission and the
    /// file provider (src/github), so store builds answer "unsupported".
    private fun installApk(path: String?): String {
        val authority = "$packageName.updates"
        if (path == null || packageManager.resolveContentProvider(authority, 0) == null) {
            return "unsupported"
        }
        if (!packageManager.canRequestPackageInstalls()) {
            startActivity(
                Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")),
            )
            return "needsPermission"
        }
        val uri = FileProvider.getUriForFile(this, authority, File(path))
        startActivity(
            Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        )
        return "started"
    }

    private fun pickSound(current: String?, result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "The sound picker is already open", null)
            return
        }
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_NOTIFICATION)
            // The app's own menu already offers the system sound and silence.
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, false)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            current?.let { putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(it)) }
        }
        pendingPick = result
        startActivityForResult(intent, PICK_REQUEST)
    }

    @Deprecated("FlutterActivity is not a ComponentActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_REQUEST) return
        val result = pendingPick ?: return
        pendingPick = null
        val uri = if (resultCode == RESULT_OK) pickedUri(data) else null
        if (uri == null) {
            result.success(null)
            return
        }
        val title = RingtoneManager.getRingtone(this, uri)?.getTitle(this)
        result.success(mapOf("uri" to uri.toString(), "title" to (title ?: uri.lastPathSegment ?: "")))
    }

    private fun pickedUri(data: Intent?): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        }

    private companion object {
        const val CHANNEL = "com.ardeman.bedug/phone_sound"
        const val UPDATE_CHANNEL = "com.ardeman.bedug/update"
        const val PICK_REQUEST = 4201
    }
}
