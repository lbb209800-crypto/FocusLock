package com.focuslock.focuslock

import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.telephony.TelephonyManager
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
    private var item: JSONObject? = null
    private var observingPhone = false
    private var wasInCall = false
    private val phoneReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            // Yield immediately on ringing/off-hook; polling also covers secondary SIM calls.
            if (intent.getStringExtra(TelephonyManager.EXTRA_STATE) != TelephonyManager.EXTRA_STATE_IDLE) hideOverlay()
            handler.removeCallbacks(tick)
            handler.post(tick)
        }
    }
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val next = try {
            intent?.getStringExtra("item")?.let { JSONObject(it) } ?: LockSession.active(this)
        } catch (_: Exception) { null }
        // Enter foreground promptly, including expired/redelivered intents.
        val korean = next?.optString("language", "ko") != "en"
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel("focus_lock", "FocusLock", NotificationManager.IMPORTANCE_LOW))
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        startForeground(20, Notification.Builder(this, "focus_lock")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(if (korean) "일정 잠금 진행 중" else "Schedule lock active")
            .setContentText(next?.optString("title") ?: "FocusLock").setContentIntent(open).setOngoing(true).build())
        if (next == null || LockSession.end(next) <= System.currentTimeMillis() ||
            next.getLong("at") > System.currentTimeMillis() || !ready()) {
            stopSelf(); return START_NOT_STICKY
        }
        // Redelivery must not extend the original monotonic deadline.
        if (item?.getString("id") == next.getString("id")) return START_STICKY
        try {
            hideOverlay()
            item = next
            deadline = SystemClock.elapsedRealtime() + LockRules.remaining(
                next.getLong("at"), next.getInt("minutes"), System.currentTimeMillis())
            LockSession.begin(this, next)
            if (!observingPhone) {
                val filter = IntentFilter(TelephonyManager.ACTION_PHONE_STATE_CHANGED)
                if (Build.VERSION.SDK_INT >= 33) registerReceiver(phoneReceiver, filter, RECEIVER_EXPORTED)
                else registerReceiver(phoneReceiver, filter)
                observingPhone = true
            }
            handler.removeCallbacks(tick)
            handler.post(tick)
        } catch (e: Exception) {
            android.util.Log.e("FocusLock", "Could not start lock", e)
            stopSelf(); return START_NOT_STICKY
        }
        return START_STICKY
    }

    private fun ready() = android.provider.Settings.canDrawOverlays(this) &&
        PhoneAccess.permitted(this) && QuietMode.allowed(this) && ScheduleEngine.allowed(this) && AppGuardService.connected

    private fun showOverlay() {
        if (overlay != null) return
        val current = item ?: return
        val korean = current.optString("language", "ko") != "en"
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
        label(SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(current.getLong("at"))) +
            if (korean) " 일정" else " schedule", 18f)
        label(current.getString("title"), 30f)
        timer = label("", 64f)
        label(if (korean) "전화가 오면 통화할 수 있어요. 종료 시각은 유지돼요." else
            "Calls remain available. The original end time stays the same.", 16f)
        val params = WindowManager.LayoutParams(WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            PixelFormat.OPAQUE)
        getSystemService(WindowManager::class.java).addView(layout, params)
        overlay = layout
        layout.requestFocus()
    }

    private fun hideOverlay() {
        overlay?.let {
            try { getSystemService(WindowManager::class.java).removeView(it) }
            catch (e: Exception) { android.util.Log.w("FocusLock", "Overlay removal failed", e) }
        }
        overlay = null; timer = null
    }

    private val tick = object : Runnable {
        override fun run() {
            val remaining = deadline - SystemClock.elapsedRealtime()
            if (remaining <= 0 || !ready()) { stopSelf(); return }
            val calling = PhoneAccess.inCall(this@LockService)
            if (wasInCall && !calling) {
                PhoneAccess.foregroundPackage = null
            }
            wasInCall = calling
            val systemScreen = getSystemService(KeyguardManager::class.java).isKeyguardLocked ||
                PhoneAccess.foregroundPackage == "com.android.settings"
            if (PhoneAccess.yielding(this@LockService) || systemScreen) hideOverlay()
            else try { showOverlay() } catch (e: Exception) {
                android.util.Log.e("FocusLock", "Overlay failed", e); stopSelf(); return
            }
            val seconds = (remaining + 999) / 1000
            timer?.text = String.format(Locale.ROOT, "%02d:%02d", seconds / 60, seconds % 60)
            handler.postDelayed(this, 250)
        }
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        if (observingPhone) unregisterReceiver(phoneReceiver)
        hideOverlay()
        LockSession.finish(this)
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
}
