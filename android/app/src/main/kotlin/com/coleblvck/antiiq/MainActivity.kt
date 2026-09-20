package com.coleblvck.antiiq

import android.content.Intent
import android.net.Uri
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: AudioServiceActivity() {
    private var intentChannel: MethodChannel? = null
    private var backupStorageBridge: BackupStorageBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register the custom audio metadata plugin
        flutterEngine.plugins.add(AudioMetadataPlugin())
        flutterEngine.plugins.add(NativeAudioPlugin())
        backupStorageBridge = BackupStorageBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        intentChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.coleblvck.antiiq/intent_audio")
        intentChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialIntent" -> result.success(intentPayload(intent))
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intentPayload(intent)?.let { payload ->
            intentChannel?.invokeMethod("receivedIntent", payload)
        }
    }

    @Deprecated("Deprecated in Android")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (backupStorageBridge?.handleActivityResult(requestCode, resultCode, data) == true) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        backupStorageBridge?.dispose()
        backupStorageBridge = null
        super.onDestroy()
    }

    private fun intentPayload(intent: Intent?): Map<String, Any?>? {
        if (intent == null) return null
        val uri = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }
            else -> null
        } ?: return null

        return mapOf(
            "uri" to uri.toString(),
            "action" to intent.action,
            "type" to intent.type,
        )
    }
}
