package com.cleanstart.akillisletme.overlay

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.RemoteViews
import android.widget.TextView
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.cleanstart.akillisletme.R
import com.cleanstart.akillisletme.home_widget.HomeWidgetProvider

class OverlayService : Service() {

    private lateinit var windowManager: WindowManager
    private var overlayView: View? = null

    private val counterRefreshReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            refreshCounter()
        }
    }

    override fun onCreate() {
        super.onCreate()
        ContextCompat.registerReceiver(
            this,
            counterRefreshReceiver,
            IntentFilter(ACTION_REFRESH),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (overlayView == null) showOverlay()
        return START_STICKY
    }

    override fun onDestroy() {
        unregisterReceiver(counterRefreshReceiver)
        removeOverlay()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // --- Overlay ---

    private fun showOverlay() {
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        overlayView = LayoutInflater.from(this).inflate(R.layout.overlay_window, null)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 24.dp
            y = 160.dp
        }

        windowManager.addView(overlayView, params)
        bindViews()
        setupDrag(params)
    }

    private fun bindViews() {
        val view = overlayView ?: return
        refreshCounter()
        view.findViewById<View>(R.id.btn_overlay_close).setOnClickListener { stopSelf() }
        view.findViewById<View>(R.id.btn_overlay_open).setOnClickListener { openApp() }
        view.findViewById<View>(R.id.btn_overlay_increment).setOnClickListener { changeCounter(+1) }
        view.findViewById<View>(R.id.btn_overlay_decrement).setOnClickListener { changeCounter(-1) }
    }

    private fun changeCounter(delta: Int) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val newValue = prefs.getInt(KEY_COUNTER, 0) + delta
        prefs.edit().putInt(KEY_COUNTER, newValue).apply()
        refreshCounter()
        updateHomeWidget(newValue)
    }

    private fun refreshCounter() {
        val count = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).getInt(KEY_COUNTER, 0)
        overlayView?.findViewById<TextView>(R.id.tv_overlay_counter)?.text = count.toString()
    }

    private fun updateHomeWidget(counter: Int) {
        val manager = AppWidgetManager.getInstance(this)
        val ids = manager.getAppWidgetIds(ComponentName(this, HomeWidgetProvider::class.java))
        if (ids.isEmpty()) return
        val views = RemoteViews(packageName, R.layout.widget_home)
        views.setTextViewText(R.id.tv_counter, counter.toString())
        manager.updateAppWidget(ids, views)
    }

    private fun openApp() {
        val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        intent?.let { startActivity(it) }
    }

    private fun removeOverlay() {
        overlayView?.let { windowManager.removeView(it) }
        overlayView = null
    }

    // --- Drag ---

    private fun setupDrag(params: WindowManager.LayoutParams) {
        val view = overlayView ?: return
        var isDragging = false
        var startX = 0; var startY = 0
        var startTouchX = 0f; var startTouchY = 0f

        view.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    isDragging = false
                    startX = params.x; startY = params.y
                    startTouchX = event.rawX; startTouchY = event.rawY
                    false
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - startTouchX
                    val dy = event.rawY - startTouchY
                    if (!isDragging && (kotlin.math.abs(dx) > 8 || kotlin.math.abs(dy) > 8)) {
                        isDragging = true
                    }
                    if (isDragging) {
                        params.x = startX + dx.toInt()
                        params.y = startY + dy.toInt()
                        windowManager.updateViewLayout(view, params)
                    }
                    isDragging
                }
                else -> false
            }
        }
    }

    // --- Notification ---

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "Yüzen Pencere", NotificationManager.IMPORTANCE_MIN)
                .apply { setShowBadge(false) }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun buildNotification() =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Uygulama arka planda çalışıyor")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setSilent(true)
            .build()

    private val Int.dp: Int get() = (this * resources.displayMetrics.density).toInt()

    companion object {
        const val ACTION_REFRESH = "com.cleanstart.akillisletme.overlay.ACTION_REFRESH"
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "overlay_channel"
        private const val PREFS_NAME = "widget_prefs"
        private const val KEY_COUNTER = "counter"
    }
}
