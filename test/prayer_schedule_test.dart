import 'package:adhan/adhan.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final jakarta = Coordinates(-6.2088, 106.8456);
  final params = CalculationMethod.singapore.getParameters();

  test('builds 30 consecutive days starting on the given date', () {
    final schedule =
        buildPrayerSchedule(jakarta, params, DateTime(2026, 12, 20, 15, 30));

    expect(schedule, hasLength(scheduleDays));
    for (final (i, day) in schedule.indexed) {
      final expected = DateTime(2026, 12, 20 + i);
      final d = day.dateComponents;
      expect(DateTime(d.year, d.month, d.day), expected);
    }
    // Crosses the year boundary.
    expect(schedule.last.dateComponents.year, 2027);
  });

  test('respects a custom day count', () {
    expect(
      buildPrayerSchedule(jakarta, params, DateTime(2026, 1, 1), days: 7),
      hasLength(7),
    );
  });
}
