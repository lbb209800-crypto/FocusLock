package com.focuslock.focuslock

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class LockService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var overlay: View? = null
    private var deadline = 0L
    private var timer: TextView? = null
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val raw = intent?.getStringExtra("item") ?: getSharedPreferences("focus_active", MODE_PRIVATE).getString("item", null)
        if (raw == null) { stopSelf(); return START_NOT_STICKY }
        val item = JSONObject(raw)
        val remaining = item.getLong("at") + item.getInt("minutes") * 60000L - System.currentTimeMillis()
        val korean = item.optString("language", "ko") == "ko"
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel("focus_lock", "FocusLock", NotificationManager.IMPORTANCE_LOW))
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val notification = Notification.Builder(this, "focus_lock").setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(if (korean) "일정 잠금 진행 중" else "Schedule lock active")
            .setContentText(item.getString("title")).setContentIntent(open).setOngoing(true).build()
        startForeground(20, notification)
        if (remaining <= 0 || !android.provider.Settings.canDrawOverlays(this)) { stopSelf(); return START_NOT_STICKY }
        // Preserve the original remaining time; never restart a full lock after process recreation.
        getSharedPreferences("focus_active", MODE_PRIVATE).edit().putString("item", raw).apply()
        if (overlay != null) return START_STICKY
        deadline = SystemClock.elapsedRealtime() + remaining
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER
            setPadding(32, 48, 32, 48); setBackgroundColor(Color.rgb(15, 23, 42))
            isFocusableInTouchMode = true
            setOnKeyListener { _, keyCode, _ -> keyCode == KeyEvent.KEYCODE_BACK }
        }
        fun label(value: String, size: Float): TextView = TextView(this).apply {
            text = value; textSize = size; setTextColor(Color.WHITE); gravity = Gravity.CENTER
            setPadding(0, 16, 0, 16); layout.addView(this)
        }
        label(if (korean) "일정 잠금" else "Schedule lock", 22f)
        label(SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(item.getLong("at"))) + if (korean) " 일정" else " schedule", 18f)
        label(item.getString("title"), 30f)
        timer = label("", 64f)
        label(if (korean) "시간이 끝나면 자동으로 해제돼요." else "Unlocks automatically when time is up.", 16f)
        val params = WindowManager.LayoutParams(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            PixelFormat.OPAQUE)
        try {
            getSystemService(WindowManager::class.java).addView(layout, params)
            overlay = layout; layout.requestFocus(); handler.post(tick)
        } catch (e: Exception) { android.util.Log.e("FocusLock", "Overlay failed", e); stopSelf() }
        return START_STICKY
    }
    private val tick = object : Runnable {
        override fun run() {
            val remaining = deadline - SystemClock.elapsedRealtime()
            if (remaining <= 0) { stopSelf(); return }
            val seconds = (remaining + 999) / 1000
            timer?.text = String.format(Locale.ROOT, "%02d:%02d", seconds / 60, seconds % 60)
            handler.postDelayed(this, 250)
        }
    }
    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        overlay?.let { getSystemService(WindowManager::class.java).removeView(it) }
        overlay = null
        getSharedPreferences("focus_active", MODE_PRIVATE).edit().remove("item").apply()
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
}
