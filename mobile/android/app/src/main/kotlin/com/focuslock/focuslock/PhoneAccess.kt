package com.focuslock.focuslock

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.telecom.TelecomManager

/** Aggregate Telecom state includes ringing and calls on secondary SIMs. No numbers are read. */
object PhoneAccess {
    var foregroundPackage: String? = null
    fun permitted(c: Context) = c.checkSelfPermission(Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED
    fun inCall(c: Context): Boolean = try {
        if (c.checkSelfPermission(Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) true
        else c.getSystemService(TelecomManager::class.java).isInCall
    } catch (_: SecurityException) { true
    } catch (_: Exception) { true } // Fail open if the phone state cannot be read.

    fun isEmergencyPackage(pkg: String): Boolean = pkg == "com.android.emergency"

    fun yielding(c: Context): Boolean = inCall(c) ||
        (foregroundPackage?.let { isEmergencyPackage(it) } == true)
}
