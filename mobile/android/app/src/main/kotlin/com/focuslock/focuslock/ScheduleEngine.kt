package com.focuslock.focuslock

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import org.json.JSONObject

object ScheduleEngine {
    private fun prefs(c: Context) = c.getSharedPreferences("focus_native", Context.MODE_PRIVATE)
    fun alarm(c: Context) = c.getSystemService(AlarmManager::class.java)
    fun allowed(c: Context) = Build.VERSION.SDK_INT < 31 || alarm(c).canScheduleExactAlarms()
    private fun pending(c: Context, id: String): PendingIntent = PendingIntent.getBroadcast(c, 0,
        Intent(c, ScheduleReceiver::class.java).setData(Uri.parse("focuslock://schedule/$id")).putExtra("id", id),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    fun register(c: Context, item: JSONObject) {
        require(allowed(c)) { "Exact alarm permission required" }
        require(android.provider.Settings.canDrawOverlays(c)) { "Overlay permission required" }
        require(PhoneAccess.permitted(c)) { "Phone state permission required" }
        require(QuietMode.allowed(c)) { "Android 10+ and Do Not Disturb access required" }
        require(AppGuardService.connected) { "Enable FocusLock app blocking in Accessibility Settings" }
        require(c.getSystemService(android.app.NotificationManager::class.java).areNotificationsEnabled()) { "Notification permission required" }
        require(item.getString("title").isNotBlank() && item.getString("title").length <= 100)
        require(item.getInt("minutes") == 10)
        require(item.getLong("at") > System.currentTimeMillis())
        val id = item.getString("id")
        for ((savedId, value) in prefs(c).all) {
            if (savedId == id) continue
            val saved = JSONObject(value as String)
            require(item.getLong("at") >= LockSession.end(saved) || saved.getLong("at") >= LockSession.end(item)) {
                "Lock overlaps another schedule"
            }
        }
        // Check/create the inactive owned rule now, not for the first time at lock start.
        QuietMode.prepare(c)
        check(prefs(c).edit().putString(id, item.toString()).commit())
        try { arm(c, item) } catch (e: Exception) { prefs(c).edit().remove(id).commit(); throw e }
    }
    private fun arm(c: Context, item: JSONObject) {
        alarm(c).setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, item.getLong("at"), pending(c, item.getString("id")))
    }
    fun cancel(c: Context, id: String) {
        alarm(c).cancel(pending(c, id))
        check(prefs(c).edit().remove(id).commit())
        if (LockSession.active(c)?.optString("id") == id) {
            LockSession.finish(c)
            c.stopService(Intent(c, LockService::class.java))
        }
    }
    fun find(c: Context, id: String): JSONObject? = prefs(c).getString(id, null)?.let { JSONObject(it) }
    fun restore(c: Context) {
        if (!allowed(c)) return
        for ((_, value) in prefs(c).all) {
            try {
                val item = JSONObject(value as String)
                if (item.getLong("at") > System.currentTimeMillis()) arm(c, item)
                // Past schedules are never replayed as new full-duration locks.
            } catch (_: Exception) { }
        }
    }
}

class ScheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra("id") ?: return
        val item = ScheduleEngine.find(context, id) ?: return
        val end = item.getLong("at") + item.getInt("minutes") * 60000L
        if (end <= System.currentTimeMillis()) return
        if (!android.provider.Settings.canDrawOverlays(context)) return
        val service = Intent(context, LockService::class.java).putExtra("item", item.toString())
        try { context.startForegroundService(service) } catch (e: Exception) {
            android.util.Log.e("FocusLock", "Could not start scheduled lock", e)
        }
    }
}

class RestoreReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Boot cannot start special-use foreground services on recent Android versions.
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) LockSession.finish(context)
        else LockSession.recover(context)
        ScheduleEngine.restore(context)
    }
}
