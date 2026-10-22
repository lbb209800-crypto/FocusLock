package com.focuslock.focuslock

/** Pure decisions shared by the service and app guard, testable without a device. */
object LockRules {
    fun remaining(at: Long, minutes: Int, now: Long): Long = at + minutes * 60000L - now

    fun redirect(active: Boolean, yieldingToPhone: Boolean, phoneWindow: Boolean,
                 systemWindow: Boolean, keyguard: Boolean): Boolean =
        active && !yieldingToPhone && !phoneWindow && !systemWindow && !keyguard
}
