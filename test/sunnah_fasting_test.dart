import 'package:bedug/features/fasting/sunnah_fasting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';

/// The Gregorian day of a Umm al-Qura date.
DateTime _day(int year, int month, int day) {
  final date = HijriCalendar().hijriToGregorian(year, month, day);
  return DateTime(date.year, date.month, date.day);
}

/// The first day from [from] that falls on [weekday].
DateTime _next(DateTime from, int weekday) =>
    DateTime(from.year, from.month, from.day + (weekday - from.weekday) % 7);

void main() {
  test('Tasu\'a, Ashura and Arafah fall on their Hijri days', () {
    expect(sunnahFastsOn(_day(1448, 1, 9)), contains(SunnahFast.tasua));
    expect(sunnahFastsOn(_day(1448, 1, 10)), contains(SunnahFast.ashura));
    expect(
      sunnahFastsOn(_day(1448, 1, 11)),
      isNot(contains(SunnahFast.ashura)),
    );
    expect(sunnahFastsOn(_day(1447, 12, 9)), contains(SunnahFast.arafah));
  });

  test('the white days are the 13th to the 15th', () {
    for (final day in [13, 14, 15]) {
      expect(sunnahFastsOn(_day(1448, 5, day)), contains(SunnahFast.whiteDays));
    }
    expect(sunnahFastsOn(_day(1448, 5, 12), weekly: false), isEmpty);
    expect(sunnahFastsOn(_day(1448, 5, 16), weekly: false), isEmpty);
  });

  test('Monday and Thursday come only when weekly reminders are on', () {
    final monday = _next(_day(1448, 8, 1), DateTime.monday);
    final thursday = _next(_day(1448, 8, 1), DateTime.thursday);
    expect(sunnahFastsOn(monday), contains(SunnahFast.monday));
    expect(sunnahFastsOn(thursday), contains(SunnahFast.thursday));
    expect(
      sunnahFastsOn(monday, weekly: false),
      isNot(contains(SunnahFast.monday)),
    );
  });

  test('no sunnah fast in Ramadan, on the Eids or the days of Tashreeq', () {
    for (var day = 1; day <= 29; day++) {
      expect(sunnahFastsOn(_day(1448, 9, day)), isEmpty);
    }
    expect(sunnahFastsOn(_day(1448, 10, 1)), isEmpty);
    for (var day = 10; day <= 13; day++) {
      expect(sunnahFastsOn(_day(1447, 12, day)), isEmpty);
    }
    expect(sunnahFastsOn(_day(1447, 12, 14)), contains(SunnahFast.whiteDays));
  });
}
