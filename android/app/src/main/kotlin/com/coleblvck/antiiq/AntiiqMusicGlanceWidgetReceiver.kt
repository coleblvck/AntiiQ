package com.coleblvck.antiiq

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

class AntiiqMusicGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = AntiiqMusicGlanceWidget()

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        val action = intent.action
        Log.d("AntiiqWidgetReceiver", "Received action: $action")

        when (action) {
            ACTION_PLAY_PAUSE -> {
                sendActionToHomeWidget(context, "play_pause")
            }
            ACTION_NEXT -> {
                sendActionToHomeWidget(context, "next")
            }
            ACTION_PREVIOUS -> {
                sendActionToHomeWidget(context, "previous")
            }
            ACTION_OPEN_APP -> {
                openApp(context)
            }
        }
    }

    private fun sendActionToHomeWidget(context: Context, action: String) {
        try {
            val uri = Uri.parse("antiiqwidget://$action")

            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                addFlags(Intent.FLAG_INCLUDE_STOPPED_PACKAGES)
                setPackage(context.packageName)
            }

            context.sendBroadcast(intent)
        } catch (e: Exception) {
            Log.e("AntiiqWidgetReceiver", "Error sending action to home_widget: ${e.message}")
        }
    }

    private fun openApp(context: Context) {
        try {
            val packageManager = context.packageManager
            val launchIntent = packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            }

            if (launchIntent != null) {
                context.startActivity(launchIntent)
            } else {
                Log.e("AntiiqWidgetReceiver", "Could not find launch intent for package")
            }
        } catch (e: Exception) {
            Log.e("AntiiqWidgetReceiver", "Error opening app: ${e.message}")
        }
    }

    companion object {
        const val ACTION_PLAY_PAUSE = "com.coleblvck.antiiq.PLAY_PAUSE"
        const val ACTION_NEXT = "com.coleblvck.antiiq.NEXT"
        const val ACTION_PREVIOUS = "com.coleblvck.antiiq.PREVIOUS"
        const val ACTION_OPEN_APP = "com.coleblvck.antiiq.OPEN_APP"
    }
}