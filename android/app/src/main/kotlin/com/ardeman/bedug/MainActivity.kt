package com.ardeman.bedug

import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
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
        const val PICK_REQUEST = 4201
    }
}
