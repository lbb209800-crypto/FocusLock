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

Android native code uses `AlarmManager.setExactAndAllowWhileIdle`, a foreground
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
New scheduling with notification restrictions requires Android 10+ and all six
permissions shown in the app: overlay, exact alarms, notifications, phone state,
Do Not Disturb access, and the FocusLock accessibility service. Android 8/9 can
install the app but cannot register this combined lock flow.
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

Six Flutter tests cover deadline boundaries, local persistence/deletion, title
registration/preview/language, activation/expiry after reload, required permission
readiness, and Android registration being withheld until permissions are granted.
Native unit tests cover the deadline during calls and guard exemptions. Build and
test results for the current change are recorded in HANDOFF.md. Physical-device
overlay, telephony and notification behavior remains **unverified**.

## App switching, calls and notifications

- `AppGuardService` listens only to window/package transitions. It returns ordinary
  apps/launchers to FocusLock while a lock is active. It cannot read the view tree,
  typed text or notification contents. The app explains this before opening the
  Android accessibility settings; enabling it is the user's choice.
- Phone/Telecom/emergency UI, Android Settings, keyguard and System UI remain
  available. This is a stronger deterrent, not kiosk mode or a guarantee against
  force stop, uninstall, navigation, permission revocation or OEM restrictions.
- `TelecomManager.isInCall` checks aggregate ringing/ongoing calls, including
  secondary SIMs. A phone-state receiver yields immediately; the service also
  polls. Unknown/unreadable call state yields rather than obstructing the phone.
  No phone numbers, contacts, call log or audio are read.
- The overlay hides during a call and resumes after it, using the original
  deadline. A call lasting beyond the deadline finishes the lock. Phone UI can
  also be opened with the overlay's phone button; leaving the phone returns to
  app blocking. Phone/Settings exemptions are deliberate escape paths.
- On Android 10+, `QuietMode` owns one `AutomaticZenRule` with a `ZenPolicy` that
  suppresses ordinary notification sound/vibration/visual effects and allows all
  calls. Alarms/media remain allowed. It does not delete notifications or change
  global DND settings. Existing stricter user rules can still silence calls, and
  DND-bypassing/system alerts may remain visible/audible. Modified/disabled rules
  are respected. There is no notification-listener/cancellation workaround.
- Deadline expiry, normal service teardown, cancellation, and boot recovery
  release only FocusLock's rule. An independent exact expiry alarm cleans up even
  after process death. Force stop can prevent alarm delivery: if needed disable
  the FocusLock rule in Android's DND settings or reopen the app to recover.

## Required physical-device checks

1. Grant every permission; deny/revoke each individually and confirm registration
   is refused or an active overlay stops without blocking system controls.
2. Schedule a test, switch to an ordinary app, press Home/Recents and open the
   notification shade. Record which transitions are actually prevented per device.
3. Receive, reject and answer a real call during a lock, including a secondary SIM.
   Test a call already ringing at lock start, a call longer than the remaining lock,
   and outbound calling. Verify emergency dialer access without placing a test
   emergency call. Check overlay removal and original-deadline resumption.
4. Send real ordinary notifications with sound/vibration enabled before the lock.
   Check banner, lock screen and shade behavior; compare with DND bypass enabled.
5. Test an existing user DND rule, stricter call policy, silent mode, user edits to
   the FocusLock rule, expiry while on a call, process kill, reboot and force stop.
   Confirm the user's settings persist after FocusLock ends.
6. Repeat on Android 10 and Android 15+ and the target manufacturer's phone.

Official references:
- https://developer.android.com/develop/background-work/services/alarms
- https://developer.android.com/reference/android/view/WindowManager.LayoutParams#TYPE_APPLICATION_OVERLAY
- https://developer.android.com/develop/background-work/services/fgs/service-types#special-use
- https://developer.android.com/reference/android/accessibilityservice/AccessibilityService
- https://developer.android.com/reference/android/telecom/TelecomManager#isInCall()
- https://developer.android.com/reference/android/app/AutomaticZenRule
- https://developer.android.com/reference/android/service/notification/ZenPolicy.Builder
