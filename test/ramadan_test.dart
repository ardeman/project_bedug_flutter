import 'package:adhan/adhan.dart';
import 'package:bedug/core/services/extra_prayer_times.dart';
import 'package:bedug/core/services/prayer_service.dart' show prayerTimesOn;
import 'package:bedug/features/fasting/fasting_log.dart';
import 'package:bedug/features/fasting/ramadan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';

/// The Gregorian day of a Umm al-Qura date.
DateTime _day(int year, int month, int day) {
  final date = HijriCalendar().hijriToGregorian(year, month, day);
  return DateTime(date.year, date.month, date.day);
}

/// A place on the equator at the machine's time zone meridian, so its
/// prayers fall on the local calendar day wherever the tests run.
PrayerTimes _timesOn(DateTime day) {
  final offset = day.timeZoneOffset.inMinutes / 60;
  return PrayerTimes(
    Coordinates(0, (offset * 15).clamp(-179.0, 179.0)),
    DateComponents(day.year, day.month, day.day),
    CalculationMethod.singapore.getParameters(),
  );
}

void main() {
  group('Ramadan dates', () {
    test('Ramadan 1446 ran from 1 March 2025 for 29 days', () {
      final month = ramadanOf(1446)!;
      expect(month.start, DateTime(2025, 3, 1));
      expect(month.length, 29);
      expect(month.end, DateTime(2025, 3, 30));
      expect(month.contains(DateTime(2025, 3, 29)), isTrue);
      expect(month.contains(DateTime(2025, 3, 30)), isFalse);
    });

    test('days of Ramadan are numbered from its first', () {
      expect(ramadanDayOf(_day(1447, 9, 1)), 1);
      expect(ramadanDayOf(_day(1447, 9, 17)), 17);
      expect(ramadanDayOf(_day(1447, 8, 29)), isNull);
      expect(ramadanDayOf(_day(1447, 10, 1)), isNull);
    });

    test('the current or next and the current or last Ramadan', () {
      final inside = _day(1447, 9, 10);
      final after = _day(1447, 11, 1);
      expect(currentOrNextRamadan(inside)!.hijriYear, 1447);
      expect(currentOrNextRamadan(after)!.hijriYear, 1448);
      expect(currentOrLastRamadan(inside)!.hijriYear, 1447);
      expect(currentOrLastRamadan(after)!.hijriYear, 1447);
      expect(currentOrLastRamadan(_day(1448, 3, 1))!.hijriYear, 1447);
    });

    test('make-up fasts are not kept in Ramadan, on Eid or at Tashreeq', () {
      expect(qadaAllowedOn(_day(1447, 9, 5)), isFalse);
      expect(qadaAllowedOn(_day(1447, 10, 1)), isFalse);
      expect(qadaAllowedOn(_day(1447, 10, 2)), isTrue);
      expect(qadaAllowedOn(_day(1447, 12, 10)), isFalse);
      expect(qadaAllowedOn(_day(1447, 12, 13)), isFalse);
      expect(qadaAllowedOn(_day(1447, 12, 14)), isTrue);
    });
  });

  group('Ramadan countdown', () {
    final first = _day(1447, 9, 1);
    final eve = DateTime(first.year, first.month, first.day - 1);
    final eid = _day(1447, 10, 1);
    final lastDay = DateTime(eid.year, eid.month, eid.day - 1);

    test('none before Maghrib on the eve of Ramadan', () {
      final times = _timesOn(eve);
      final now = times.maghrib.subtract(const Duration(minutes: 1));
      expect(ramadanCountdownAt(times, now), isNull);
    });

    test('sahur from Maghrib the evening before the first fast', () {
      final times = _timesOn(eve);
      final countdown = ramadanCountdownAt(times, times.maghrib)!;
      final firstTimes = prayerTimesOn(times, first);
      expect(countdown.phase, RamadanPhase.sahur);
      expect(countdown.ramadanDay, 1);
      expect(countdown.fastDay, first);
      expect(countdown.target, ExtraPrayerTimes(firstTimes).imsak);
      expect(countdown.fajr, firstTimes.fajr);
      expect(countdown.since, times.maghrib);
    });

    test('sahur until imsak, then the fast until Maghrib', () {
      final times = _timesOn(first);
      final imsak = ExtraPrayerTimes(times).imsak;
      final sahur = ramadanCountdownAt(
        times,
        imsak.subtract(const Duration(minutes: 1)),
      )!;
      expect(sahur.phase, RamadanPhase.sahur);
      expect(sahur.target, imsak);

      final fast = ramadanCountdownAt(times, imsak)!;
      expect(fast.phase, RamadanPhase.fasting);
      expect(fast.target, times.maghrib);
      expect(fast.since, imsak);
      expect(fast.ramadanDay, 1);
    });

    test('after iftar it counts to the next day\'s imsak', () {
      final times = _timesOn(first);
      final countdown = ramadanCountdownAt(times, times.maghrib)!;
      expect(countdown.phase, RamadanPhase.sahur);
      expect(countdown.ramadanDay, 2);
    });

    test('none after iftar on the last day, before Eid', () {
      final times = _timesOn(lastDay);
      expect(ramadanCountdownAt(times, times.maghrib), isNull);
      expect(
        ramadanCountdownAt(
          times,
          times.maghrib.subtract(const Duration(minutes: 1)),
        )?.phase,
        RamadanPhase.fasting,
      );
    });
  });

  group('fasting log', () {
    test('missed and excused days are owed until made up', () {
      var log = const FastingLog()
          .withStatus(DateTime(2026, 2, 20), FastStatus.fasted)
          .withStatus(DateTime(2026, 2, 21), FastStatus.missed)
          .withStatus(DateTime(2026, 2, 22, 18), FastStatus.excused);
      expect(log.qadaOwed, 2);
      log = log.withStatus(DateTime(2026, 4, 6), FastStatus.qada);
      expect(log.qadaOwed, 1);
      expect(log.qadaDays, [DateTime(2026, 4, 6)]);
      log = log
          .withStatus(DateTime(2026, 4, 7), FastStatus.qada)
          .withStatus(DateTime(2026, 4, 8), FastStatus.qada);
      expect(log.qadaOwed, 0);
      expect(log.qadaDays.first, DateTime(2026, 4, 8));
      expect(log.withStatus(DateTime(2026, 4, 8), null).qadaDays.length, 2);
    });

    test('round-trips and skips what it does not know', () {
      final log = const FastingLog()
          .withStatus(DateTime(2026, 2, 20), FastStatus.fasted)
          .withStatus(DateTime(2026, 4, 6), FastStatus.qada);
      final parsed = FastingLog.parse(log.toJson());
      expect(parsed.statusOn(DateTime(2026, 2, 20, 9)), FastStatus.fasted);
      expect(parsed.statusOn(DateTime(2026, 4, 6)), FastStatus.qada);

      final future = FastingLog.parse(
        '{"2026-02-20":"fasted","2026-02-21":"someday","nope":"missed"}',
      );
      expect(future.days.length, 1);
      expect(FastingLog.parse('not json').days, isEmpty);
      expect(FastingLog.parse(null).days, isEmpty);
    });
  });
}
