package hacker.silverwolf.punklorde

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch

class MainActivity: FlutterActivity() {
    private val WIDGET_CHANNEL = "hacker.silverwolf.punklorde/widget_refresh"
    private val PKLD_CHANNEL = "hacker.silverwolf.punklorde/pkld_handler"
    private var pendingPkldBytes: ByteArray? = null
    private var flutterEngine: FlutterEngine? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        this.flutterEngine = flutterEngine

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "forceRefresh") {
                MainScope().launch {
                    try {
                        ScheduleAppWidget().updateAll(applicationContext)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("REFRESH_ERROR", e.message, null)
                    }
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PKLD_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getPendingPkldFile") {
                val bytes = pendingPkldBytes
                pendingPkldBytes = null
                result.success(bytes)
            } else {
                result.notImplemented()
            }
        }

        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_VIEW) return

        val uri = intent?.data ?: return
        val bytes = readBytesFromUri(uri)
        if (bytes != null) {
            pendingPkldBytes = bytes
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                MethodChannel(it, PKLD_CHANNEL).invokeMethod("onPkldFileReceived", bytes)
            }
        }
    }

    private fun readBytesFromUri(uri: Uri): ByteArray? {
        return try {
            contentResolver.openInputStream(uri)?.use { it.readBytes() }
        } catch (e: Exception) {
            null
        }
    }
}