import 'package:hijri/hijri_calendar.dart';

import '../../generated/l10n/app_localizations.dart';

// getDaysInMonth adalah instance method di hijri v3
List<HijriCalendar> buildHijriMonth(int hYear, int hMonth) {
  final temp = HijriCalendar();
  final daysInMonth = temp.getDaysInMonth(hYear, hMonth);
  return List.generate(daysInMonth, (i) {
    final h = HijriCalendar();
    h.hYear = hYear;
    h.hMonth = hMonth;
    h.hDay = i + 1;
    return h;
  });
}

/// The choices for [hijriOf]'s adjustment, in days.
const hijriAdjustmentOptions = [-2, -1, 0, 1, 2];

/// The Hijri date of the Gregorian [date]: the Umm al-Qura conversion moved
/// [adjustment] days, so it can follow a local announcement such as
/// Indonesia's sidang isbat. Throws an [ArgumentError] outside the table.
HijriCalendar hijriOf(DateTime date, [int adjustment = 0]) =>
    HijriCalendar.fromDate(
      DateTime(date.year, date.month, date.day + adjustment),
    );

/// The Gregorian date of [h], the inverse of [hijriOf] with the same
/// [adjustment].
DateTime hijriToGregorian(HijriCalendar h, [int adjustment = 0]) {
  // hijriToGregorian is an instance method in hijri v3.
  final date = HijriCalendar().hijriToGregorian(h.hYear, h.hMonth, h.hDay);
  return DateTime(date.year, date.month, date.day - adjustment);
}

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
