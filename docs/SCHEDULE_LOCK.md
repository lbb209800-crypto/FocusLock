# Scheduled focus lock

The default Flutter entry point now opens a local schedule app. No Firebase
configuration, backend server, or AI API is required. Existing AI/auth source
files remain as legacy code and are not in the current navigation.

## Try it on this Windows workspace

From `mobile/`:

```powershell
$env:PUB_CACHE = "$PWD\..\.tools\pub-cache"
..\.tools\flutter\bin\flutter.bat run -d chrome --web-port 8084
```

Enter a title, choose a date/time for a fixed ten-minute lock. Schedules are
one-time appointments, not daily repeats. Past times and overlapping lock windows
are rejected. The fifteen-second scheduling test uses the ten-minute production
lock duration. The separate fifteen-second screen preview ends after fifteen
seconds and does not create an appointment.

The browser version only covers the app page while it is open. Browser tabs,
closing the browser, and other applications cannot be blocked. Background tabs
may be throttled. The countdown derives from the original deadline, so reload
does not grant a fresh ten minutes.

## Android implementation

Android 8+ native code uses `AlarmManager.setExactAndAllowWhileIdle`, a foreground
service and a touch-consuming `TYPE_APPLICATION_OVERLAY` window. The schedule
time, title and countdown appear over ordinary app windows. There is no dismiss
button. Back events received by the overlay are consumed; the overlay removes
itself at its deadline. The deadline also uses elapsed time while the service is
alive. The alarm does not depend on a Flutter timer or the Flutter app staying
open. App and native alarm records are stored locally.

Install Android SDK/Java, connect an Android device with USB debugging, then run
`flutter run -d <device-id>` from `mobile/`. In the app, explicitly grant
**Display over other apps** and **Alarms & reminders**; allow notifications to see
the ongoing service. Register a fifteen-second test and switch to another app.
The overlay should appear after fifteen seconds and remain for ten minutes.
Check normal registration, cancellation, reboot, app restart, missing permissions,
and automatic expiry on a physical device before relying on this feature.

Future alarms are restored on boot, package update and permission grant. Past
appointments are not replayed after boot. Overlapping locks are rejected in the
UI. Changing the language affects newly registered native lock screens; existing
appointments retain their registration language.

This is an app overlay, not kiosk/device-owner mode or the Android system
keyguard. System navigation, notification shade, emergency calls, uninstall,
force stop and permission revocation remain under OS/user control. Some apps
can suppress overlays; manufacturer power management can affect execution.
It cannot guarantee blocking everything the phone is doing. iOS device-wide
blocking is not implemented.

## Verification in this workspace

Four Flutter tests cover deadline boundaries, local persistence/deletion, title
registration/preview/language, and scheduled activation/expiry after a reload.
The new Dart source passed type/error analysis. Android SDK and an Android device
were unavailable here, so native Kotlin/APK compilation and real overlay behavior
have **not** been verified. The Android code is a first implementation, not a
tested phone build.

Official references:
- https://developer.android.com/develop/background-work/services/alarms
- https://developer.android.com/reference/android/view/WindowManager.LayoutParams#TYPE_APPLICATION_OVERLAY
- https://developer.android.com/develop/background-work/services/fgs/service-types#special-use
