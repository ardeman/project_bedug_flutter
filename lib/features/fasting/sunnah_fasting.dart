import 'package:hijri/hijri_calendar.dart';

import '../../core/utils/hijri_utils.dart';
import '../../generated/l10n/app_localizations.dart';

/// The sunnah fasts the app reminds of; names are stable identifiers.
enum SunnahFast {
  monday,
  thursday,

  /// Ayyamul Bidh, the 13th to the 15th of every Hijri month.
  whiteDays,

  /// 9 Dhu al-Hijjah.
  arafah,

  /// 9 Muharram, fasted with Ashura.
  tasua,

  /// 10 Muharram.
  ashura;

  /// Monday and Thursday come every week and have their own switch.
  bool get isWeekly => this == monday || this == thursday;
}

/// The sunnah fasts on the Gregorian [day], in [SunnahFast] order, left out
/// of Ramadan, whose own fast replaces them, and of the days on which
/// fasting is not allowed: Eid al-Fitr, Eid al-Adha and the days of
/// Tashreeq. Hijri dates are the daytime date's under [reckoning]
/// ([hijriOf]); days outside the Umm al-Qura table keep only the weekly
/// fasts. [weekly] includes Monday and Thursday.
List<SunnahFast> sunnahFastsOn(
  DateTime day, {
  bool weekly = true,
  HijriReckoning reckoning = const HijriReckoning(),
}) {
  HijriCalendar? hijri;
  try {
    hijri = hijriOf(day, reckoning);
  } on ArgumentError {
    hijri = null;
  }
  if (hijri != null && _noSunnahFast(hijri)) return const [];
  return [
    if (weekly && day.weekday == DateTime.monday) SunnahFast.monday,
    if (weekly && day.weekday == DateTime.thursday) SunnahFast.thursday,
    if (hijri != null) ...[
      if (hijri.hDay >= 13 && hijri.hDay <= 15) SunnahFast.whiteDays,
      if (hijri.hMonth == 12 && hijri.hDay == 9) SunnahFast.arafah,
      if (hijri.hMonth == 1 && hijri.hDay == 9) SunnahFast.tasua,
      if (hijri.hMonth == 1 && hijri.hDay == 10) SunnahFast.ashura,
    ],
  ];
}

/// Ramadan (month 9), 1 Shawwal and 10 to 13 Dhu al-Hijjah.
bool _noSunnahFast(HijriCalendar hijri) =>
    hijri.hMonth == 9 ||
    (hijri.hMonth == 10 && hijri.hDay == 1) ||
    (hijri.hMonth == 12 && hijri.hDay >= 10 && hijri.hDay <= 13);

String sunnahFastName(AppLocalizations l10n, SunnahFast fast) => switch (fast) {
  SunnahFast.monday => l10n.sunnahFastMonday,
  SunnahFast.thursday => l10n.sunnahFastThursday,
  SunnahFast.whiteDays => l10n.sunnahFastWhiteDays,
  SunnahFast.arafah => l10n.sunnahFastArafah,
  SunnahFast.tasua => l10n.sunnahFastTasua,
  SunnahFast.ashura => l10n.sunnahFastAshura,
};
