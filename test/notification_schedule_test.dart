import 'package:adhan/adhan.dart';
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
        schedule.firstWhere((alert) => alert.id == 10).time,
        tomorrow.fajr,
      );
    },
  );

  test('disabled prayer removes both alerts and master switch removes all', () {
    const preferences = NotificationPreferences(
      disabledPrayers: {Prayer.fajr},
      reminderMinutes: 10,
    );
    final schedule = buildNotificationSchedule(times, preferences, now);
    expect(schedule, hasLength(48));
    expect(schedule.any((alert) => alert.prayer == Prayer.fajr), isFalse);
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
          (alert) => alert.id == reminder.id - 5,
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
    expect(schedule.any((alert) => alert.id == 1), isTrue);
    expect(schedule.any((alert) => alert.id == 6), isFalse);
  });
}
