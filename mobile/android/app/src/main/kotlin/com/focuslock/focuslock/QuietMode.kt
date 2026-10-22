package com.focuslock.focuslock

import android.app.AutomaticZenRule
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.net.Uri
import android.os.Build
import android.service.notification.Condition
import android.service.notification.ConditionProviderService
import android.service.notification.ZenPolicy

/** An app-owned rule: never overwrites the user's global DND policy/filter. */
object QuietMode {
    private val condition = Uri.parse("condition://com.focuslock.focuslock/lock")
    private fun prefs(c: Context) = c.getSharedPreferences("focus_quiet", Context.MODE_PRIVATE)
    fun supported() = Build.VERSION.SDK_INT >= 29
    fun allowed(c: Context) = supported() && c.getSystemService(NotificationManager::class.java).isNotificationPolicyAccessGranted

    fun prepare(c: Context): String {
        check(allowed(c)) { "Android 10+ and Do Not Disturb access required" }
        if (Build.VERSION.SDK_INT < 29) error("Android 10 or later required")
        val manager = c.getSystemService(NotificationManager::class.java)
        var id = prefs(c).getString("rule", null)
        val policy = ZenPolicy.Builder().disallowAllSounds()
            .allowCalls(ZenPolicy.PEOPLE_TYPE_ANYONE).allowRepeatCallers(true)
            .allowAlarms(true).allowMedia(true).hideAllVisualEffects().build()
        if (id == null || manager.getAutomaticZenRule(id) == null) {
            val rule = AutomaticZenRule("FocusLock", ComponentName(c, FocusConditionService::class.java),
                null, condition, policy, NotificationManager.INTERRUPTION_FILTER_PRIORITY, true)
            id = manager.addAutomaticZenRule(rule)
            // Save ownership before activating so crash recovery can release it.
            if (!prefs(c).edit().putString("rule", id).commit()) {
                manager.removeAutomaticZenRule(id)
                error("Could not save notification rule")
            }
        } else {
            val rule = manager.getAutomaticZenRule(id)!!
            check(rule.isEnabled) { "Enable the FocusLock Do Not Disturb rule in Settings" }
            // Respect user edits to a previously created rule; do not recreate disabled rules.
        }
        return checkNotNull(id)
    }

    fun start(c: Context) {
        val id = prepare(c)
        if (Build.VERSION.SDK_INT >= 29) c.getSystemService(NotificationManager::class.java)
            .setAutomaticZenRuleState(id, Condition(condition, "FocusLock", Condition.STATE_TRUE))
    }

    fun stop(c: Context) {
        if (Build.VERSION.SDK_INT < 29) return
        val id = prefs(c).getString("rule", null) ?: return
        try {
            val manager = c.getSystemService(NotificationManager::class.java)
            manager.setAutomaticZenRuleState(id, Condition(condition, "FocusLock", Condition.STATE_FALSE))
        } catch (e: Exception) { android.util.Log.w("FocusLock", "Could not release notification rule", e) }
    }
}

class FocusConditionService : ConditionProviderService() {
    override fun onConnected() {
        if (LockSession.active(this) == null) QuietMode.stop(this)
    }
    override fun onUnsubscribe(conditionId: Uri) { }
    override fun onSubscribe(conditionId: Uri) {
        // On reconnect the rule must reflect the deadline, never an old activation.
        notifyCondition(Condition(conditionId, "FocusLock",
            if (LockSession.active(this) != null) Condition.STATE_TRUE else Condition.STATE_FALSE))
    }
}
