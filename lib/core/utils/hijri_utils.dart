import 'package:flutter/foundation.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../generated/l10n/app_localizations.dart';
import 'mabims_calendar.dart';

/// Whose calendar the Hijri dates follow.
enum HijriSource {
  /// Saudi Arabia's Umm al-Qura calendar, from the `hijri` package's table.
  ummAlQura,

  /// The MABIMS criteria, as the Indonesian government (Kemenag) and
  /// Malaysia, Brunei and Singapore calculate them ([mabimsMonthStart]).
  mabims,
}

/// The choices for [HijriReckoning.adjustment], in days.
const hijriAdjustmentOptions = [-2, -1, 0, 1, 2];

/// How Hijri dates are reckoned: the [source] calendar moved [adjustment]
/// days, so it can follow a local announcement such as Indonesia's sidang
/// isbat.
@immutable
class HijriReckoning {
  final HijriSource source;

  /// Days added to the calculated date, one of [hijriAdjustmentOptions].
  final int adjustment;

  const HijriReckoning({
    this.source = HijriSource.ummAlQura,
    this.adjustment = 0,
  });

  @override
  bool operator ==(Object other) =>
      other is HijriReckoning &&
      other.source == source &&
      other.adjustment == adjustment;

  @override
  int get hashCode => Object.hash(source, adjustment);
}

/// The days of Hijri [month] of [year] under [source].
List<HijriCalendar> buildHijriMonth(
  int hYear,
  int hMonth, [
  HijriSource source = HijriSource.ummAlQura,
]) {
  final daysInMonth = switch (source) {
    // getDaysInMonth is an instance method in hijri v3.
    HijriSource.ummAlQura => HijriCalendar().getDaysInMonth(hYear, hMonth),
    HijriSource.mabims => _daysBetween(
      mabimsMonthStart(hYear, hMonth),
      mabimsMonthStart(hYear, hMonth + 1),
    ),
  };
  return [
    for (var day = 1; day <= daysInMonth; day++) _hijri(hYear, hMonth, day),
  ];
}

/// The Hijri date of the Gregorian [date] under [reckoning]. Throws an
/// [ArgumentError] outside the Umm al-Qura table (1356–1500 H), for every
/// source, so the calendars cover the same years.
HijriCalendar hijriOf(
  DateTime date, [
  HijriReckoning reckoning = const HijriReckoning(),
]) {
  final day = DateTime.utc(
    date.year,
    date.month,
    date.day + reckoning.adjustment,
  );
  final ummAlQura = HijriCalendar.fromDate(
    DateTime(day.year, day.month, day.day),
  );
  if (reckoning.source == HijriSource.ummAlQura) return ummAlQura;

  // The calendars differ by a day or two at most, so the MABIMS month is
  // the Umm al-Qura one or a neighbour.
  var year = ummAlQura.hYear, month = ummAlQura.hMonth;
  if (day.isBefore(mabimsMonthStart(year, month))) {
    (year, month) = month == 1 ? (year - 1, 12) : (year, month - 1);
  } else if (!day.isBefore(mabimsMonthStart(year, month + 1))) {
    (year, month) = month == 12 ? (year + 1, 1) : (year, month + 1);
  }
  return _hijri(
    year,
    month,
    _daysBetween(mabimsMonthStart(year, month), day) + 1,
  );
}

/// The Gregorian date of [h], the inverse of [hijriOf] with the same
/// [reckoning].
DateTime hijriToGregorian(
  HijriCalendar h, [
  HijriReckoning reckoning = const HijriReckoning(),
]) {
  final date = switch (reckoning.source) {
    // hijriToGregorian is an instance method in hijri v3.
    HijriSource.ummAlQura => HijriCalendar().hijriToGregorian(
      h.hYear,
      h.hMonth,
      h.hDay,
    ),
    HijriSource.mabims => mabimsMonthStart(
      h.hYear,
      h.hMonth,
    ).add(Duration(days: h.hDay - 1)),
  };
  return DateTime(date.year, date.month, date.day - reckoning.adjustment);
}

HijriCalendar _hijri(int year, int month, int day) => HijriCalendar()
  ..hYear = year
  ..hMonth = month
  ..hDay = day;

int _daysBetween(DateTime from, DateTime to) => to.difference(from).inDays;

/// The short name of [source], such as "Umm al-Qura".
String hijriSourceLabel(AppLocalizations l10n, HijriSource source) =>
    switch (source) {
      HijriSource.ummAlQura => l10n.hijriSourceUmmAlQura,
      HijriSource.mabims => l10n.hijriSourceMabims,
    };

/// Whose calendar [source] is, crediting it.
String hijriSourceCredit(AppLocalizations l10n, HijriSource source) =>
    switch (source) {
      HijriSource.ummAlQura => l10n.hijriSourceUmmAlQuraSubtitle,
      HijriSource.mabims => l10n.hijriSourceMabimsSubtitle,
    };

/// The localized name of Hijri [month] (1 is Muharram).
String hijriMonthName(AppLocalizations l10n, int month) => switch (month) {
  1 => l10n.muharram,
  2 => l10n.safar,
  3 => l10n.rabiAlAwwal,
  4 => l10n.rabiAlThani,
  5 => l10n.jumadaAlUla,
  6 => l10n.jumadaAlAkhirah,
  7 => l10n.rajab,
  8 => l10n.shaban,
  9 => l10n.ramadan,
  10 => l10n.shawwal,
  11 => l10n.dhuAlQidah,
  12 => l10n.dhuAlHijjah,
  _ => '',
};
