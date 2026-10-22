package com.focuslock.focuslock

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONObject

object LockSession {
    private fun prefs(c: Context) = c.getSharedPreferences("focus_active", Context.MODE_PRIVATE)
    fun end(item: JSONObject) = item.getLong("at") + item.getInt("minutes") * 60000L
    fun active(c: Context): JSONObject? = try {
        prefs(c).getString("item", null)?.let { JSONObject(it) }
            ?.takeIf { it.getLong("at") <= System.currentTimeMillis() && end(it) > System.currentTimeMillis() }
    } catch (_: Exception) { null }

    private fun expiry(c: Context) = PendingIntent.getBroadcast(c, 0,
        Intent(c, LockExpiryReceiver::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

    fun begin(c: Context, item: JSONObject) {
        check(prefs(c).edit().putString("item", item.toString()).commit())
        try {
            // Independent cleanup survives service/process loss while the device is running.
            c.getSystemService(AlarmManager::class.java).setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP, end(item), expiry(c))
            QuietMode.start(c)
        } catch (e: Exception) { finish(c); throw e }
    }

    fun finish(c: Context) {
        QuietMode.stop(c)
        prefs(c).edit().remove("item").commit()
        c.getSystemService(AlarmManager::class.java).cancel(expiry(c))
        PhoneAccess.dialerUntil = 0
    }

    fun recover(c: Context) {
        val item = active(c)
        if (item == null) { finish(c); return }
        try { c.startForegroundService(Intent(c, LockService::class.java).putExtra("item", item.toString())) }
        catch (e: Exception) {
            android.util.Log.w("FocusLock", "Could not resume lock", e)
            finish(c)
        }
    }
}

class LockExpiryReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // A stale alarm must not end a later lock.
        if (LockSession.active(context) != null) return
        LockSession.finish(context)
        context.stopService(Intent(context, LockService::class.java))
    }
}
