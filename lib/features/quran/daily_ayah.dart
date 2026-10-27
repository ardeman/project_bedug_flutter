import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/utils/hijri_utils.dart';
import 'quran.dart';

const dailyAyahsAsset = 'assets/content/quran/daily_ayahs.json';

/// One ayah of the day with its text in every language, filled in by
/// `scripts/build_daily_ayahs.py`.
@immutable
class DailyAyah {
  final AyahRef ref;

  /// The Arabic under `ar` and each translation under its language.
  final Map<String, String> text;

  const DailyAyah({required this.ref, required this.text});

  String get arabic => text['ar']!;

  /// The meaning in [languageCode]; null for Arabic, whose readers read the
  /// text itself.
  String? translationFor(String languageCode) =>
      languageCode == 'ar' ? null : text[languageCode] ?? text['en'];
}

/// A set of ayahs that share why they are shown: an occasion, such as
/// Ramadan or Friday, or a theme for ordinary days.
@immutable
class DailyAyahGroup {
  final String id;

  /// Why these ayahs are shown, in every language.
  final Map<String, String> why;
  final List<DailyAyah> ayahs;

  /// The Hijri month an occasion falls in, 1 to 12.
  final int? hijriMonth;

  /// The first and last day of the occasion within [hijriMonth]; null for
  /// the whole month.
  final (int, int)? hijriDays;

  /// The weekday an occasion falls on, as in [DateTime.weekday].
  final int? weekday;

  const DailyAyahGroup({
    required this.id,
    required this.why,
    required this.ayahs,
    this.hijriMonth,
    this.hijriDays,
    this.weekday,
  });

  String whyFor(String languageCode) => why[languageCode] ?? why['en']!;

  bool matches(DateTime day, HijriCalendar hijri) {
    if (weekday case final weekday?) return day.weekday == weekday;
    if (hijriMonth != hijri.hMonth) return false;
    final days = hijriDays;
    return days == null || (hijri.hDay >= days.$1 && hijri.hDay <= days.$2);
  }

  /// How closely the occasion pins down a day: a few Hijri days beat a whole
  /// month, which beats a weekday, so Laylat al-Qadr wins over Ramadan and
  /// Ramadan over Friday.
  int get _specificity {
    if (weekday != null) return 0;
    final days = hijriDays;
    // Hijri months have at most 30 days.
    return days == null ? 1 : 2 + 30 - (days.$2 - days.$1);
  }
}

/// The day's ayah and why it was picked.
typedef DailyAyahPick = ({DailyAyah ayah, DailyAyahGroup group});

class DailyAyahs {
  final List<DailyAyahGroup> occasions;
  final List<DailyAyahGroup> themes;

  /// Ordinary days take the themes in turn, one ayah each, so consecutive
  /// days differ in theme.
  final List<DailyAyahPick> _rotation;

  DailyAyahs({required this.occasions, required this.themes})
    : _rotation = _interleave(themes);

  static List<DailyAyahPick> _interleave(List<DailyAyahGroup> themes) {
    final rotation = <DailyAyahPick>[];
    final longest = themes.fold(
      0,
      (max, t) => t.ayahs.length > max ? t.ayahs.length : max,
    );
    for (var i = 0; i < longest; i++) {
      for (final theme in themes) {
        if (i < theme.ayahs.length) {
          rotation.add((ayah: theme.ayahs[i], group: theme));
        }
      }
    }
    return rotation;
  }

  /// The ayah for the Gregorian [day]. An occasion that day comes first; on
  /// other days the themes rotate. Hijri dates are the daytime date's under
  /// [reckoning] ([hijriOf]).
  DailyAyahPick pick(
    DateTime day, [
    HijriReckoning reckoning = const HijriReckoning(),
  ]) {
    // Counting days in UTC keeps daylight saving from skipping or repeating
    // an ayah.
    final index = DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime.utc(1970)).inDays;
    final hijri = hijriOf(day, reckoning);
    DailyAyahGroup? occasion;
    for (final group in occasions) {
      if (!group.matches(day, hijri)) continue;
      if (occasion == null || group._specificity > occasion._specificity) {
        occasion = group;
      }
    }
    if (occasion != null) {
      return (
        ayah: occasion.ayahs[index % occasion.ayahs.length],
        group: occasion,
      );
    }
    return _rotation[index % _rotation.length];
  }
}

DailyAyahGroup _parseGroup(Map<String, dynamic> json) {
  final days = json['hijriDays'] as List?;
  return DailyAyahGroup(
    id: json['id'] as String,
    why: Map<String, String>.from(json['why'] as Map),
    ayahs: [
      for (final a in json['ayahs'] as List)
        DailyAyah(
          ref: AyahRef.tryParse(a['ref'] as String)!,
          text: Map<String, String>.from(a['text'] as Map),
        ),
    ],
    hijriMonth: json['hijriMonth'] as int?,
    hijriDays: days == null ? null : (days[0] as int, days[1] as int),
    weekday: json['weekday'] as int?,
  );
}

/// Parses [dailyAyahsAsset].
DailyAyahs parseDailyAyahs(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  return DailyAyahs(
    occasions: [
      for (final g in json['occasions'] as List)
        _parseGroup(g as Map<String, dynamic>),
    ],
    themes: [
      for (final g in json['themes'] as List)
        _parseGroup(g as Map<String, dynamic>),
    ],
  );
}

final dailyAyahsProvider = FutureProvider<DailyAyahs>(
  (ref) async => parseDailyAyahs(await rootBundle.loadString(dailyAyahsAsset)),
);
