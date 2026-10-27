import 'dart:io';

import 'package:bedug/features/quran/daily_ayah.dart';
import 'package:bedug/features/quran/daily_ayah_widget.dart';
import 'package:bedug/features/quran/quran.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';

const _languages = ['id', 'en', 'ms', 'ar'];

/// The Gregorian day of Hijri [month] [day] in 1448 AH (2026–2027).
DateTime _hijri(int month, int day) {
  final date = HijriCalendar().hijriToGregorian(1448, month, day);
  return DateTime(date.year, date.month, date.day);
}

void main() {
  final daily = parseDailyAyahs(File(dailyAyahsAsset).readAsStringSync());
  final index = parseQuranIndex(File(quranIndexAsset).readAsStringSync());
  final groups = [...daily.occasions, ...daily.themes];

  test('every ayah is real and its text matches the reader', () {
    final texts = {
      'ar': parseQuranText(File(quranTextAsset).readAsStringSync()),
      for (final language in _languages.where((l) => l != 'ar'))
        language: parseQuranText(
          File(quranTranslationAsset(language)!).readAsStringSync(),
        ),
    };
    for (final group in groups) {
      expect(group.ayahs, isNotEmpty, reason: group.id);
      for (final ayah in group.ayahs) {
        expect(index.contains(ayah.ref), isTrue, reason: '${ayah.ref}');
        for (final MapEntry(key: language, value: text) in texts.entries) {
          expect(
            ayah.text[language],
            ayahWithoutBasmala(text, ayah.ref),
            reason: 'Run scripts/build_daily_ayahs.py (${ayah.ref} $language)',
          );
        }
      }
    }
  });

  test('every reason is in every language', () {
    for (final group in groups) {
      for (final language in _languages) {
        expect(group.why[language], isNotEmpty, reason: group.id);
      }
    }
  });

  test('occasions come before themes, the most specific first', () {
    expect(daily.pick(_hijri(9, 5)).group.id, 'ramadan');
    expect(daily.pick(_hijri(9, 17)).group.id, 'nuzulul_quran');
    expect(daily.pick(_hijri(9, 27)).group.id, 'last_ten_nights');
    expect(daily.pick(_hijri(10, 1)).group.id, 'eid_al_fitr');
    expect(daily.pick(_hijri(12, 9)).group.id, 'arafah');
    expect(daily.pick(_hijri(12, 10)).group.id, 'eid_al_adha');
    expect(daily.pick(_hijri(1, 1)).group.id, 'hijri_new_year');
  });

  test('Fridays without an occasion read for Friday', () {
    // 6 November 2026 is a Friday in Jumada al-Ula, which has no occasion.
    final friday = DateTime(2026, 11, 6);
    expect(friday.weekday, DateTime.friday);
    expect(daily.pick(friday).group.id, 'friday');
  });

  test('ordinary days rotate themes and repeat for the same day', () {
    // Monday 2 to Thursday 5 November 2026 have no occasion.
    final picks = [
      for (var d = 2; d <= 5; d++) daily.pick(DateTime(2026, 11, d)),
    ];
    final themes = {for (final t in daily.themes) t.id};
    for (final pick in picks) {
      expect(themes, contains(pick.group.id));
    }
    for (var i = 1; i < picks.length; i++) {
      expect(picks[i].group.id, isNot(picks[i - 1].group.id));
    }
    expect(
      daily.pick(DateTime(2026, 11, 2, 23, 59)).ayah.ref,
      picks.first.ayah.ref,
    );
  });

  test('the widget gets a week of days keyed by local date', () {
    final data = buildDailyAyahWidgetData(
      ayahs: daily,
      index: index,
      l10n: lookupAppLocalizations(const Locale('en')),
      now: DateTime(2026, 12, 30, 21),
      themeMode: 0,
    );
    final days = data['days']! as List<Map<String, Object>>;
    expect(days, hasLength(dailyAyahWidgetDays));
    expect(days.first['date'], '2026-12-30');
    expect(days[2]['date'], '2027-01-01');
    final first = daily.pick(DateTime(2026, 12, 30));
    expect(days.first['why'], first.group.whyFor('en'));
    expect(days.first['translation'], first.ayah.text['en']);
    expect(
      ayahFromWidgetUri(Uri.parse(days.first['link']! as String)),
      first.ayah.ref,
    );
  });

  test('Arabic widgets carry no translation', () {
    final data = buildDailyAyahWidgetData(
      ayahs: daily,
      index: index,
      l10n: lookupAppLocalizations(const Locale('ar')),
      now: DateTime(2026, 11, 2),
      themeMode: 0,
    );
    final days = data['days']! as List<Map<String, Object>>;
    expect(days.every((d) => d['translation'] == ''), isTrue);
  });
}
