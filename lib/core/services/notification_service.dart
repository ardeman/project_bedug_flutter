import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:adhan/adhan.dart';
import '../../generated/l10n/app_localizations.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    final l10n = _resolveL10n();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final linux =
        LinuxInitializationSettings(defaultActionName: l10n.openAction);

    await _plugin.initialize(
      settings: InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        linux: linux,
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> schedulePrayerNotifications(PrayerTimes times) async {
    final l10n = _resolveL10n();
    await _plugin.cancelAll();

    final prayers = <int, (String, String, DateTime?)>{
      0: ('🌙 ${l10n.fajr}', l10n.notifSubuh, times.fajr),
      1: ('☀️ ${l10n.dhuhr}', l10n.notifDzuhur, times.dhuhr),
      2: ('🌤 ${l10n.asr}', l10n.notifAshar, times.asr),
      3: ('🌅 ${l10n.maghrib}', l10n.notifMaghrib, times.maghrib),
      4: ('🌙 ${l10n.isha}', l10n.notifIsya, times.isha),
    };

    for (final e in prayers.entries) {
      final (title, body, dt) = e.value;
      if (dt == null || dt.isBefore(DateTime.now())) continue;

      // v20: zonedSchedule pakai named params, title & body opsional
      await _plugin.zonedSchedule(
        id: e.key,
        scheduledDate: tz.TZDateTime.from(dt, tz.local),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'bedug_channel',
            l10n.notificationChannelName,
            channelDescription: l10n.notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
          linux: LinuxNotificationDetails(),
        ),
      );
    }
  }

  static AppLocalizations _resolveL10n() {
    final locale = PlatformDispatcher.instance.locale;
    try {
      return lookupAppLocalizations(locale);
    } catch (_) {
      return lookupAppLocalizations(const Locale('id'));
    }
  }
}
