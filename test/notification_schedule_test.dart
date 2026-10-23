import 'package:adhan/adhan.dart';
import 'package:bedug/core/services/extra_prayer_times.dart';
import 'package:bedug/core/services/notification_preferences.dart';
import 'package:bedug/core/services/notification_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 20);
  final times = PrayerTimes(
    Coordinates(-6.2088, 106.8456),
    DateComponents.from(now),
    CalculationMethod.singapore.getParameters(),
  );

  test(
    'default alerts contain five prayers for each of six calculated days',
    () {
      final schedule = buildNotificationSchedule(
        times,
        const NotificationPreferences(),
        now,
      );
      expect(schedule, hasLength(30));
      expect(schedule.every((alert) => !alert.isReminder), isTrue);
      final tomorrow = PrayerTimes(
        times.coordinates,
        DateComponents(2026, 10, 21),
        times.calculationParameters,
      );
      expect(
        schedule.firstWhere((alert) => alert.id == 20).time,
        tomorrow.fajr,
      );
    },
  );

  test('disabled prayer removes both alerts and master switch removes all', () {
    const preferences = NotificationPreferences(
      alerts: {
        PrayerAlert.dhuhr,
        PrayerAlert.asr,
        PrayerAlert.maghrib,
        PrayerAlert.isha,
      },
      reminderMinutes: 10,
    );
    final schedule = buildNotificationSchedule(times, preferences, now);
    expect(schedule, hasLength(48));
    expect(schedule.any((alert) => alert.alert == PrayerAlert.fajr), isFalse);
    expect(
      buildNotificationSchedule(
        times,
        preferences.copyWith(enabled: false),
        now,
      ),
      isEmpty,
    );
  });

  test(
    'reminders are additional alerts, with unique IDs below Apple limit',
    () {
      final schedule = buildNotificationSchedule(
        times,
        const NotificationPreferences(reminderMinutes: 30),
        now,
      );
      expect(schedule, hasLength(60));
      expect(schedule.map((alert) => alert.id).toSet(), hasLength(60));
      for (final reminder in schedule.where((alert) => alert.isReminder)) {
        final prayer = schedule.singleWhere(
          (alert) => alert.id == reminder.id - PrayerAlert.values.length,
        );
        expect(
          prayer.time.difference(reminder.time),
          const Duration(minutes: 30),
        );
      }
    },
  );

  test('past reminders are omitted without dropping the upcoming prayer', () {
    final current = times.dhuhr.subtract(const Duration(minutes: 2));
    final schedule = buildNotificationSchedule(
      times,
      const NotificationPreferences(reminderMinutes: 10),
      current,
    );
    expect(schedule.every((alert) => alert.time.isAfter(current)), isTrue);
    expect(schedule.any((alert) => alert.id == 5), isTrue);
    expect(schedule.any((alert) => alert.id == 14), isFalse);
  });

  test('every timeline time can alert, capped at the soonest 64', () {
    final schedule = buildNotificationSchedule(
      times,
      NotificationPreferences(
        alerts: PrayerAlert.values.toSet(),
        reminderMinutes: 10,
      ),
      now,
    );
    expect(schedule, hasLength(maxScheduledNotifications));
    expect(schedule.map((alert) => alert.id).toSet(), hasLength(64));
    final extra = ExtraPrayerTimes(times);
    final today = {
      for (final alert in schedule.where((a) => a.id < 9)) alert.alert: alert,
    };
    expect(today[PrayerAlert.lastThirdOfNight]!.time, extra.lastThirdOfNight);
    expect(today[PrayerAlert.imsak]!.time, extra.imsak);
    expect(today[PrayerAlert.sunrise]!.time, times.sunrise);
    expect(today[PrayerAlert.dhuha]!.time, extra.dhuha);
  });
}
