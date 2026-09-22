package com.cleanstart.akillisletme

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.widget.RemoteViews
import com.cleanstart.akillisletme.home_widget.HomeWidgetProvider
import com.cleanstart.akillisletme.overlay.OverlayService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupOverlayChannel(flutterEngine)
        setupCounterChannel(flutterEngine)
    }

    override fun onStart() {
        super.onStart()
        stopService(Intent(this, OverlayService::class.java))
    }

    override fun onStop() {
        super.onStop()
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val overlayEnabled = prefs.getBoolean(KEY_OVERLAY_ENABLED, true)
        if (overlayEnabled && Settings.canDrawOverlays(this)) {
            startService(Intent(this, OverlayService::class.java))
        }
    }

    private fun setupOverlayChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                when (call.method) {
                    "isGranted" -> result.success(Settings.canDrawOverlays(this@MainActivity))
                    "request" -> {
                        startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
                        result.success(null)
                    }
                    "isEnabled" -> result.success(prefs.getBoolean(KEY_OVERLAY_ENABLED, true))
                    "setEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        prefs.edit().putBoolean(KEY_OVERLAY_ENABLED, enabled).apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun setupCounterChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COUNTER_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                when (call.method) {
                    "get" -> result.success(prefs.getInt(KEY_COUNTER, 0))
                    "increment" -> {
                        val v = prefs.getInt(KEY_COUNTER, 0) + 1
                        prefs.edit().putInt(KEY_COUNTER, v).apply()
                        updateHomeWidget(v)
                        result.success(v)
                    }
                    "decrement" -> {
                        val v = prefs.getInt(KEY_COUNTER, 0) - 1
                        prefs.edit().putInt(KEY_COUNTER, v).apply()
                        updateHomeWidget(v)
                        result.success(v)
                    }
                    "reset" -> {
                        prefs.edit().putInt(KEY_COUNTER, 0).apply()
                        updateHomeWidget(0)
                        result.success(0)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun updateHomeWidget(counter: Int) {
        val manager = AppWidgetManager.getInstance(this)
        val ids = manager.getAppWidgetIds(ComponentName(this, HomeWidgetProvider::class.java))
        if (ids.isEmpty()) return
        val views = RemoteViews(packageName, R.layout.widget_home)
        views.setTextViewText(R.id.tv_counter, counter.toString())
        manager.updateAppWidget(ids, views)
    }

    companion object {
        private const val OVERLAY_CHANNEL = "overlay_permission"
        private const val COUNTER_CHANNEL = "counter"
        private const val PREFS_NAME = "widget_prefs"
        private const val KEY_COUNTER = "counter"
        private const val KEY_OVERLAY_ENABLED = "overlay_enabled"
    }
}
