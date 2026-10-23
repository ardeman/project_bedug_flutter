import 'package:adhan/adhan.dart';

import 'extra_prayer_times.dart';
import 'notification_preferences.dart';

class PrayerNotification {
  final int id;
  final PrayerAlert alert;
  final DateTime time;
  final bool isReminder;

  const PrayerNotification(
    this.id,
    this.alert,
    this.time, {
    this.isReminder = false,
  });
}

/// Apple keeps only the 64 soonest pending alerts per app.
const maxScheduledNotifications = 64;

/// Up to six days of alerts, the soonest first, capped at Apple's limit.
/// Each date is calculated separately; prayer times must not repeat daily.
List<PrayerNotification> buildNotificationSchedule(
  PrayerTimes times,
  NotificationPreferences preferences,
  DateTime now,
) {
  if (!preferences.enabled) return const [];
  final alerts = PrayerAlert.values;
  final result = <PrayerNotification>[];
  for (var day = 0; day < 6; day++) {
    final date = DateTime(now.year, now.month, now.day + day);
    final daily = PrayerTimes(
      times.coordinates,
      DateComponents.from(date),
      times.calculationParameters,
    );
    final extra = ExtraPrayerTimes(daily);
    for (final alert in alerts) {
      if (!preferences.includes(alert)) continue;
      final time = switch (alert) {
        PrayerAlert.lastThirdOfNight => extra.lastThirdOfNight,
        PrayerAlert.imsak => extra.imsak,
        PrayerAlert.fajr => daily.fajr,
        PrayerAlert.sunrise => daily.sunrise,
        PrayerAlert.dhuha => extra.dhuha,
        PrayerAlert.dhuhr => daily.dhuhr,
        PrayerAlert.asr => daily.asr,
        PrayerAlert.maghrib => daily.maghrib,
        PrayerAlert.isha => daily.isha,
      };
      // Reminders take the IDs after each day's on-time alerts.
      final id = day * alerts.length * 2 + alert.index;
      if (time.isAfter(now)) {
        result.add(PrayerNotification(id, alert, time));
      }
      if (preferences.reminderMinutes > 0) {
        final reminder = time.subtract(
          Duration(minutes: preferences.reminderMinutes),
        );
        if (reminder.isAfter(now)) {
          result.add(
            PrayerNotification(
              id + alerts.length,
              alert,
              reminder,
              isReminder: true,
            ),
          );
        }
      }
    }
  }
  result.sort((a, b) => a.time.compareTo(b.time));
  return result.take(maxScheduledNotifications).toList();
}
