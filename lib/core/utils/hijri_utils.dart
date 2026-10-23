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

// hijriToGregorian adalah instance method: hijriToGregorian(year, month, day)
DateTime hijriToGregorian(HijriCalendar h) {
  final temp = HijriCalendar();
  return temp.hijriToGregorian(h.hYear, h.hMonth, h.hDay);
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
