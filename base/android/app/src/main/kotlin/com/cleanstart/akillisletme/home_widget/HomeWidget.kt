package com.cleanstart.akillisletme.home_widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import androidx.core.app.PendingIntentCompat
import com.cleanstart.akillisletme.R
import com.cleanstart.akillisletme.overlay.OverlayService

// ─── Provider ────────────────────────────────────────────────────────────────

class HomeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { updateWidget(context, appWidgetManager, it) }
    }

    private fun updateWidget(context: Context, manager: AppWidgetManager, widgetId: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val counter = prefs.getInt(KEY_COUNTER, 0)

        val views = RemoteViews(context.packageName, R.layout.widget_home)
        views.setTextViewText(R.id.tv_counter, counter.toString())
        views.setOnClickPendingIntent(
            R.id.btn_increment,
            buildIntent(context, HomeWidgetReceiver.ACTION_INCREMENT, REQUEST_INCREMENT),
        )
        views.setOnClickPendingIntent(
            R.id.btn_decrement,
            buildIntent(context, HomeWidgetReceiver.ACTION_DECREMENT, REQUEST_DECREMENT),
        )
        manager.updateAppWidget(widgetId, views)
    }

    private fun buildIntent(context: Context, action: String, requestCode: Int) =
        PendingIntentCompat.getBroadcast(
            context,
            requestCode,
            Intent(context, HomeWidgetReceiver::class.java).apply { this.action = action },
            0,
            false,
        )

    companion object {
        private const val REQUEST_INCREMENT = 1001
        private const val REQUEST_DECREMENT = 1002
        private const val PREFS_NAME = "widget_prefs"
        private const val KEY_COUNTER = "counter"
    }
}

// ─── Receiver ────────────────────────────────────────────────────────────────

class HomeWidgetReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_INCREMENT -> changeCounter(context, delta = +1)
            ACTION_DECREMENT -> changeCounter(context, delta = -1)
        }
    }

    private fun changeCounter(context: Context, delta: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val newValue = prefs.getInt(KEY_COUNTER, 0) + delta
        prefs.edit().putInt(KEY_COUNTER, newValue).apply()

        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, HomeWidgetProvider::class.java))
        val views = RemoteViews(context.packageName, R.layout.widget_home)
        views.setTextViewText(R.id.tv_counter, newValue.toString())
        manager.updateAppWidget(ids, views)

        context.sendBroadcast(
            Intent(OverlayService.ACTION_REFRESH).setPackage(context.packageName)
        )
    }

    companion object {
        const val ACTION_INCREMENT = "com.cleanstart.akillisletme.home_widget.ACTION_INCREMENT"
        const val ACTION_DECREMENT = "com.cleanstart.akillisletme.home_widget.ACTION_DECREMENT"
        private const val PREFS_NAME = "widget_prefs"
        private const val KEY_COUNTER = "counter"
    }
}
