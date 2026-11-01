import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/services/extra_prayer_times.dart';
import '../../core/services/prayer_service.dart' show prayerTimesOn;
import '../../core/utils/hijri_utils.dart';

/// The day of Ramadan (1 to 30) that the Gregorian [day] falls on under
/// [reckoning], or null outside Ramadan and outside the Umm al-Qura table.
/// Like the sunnah fasts, the day is the daytime date's.
int? ramadanDayOf(
  DateTime day, [
  HijriReckoning reckoning = const HijriReckoning(),
]) {
  try {
    final hijri = hijriOf(day, reckoning);
    return hijri.hMonth == 9 ? hijri.hDay : null;
  } on ArgumentError {
    return null;
  }
}

/// The Gregorian days of one Ramadan.
@immutable
class RamadanMonth {
  final int hijriYear;

  /// The first day, at local midnight.
  final DateTime start;

  /// 29 or 30.
  final int length;

  const RamadanMonth({
    required this.hijriYear,
    required this.start,
    required this.length,
  });

  /// The Gregorian date of Ramadan day [n], counted from 1.
  DateTime day(int n) => DateTime(start.year, start.month, start.day + n - 1);

  List<DateTime> get days => [for (var n = 1; n <= length; n++) day(n)];

  /// The day after the last, Eid al-Fitr.
  DateTime get end => day(length + 1);

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);
}

/// Ramadan of [hijriYear] under [reckoning], or null outside the Umm
/// al-Qura table.
RamadanMonth? ramadanOf(
  int hijriYear, [
  HijriReckoning reckoning = const HijriReckoning(),
]) {
  try {
    final first = hijriToGregorian(
      HijriCalendar()
        ..hYear = hijriYear
        ..hMonth = 9
        ..hDay = 1,
      reckoning,
    );
    final start = DateTime(first.year, first.month, first.day);
    // The month ends where the next one begins, which the source decides.
    final length =
        ramadanDayOf(
              DateTime(start.year, start.month, start.day + 29),
              reckoning,
            ) ==
            30
        ? 30
        : 29;
    return RamadanMonth(hijriYear: hijriYear, start: start, length: length);
  } on ArgumentError {
    return null;
  }
}

/// The Ramadan [today] is in, or else the next one, so a screen always has
/// a month to show; null outside the Umm al-Qura table.
RamadanMonth? currentOrNextRamadan(
  DateTime today, [
  HijriReckoning reckoning = const HijriReckoning(),
]) {
  final HijriCalendar hijri;
  try {
    hijri = hijriOf(today, reckoning);
  } on ArgumentError {
    return null;
  }
  return ramadanOf(
    hijri.hMonth <= 9 ? hijri.hYear : hijri.hYear + 1,
    reckoning,
  );
}

/// The most recent Ramadan that has begun by [today], current or past.
RamadanMonth? currentOrLastRamadan(
  DateTime today, [
  HijriReckoning reckoning = const HijriReckoning(),
]) {
  final HijriCalendar hijri;
  try {
    hijri = hijriOf(today, reckoning);
  } on ArgumentError {
    return null;
  }
  return ramadanOf(
    hijri.hMonth >= 9 ? hijri.hYear : hijri.hYear - 1,
    reckoning,
  );
}

/// What a Ramadan countdown counts down to.
enum RamadanPhase {
  /// Sahur until imsak, from Maghrib the evening before.
  sahur,

  /// The fast until Maghrib, when it is broken.
  fasting,
}

/// A countdown to the end of sahur or to iftar.
@immutable
class RamadanCountdown {
  final RamadanPhase phase;

  /// Imsak for [RamadanPhase.sahur], Maghrib for [RamadanPhase.fasting].
  final DateTime target;

  /// When the phase began: the previous Maghrib for sahur, imsak for the
  /// fast. Countdown rings fill from here.
  final DateTime since;

  /// Fajr of the fasting day, when the fast itself begins.
  final DateTime fajr;

  /// The Gregorian fasting day and its day of Ramadan.
  final DateTime fastDay;
  final int ramadanDay;

  const RamadanCountdown({
    required this.phase,
    required this.target,
    required this.since,
    required this.fajr,
    required this.fastDay,
    required this.ramadanDay,
  });
}

/// The countdown at [now], or null when no Ramadan fast is ahead: before
/// imsak and during the fast on a day of Ramadan, and from Maghrib on when
/// the next day is one, including the evening before the first. [times]
/// gives the place and method; each day is calculated on its own.
RamadanCountdown? ramadanCountdownAt(
  PrayerTimes times,
  DateTime now, [
  HijriReckoning reckoning = const HijriReckoning(),
]) {
  final today = DateTime(now.year, now.month, now.day);
  final daily = prayerTimesOn(times, today);
  final todayFast = ramadanDayOf(today, reckoning);
  if (todayFast != null) {
    final imsak = ExtraPrayerTimes(daily).imsak;
    if (now.isBefore(imsak)) {
      final yesterday = prayerTimesOn(
        times,
        DateTime(today.year, today.month, today.day - 1),
      );
      return RamadanCountdown(
        phase: RamadanPhase.sahur,
        target: imsak,
        since: yesterday.maghrib,
        fajr: daily.fajr,
        fastDay: today,
        ramadanDay: todayFast,
      );
    }
    if (now.isBefore(daily.maghrib)) {
      return RamadanCountdown(
        phase: RamadanPhase.fasting,
        target: daily.maghrib,
        since: imsak,
        fajr: daily.fajr,
        fastDay: today,
        ramadanDay: todayFast,
      );
    }
  }
  if (now.isBefore(daily.maghrib)) return null;
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  final tomorrowFast = ramadanDayOf(tomorrow, reckoning);
  if (tomorrowFast == null) return null;
  final next = prayerTimesOn(times, tomorrow);
  return RamadanCountdown(
    phase: RamadanPhase.sahur,
    target: ExtraPrayerTimes(next).imsak,
    since: daily.maghrib,
    fajr: next.fajr,
    fastDay: tomorrow,
    ramadanDay: tomorrowFast,
  );
}

/// Whether a make-up fast can be kept on [day]: not in Ramadan, whose own
/// fast it would replace, and not on Eid al-Fitr, Eid al-Adha or the days
/// of Tashreeq, when fasting is not allowed.
bool qadaAllowedOn(
  DateTime day, [
  HijriReckoning reckoning = const HijriReckoning(),
]) {
  final HijriCalendar hijri;
  try {
    hijri = hijriOf(day, reckoning);
  } on ArgumentError {
    return true;
  }
  return !(hijri.hMonth == 9 ||
      (hijri.hMonth == 10 && hijri.hDay == 1) ||
      (hijri.hMonth == 12 && hijri.hDay >= 10 && hijri.hDay <= 13));
}
