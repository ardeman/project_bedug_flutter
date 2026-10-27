import '../utils/hijri_utils.dart';

import 'package:adhan/adhan.dart';

import '../../features/hijri_events/hijri_events.dart';
import 'extra_prayer_times.dart';
import 'notification_preferences.dart';

class PrayerNotification {
  final int id;
  final PrayerAlert alert;
  final DateTime time;
  final bool isReminder;

  /// Set on a dzikir reminder, whose [alert] is the prayer it follows.
  final DzikirReminder? dzikir;

  /// Set on an event reminder: the events of the next day, announced at
  /// Maghrib ([alert]) when their Hijri day begins.
  final List<HijriEvent>? events;

  const PrayerNotification(
    this.id,
    this.alert,
    this.time, {
    this.isReminder = false,
    this.dzikir,
    this.events,
  });
}

/// Apple keeps only the 64 soonest pending alerts per app.
const maxScheduledNotifications = 64;

/// Up to six days of alerts, the soonest first, capped at Apple's limit.
/// Each date is calculated separately; prayer times must not repeat daily.
/// Event reminders need [events], dated with [hijriReckoning].
List<PrayerNotification> buildNotificationSchedule(
  PrayerTimes times,
  NotificationPreferences preferences,
  DateTime now, {
  HijriEvents? events,
  HijriReckoning hijriReckoning = const HijriReckoning(),
}) {
  if (!preferences.enabled) return const [];
  final alerts = PrayerAlert.values;
  final result = <PrayerNotification>[];
  const days = 6;
  for (var day = 0; day < days; day++) {
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
      final minutes = preferences.reminderOf(alert);
      if (minutes > 0) {
        final reminder = time.subtract(Duration(minutes: minutes));
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
    for (final dzikir in DzikirReminder.values) {
      if (!preferences.includesDzikir(dzikir)) continue;
      final (alert, prayer) = switch (dzikir) {
        DzikirReminder.morning => (PrayerAlert.fajr, daily.fajr),
        DzikirReminder.evening => (PrayerAlert.asr, daily.asr),
      };
      final time = prayer.add(dzikirReminderDelay);
      if (!time.isAfter(now)) continue;
      // Dzikir IDs follow every day's prayer alerts and reminders.
      final id =
          days * alerts.length * 2 +
          day * DzikirReminder.values.length +
          dzikir.index;
      result.add(PrayerNotification(id, alert, time, dzikir: dzikir));
    }
    if (events != null && preferences.includesEvents) {
      // A run of days, such as the white days, is announced once, before
      // its first day.
      final today = events.on(date, hijriReckoning).toSet();
      final starting = [
        for (final event in events.on(
          DateTime(date.year, date.month, date.day + 1),
          hijriReckoning,
        ))
          if (!today.contains(event)) event,
      ];
      if (starting.isNotEmpty && daily.maghrib.isAfter(now)) {
        // Event IDs follow every day's dzikir reminders.
        final id =
            days * alerts.length * 2 +
            days * DzikirReminder.values.length +
            day;
        result.add(
          PrayerNotification(
            id,
            PrayerAlert.maghrib,
            daily.maghrib,
            events: starting,
          ),
        );
      }
    }
  }
  result.sort((a, b) => a.time.compareTo(b.time));
  return result.take(maxScheduledNotifications).toList();
}
