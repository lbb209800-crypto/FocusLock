package com.focuslock.focuslock

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.SystemClock
import android.telecom.TelecomManager

/** Aggregate Telecom state includes ringing and calls on secondary SIMs. No numbers are read. */
object PhoneAccess {
    var dialerUntil = 0L
    var foregroundPackage: String? = null
    fun permitted(c: Context) = c.checkSelfPermission(Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED
    fun inCall(c: Context): Boolean = try {
        if (c.checkSelfPermission(Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) true
        else c.getSystemService(TelecomManager::class.java).isInCall
    } catch (_: SecurityException) { true
    } catch (_: Exception) { true } // Fail open if the phone state cannot be read.

    fun isPhonePackage(c: Context, pkg: String): Boolean =
        pkg == c.getSystemService(TelecomManager::class.java).defaultDialerPackage ||
            pkg == "com.android.server.telecom" || pkg == "com.android.emergency" ||
            pkg == "com.android.phone"

    fun yielding(c: Context): Boolean = inCall(c) ||
        (foregroundPackage?.let { isPhonePackage(c, it) } == true) ||
        (SystemClock.elapsedRealtime() < dialerUntil &&
            (foregroundPackage == null || isPhonePackage(c, foregroundPackage!!)))

    fun openDialer(c: Context) {
        foregroundPackage = null
        dialerUntil = SystemClock.elapsedRealtime() + 60000
        try { c.startActivity(Intent(Intent.ACTION_DIAL).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
        catch (e: Exception) { dialerUntil = 0; throw e }
    }
}
