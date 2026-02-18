import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:adhan/adhan.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin  = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linux = LinuxInitializationSettings(defaultActionName: 'Buka');

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS:     darwin,
        macOS:   darwin,
        linux:   linux,
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> schedulePrayerNotifications(PrayerTimes times) async {
    await _plugin.cancelAll();

    final prayers = <int, (String, String, DateTime?)>{
      0: ('🌙 Subuh',   'Waktu Subuh telah tiba',   times.fajr),
      1: ('☀️ Dzuhur',  'Waktu Dzuhur telah tiba',  times.dhuhr),
      2: ('🌤 Ashar',   'Waktu Ashar telah tiba',   times.asr),
      3: ('🌅 Maghrib', 'Waktu Maghrib telah tiba', times.maghrib),
      4: ('🌙 Isya',    'Waktu Isya telah tiba',    times.isha),
    };

    for (final e in prayers.entries) {
      final (title, body, dt) = e.value;
      if (dt == null || dt.isBefore(DateTime.now())) continue;

      // v20: zonedSchedule pakai named params, title & body opsional
      await _plugin.zonedSchedule(
        id:                  e.key,
        scheduledDate:       tz.TZDateTime.from(dt, tz.local),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title:               title,
        body:                body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'bedug_channel',
            'Waktu Sholat',
            channelDescription: 'Pengingat azan untuk sholat harian',
            importance: Importance.high,
            priority:   Priority.high,
          ),
          iOS:   DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
          linux: LinuxNotificationDetails(),
        ),
      );
    }
  }
}