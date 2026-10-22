package com.focuslock.focuslock

import android.accessibilityservice.AccessibilityService
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent

/** Only package/window transitions are observed. No screen text, gestures or keystrokes. */
class AppGuardService : AccessibilityService() {
    companion object { var connected = false; private set }
    private var lastRedirect = 0L
    override fun onServiceConnected() { connected = true }
    override fun onInterrupt() { connected = false }
    override fun onDestroy() { connected = false; super.onDestroy() }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        connected = true
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        // System permission, lock screen and emergency UI remain under user/OS control.
        if (pkg == "com.android.systemui") return
        if (pkg == packageName && event.className?.toString()?.startsWith(packageName) != true) return
        PhoneAccess.foregroundPackage = pkg
        if (pkg == packageName || pkg == "com.android.settings") return
        if (!LockRules.redirect(LockSession.active(this) != null, PhoneAccess.yielding(this),
            PhoneAccess.isEmergencyPackage(pkg), false,
            getSystemService(KeyguardManager::class.java).isKeyguardLocked)) return
        val now = SystemClock.elapsedRealtime()
        if (now - lastRedirect < 800) return
        lastRedirect = now
        try {
            startActivity(Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP))
        } catch (e: Exception) { android.util.Log.w("FocusLock", "App redirect failed", e) }
    }
}
