import 'package:bedug/core/utils/hijri_utils.dart';
import 'package:bedug/core/utils/mabims_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

const mabims = HijriReckoning(source: HijriSource.mabims);

void main() {
  test('an adjustment moves the Hijri date and its inverse together', () {
    final day = DateTime(2026, 10, 27);
    final calculated = hijriOf(day);
    for (final adjustment in hijriAdjustmentOptions) {
      final reckoning = HijriReckoning(adjustment: adjustment);
      final adjusted = hijriOf(day, reckoning);
      expect(hijriToGregorian(adjusted, reckoning), day, reason: '$adjustment');
      expect(
        hijriToGregorian(adjusted).difference(hijriToGregorian(calculated)),
        Duration(days: adjustment),
        reason: '$adjustment',
      );
    }
  });

  // Kemenag's published first days, under MABIMS since 1444 H (2022), with
  // the Umm al-Qura date where it differs.
  const kemenag = {
    (1444, 9): '2023-03-23',
    (1444, 10): '2023-04-22', // Umm al-Qura 21 April
    (1444, 12): '2023-06-20', // 19 June
    (1445, 9): '2024-03-12', // 11 March
    (1445, 10): '2024-04-10',
    (1445, 12): '2024-06-08', // 7 June
    (1446, 1): '2024-07-07',
    (1446, 9): '2025-03-01', // elongation 6.40°, just over the limit
    (1446, 10): '2025-03-31', // 30 March
    (1446, 12): '2025-05-28',
    (1447, 1): '2025-06-27', // 26 June
    (1447, 9): '2026-02-19', // 18 February
    (1447, 10): '2026-03-21', // 20 March
    (1447, 12): '2026-05-18',
    (1448, 1): '2026-06-16',
    (1448, 2): '2026-07-16', // 15 July
  };

  test('MABIMS months start on the days Kemenag published', () {
    for (final MapEntry(key: (year, month), :value) in kemenag.entries) {
      expect(
        mabimsMonthStart(year, month),
        DateTime.parse('${value}T00:00:00Z'),
        reason: '$year/$month',
      );
      final first = DateTime.parse(value);
      final hijri = hijriOf(first, mabims);
      expect(
        (hijri.hYear, hijri.hMonth, hijri.hDay),
        (year, month, 1),
        reason: '$year/$month',
      );
    }
  });

  test('MABIMS conversions round-trip and months last 29 or 30 days', () {
    for (var year = 1440; year <= 1460; year++) {
      for (var month = 1; month <= 12; month++) {
        final days = buildHijriMonth(year, month, HijriSource.mabims);
        expect(days.length, inInclusiveRange(29, 30), reason: '$year/$month');
        for (final day in [days.first, days.last]) {
          final date = hijriToGregorian(day, mabims);
          final back = hijriOf(date, mabims);
          expect(
            (back.hYear, back.hMonth, back.hDay),
            (day.hYear, day.hMonth, day.hDay),
          );
        }
        // The next month starts the day after this one ends.
        final next = month == 12 ? (year + 1, 1) : (year, month + 1);
        final nextDate = hijriToGregorian(
          days.last,
          mabims,
        ).add(const Duration(days: 1));
        final nextHijri = hijriOf(nextDate, mabims);
        expect(
          (nextHijri.hYear, nextHijri.hMonth, nextHijri.hDay),
          (next.$1, next.$2, 1),
        );
      }
    }
  });

  test('the calendars stay within two days of each other', () {
    for (
      var day = DateTime(2000);
      day.year < 2077;
      day = DateTime(day.year, day.month, day.day + 9)
    ) {
      final ummAlQura = hijriOf(day), other = hijriOf(day, mabims);
      final shift = hijriToGregorian(other)
          .difference(hijriToGregorian(ummAlQura));
      expect(shift.inDays.abs(), lessThanOrEqualTo(2), reason: '$day');
    }
  });
}
