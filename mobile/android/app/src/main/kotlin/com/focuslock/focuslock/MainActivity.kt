package com.focuslock.focuslock

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ScheduleEngine.restore(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "focuslock/phone_lock").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "permissions" -> result.success(mapOf(
                        "overlay" to Settings.canDrawOverlays(this),
                        "exact" to ScheduleEngine.allowed(this),
                        "notifications" to getSystemService(NotificationManager::class.java).areNotificationsEnabled()
                    ))
                    "request" -> {
                        when (call.arguments as String) {
                            "overlay" -> startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
                            "exact" -> if (Build.VERSION.SDK_INT >= 31) startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName")))
                            "notifications" -> if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED)
                                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 12)
                        }
                        result.success(null)
                    }
                    "schedule" -> { ScheduleEngine.register(this, JSONObject(call.arguments as Map<*, *>)); result.success(null) }
                    "cancel" -> { ScheduleEngine.cancel(this, call.arguments as String); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) { result.error("PHONE_LOCK_ERROR", e.message, null) }
        }
    }
}
