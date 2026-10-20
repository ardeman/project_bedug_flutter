import 'package:adhan/adhan.dart';

import 'notification_preferences.dart';

class PrayerNotification {
  final int id;
  final Prayer prayer;
  final DateTime time;
  final bool isReminder;

  const PrayerNotification(
    this.id,
    this.prayer,
    this.time, {
    this.isReminder = false,
  });
}

/// Six days × five prayers × two alerts stays below Apple's 64-alert limit.
/// Each date is calculated separately; prayer times must not repeat daily.
List<PrayerNotification> buildNotificationSchedule(
  PrayerTimes times,
  NotificationPreferences preferences,
  DateTime now,
) {
  if (!preferences.enabled) return const [];
  final result = <PrayerNotification>[];
  for (var day = 0; day < 6; day++) {
    final date = DateTime(now.year, now.month, now.day + day);
    final daily = PrayerTimes(
      times.coordinates,
      DateComponents.from(date),
      times.calculationParameters,
    );
    for (final (index, prayer) in notificationPrayers.indexed) {
      if (!preferences.includes(prayer)) continue;
      final time = daily.timeForPrayer(prayer);
      if (time == null) continue;
      final id = day * 10 + index;
      if (time.isAfter(now)) {
        result.add(PrayerNotification(id, prayer, time));
      }
      if (preferences.reminderMinutes > 0) {
        final reminder = time.subtract(
          Duration(minutes: preferences.reminderMinutes),
        );
        if (reminder.isAfter(now)) {
          result.add(
            PrayerNotification(id + 5, prayer, reminder, isReminder: true),
          );
        }
      }
    }
  }
  result.sort((a, b) => a.time.compareTo(b.time));
  return result;
}
