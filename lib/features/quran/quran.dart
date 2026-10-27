import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/locale_provider.dart';

const quranIndexAsset = 'assets/content/quran/surahs.json';
const quranTextAsset = 'assets/content/quran/text.json';

/// The bundled Amiri Quran face, which draws the Uthmani marks.
const quranFontFamily = 'AmiriQuran';

/// The translation shown under the Arabic in [languageCode]; Arabic has none.
String? quranTranslationAsset(String languageCode) => languageCode == 'ar'
    ? null
    : 'assets/content/quran/translation_$languageCode.json';

enum Revelation { meccan, medinan }

class Surah {
  /// 1 to 114.
  final int number;
  final String arabic;

  /// The transliterated name in each language except Arabic.
  final Map<String, String> name;
  final int ayahCount;
  final Revelation revelation;

  const Surah({
    required this.number,
    required this.arabic,
    required this.name,
    required this.ayahCount,
    required this.revelation,
  });

  String nameFor(String languageCode) =>
      languageCode == 'ar' ? arabic : name[languageCode] ?? name['en']!;
}

/// One ayah, such as 2:255.
@immutable
class AyahRef implements Comparable<AyahRef> {
  final int surah;
  final int ayah;

  const AyahRef(this.surah, this.ayah);

  /// Parses the `surah:ayah` form [toString] writes; null when malformed.
  static AyahRef? tryParse(String? value) {
    final parts = value?.split(':');
    if (parts == null || parts.length != 2) return null;
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null) return null;
    return AyahRef(surah, ayah);
  }

  @override
  int compareTo(AyahRef other) =>
      surah != other.surah ? surah - other.surah : ayah - other.ayah;

  @override
  bool operator ==(Object other) =>
      other is AyahRef && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);

  @override
  String toString() => '$surah:$ayah';
}

class QuranIndex {
  final List<Surah> surahs;

  /// Where each of the 30 juz starts.
  final List<AyahRef> juzStarts;

  const QuranIndex({required this.surahs, required this.juzStarts});

  Surah surah(int number) => surahs[number - 1];

  bool contains(AyahRef ref) =>
      ref.surah >= 1 &&
      ref.surah <= surahs.length &&
      ref.ayah >= 1 &&
      ref.ayah <= surah(ref.surah).ayahCount;

  /// The juz, 1 to 30, that [ref] is in.
  int juzOf(AyahRef ref) =>
      juzStarts.lastIndexWhere((start) => start.compareTo(ref) <= 0) + 1;

  /// Every ayah in the Quran, 6236.
  int get ayahCount => surahs.fold(0, (sum, s) => sum + s.ayahCount);

  /// The last ayah, An-Nas 6.
  AyahRef get lastAyah => AyahRef(surahs.length, surahs.last.ayahCount);

  /// [ref]'s place in the whole Quran, counted from 0 at Al-Fatihah 1.
  int ordinalOf(AyahRef ref) {
    var ordinal = ref.ayah - 1;
    for (var s = 1; s < ref.surah; s++) {
      ordinal += surah(s).ayahCount;
    }
    return ordinal;
  }

  /// The ayah at [ordinal], the inverse of [ordinalOf].
  AyahRef ayahAt(int ordinal) {
    var rest = ordinal;
    for (final s in surahs) {
      if (rest < s.ayahCount) return AyahRef(s.number, rest + 1);
      rest -= s.ayahCount;
    }
    throw RangeError.range(ordinal, 0, ayahCount - 1, 'ordinal');
  }
}

/// The Arabic text or one translation: each surah's ayahs in order.
class QuranText {
  /// Credit shown under the reader, such as the translator.
  final String source;
  final List<List<String>> surahs;

  const QuranText({required this.source, required this.surahs});

  String ayah(AyahRef ref) => surahs[ref.surah - 1][ref.ayah - 1];
}

/// Parses [quranIndexAsset].
QuranIndex parseQuranIndex(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  final surahs = json['surahs'] as List;
  return QuranIndex(
    surahs: [
      for (final (i, s) in surahs.indexed)
        Surah(
          number: i + 1,
          arabic: s['arabic'] as String,
          name: Map<String, String>.from(s['name'] as Map),
          ayahCount: s['ayahs'] as int,
          revelation: Revelation.values.byName(s['revelation'] as String),
        ),
    ],
    juzStarts: [
      for (final j in json['juz'] as List) AyahRef(j[0] as int, j[1] as int),
    ],
  );
}

/// Parses [quranTextAsset] or a translation from [quranTranslationAsset].
QuranText parseQuranText(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  return QuranText(
    source: json['source'] as String,
    surahs: [
      for (final surah in json['surahs'] as List) List<String>.from(surah),
    ],
  );
}

/// Tanzil's text opens the first ayah of every surah but Al-Fatihah and
/// At-Taubah with the basmala. The reader shows it as the surah's heading, so
/// this returns that ayah without it; other ayahs come back unchanged.
String ayahWithoutBasmala(QuranText text, AyahRef ref) {
  final ayah = text.ayah(ref);
  if (ref.surah == 1 || ref.ayah != 1) return ayah;
  final basmala = '${text.ayah(const AyahRef(1, 1))} ';
  return ayah.startsWith(basmala) ? ayah.substring(basmala.length) : ayah;
}

/// Whether surah [number] opens with the basmala as its heading.
bool hasBasmalaHeading(int number) => number != 1 && number != 9;

final quranIndexProvider = FutureProvider<QuranIndex>(
  (ref) async => parseQuranIndex(await rootBundle.loadString(quranIndexAsset)),
);

/// Each text is over a megabyte, so it is parsed off the UI thread.
Future<QuranText> _loadText(String asset) async =>
    compute(parseQuranText, await rootBundle.loadString(asset));

final quranTextProvider = FutureProvider<QuranText>(
  (ref) => _loadText(quranTextAsset),
);

/// The translation for the app language; null for Arabic.
final quranTranslationProvider = FutureProvider<QuranText?>((ref) async {
  final asset = quranTranslationAsset(ref.watch(localeProvider).languageCode);
  return asset == null ? null : _loadText(asset);
});

// ─── Reading progress ─────────────────────────────────────────────────────────

const _kLastRead = 'quran_last_read';
const _kBookmarks = 'quran_bookmarks';
const _kTextScale = 'quran_text_scale';

/// Text sizes the reader steps through, as a factor of the default size.
const quranTextScales = [0.8, 0.9, 1.0, 1.15, 1.3, 1.5, 1.75, 2.0];

/// Where the reader left off, the bookmarked ayahs and the text size. Kept on
/// the device only.
@immutable
class QuranReading {
  final AyahRef? lastRead;

  /// Newest first.
  final List<AyahRef> bookmarks;
  final double textScale;

  const QuranReading({
    this.lastRead,
    this.bookmarks = const [],
    this.textScale = 1.0,
  });

  bool isBookmarked(AyahRef ref) => bookmarks.contains(ref);
}

class QuranReadingNotifier extends Notifier<QuranReading> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  QuranReading build() {
    final scale = _prefs.getDouble(_kTextScale);
    return QuranReading(
      lastRead: AyahRef.tryParse(_prefs.getString(_kLastRead)),
      bookmarks: List.unmodifiable(
        (_prefs.getStringList(_kBookmarks) ?? const [])
            .map(AyahRef.tryParse)
            .nonNulls,
      ),
      textScale: quranTextScales.contains(scale) ? scale! : 1.0,
    );
  }

  Future<void> setLastRead(AyahRef ref) async {
    if (state.lastRead == ref) return;
    state = QuranReading(
      lastRead: ref,
      bookmarks: state.bookmarks,
      textScale: state.textScale,
    );
    await _prefs.setString(_kLastRead, ref.toString());
  }

  Future<void> toggleBookmark(AyahRef ref) async {
    final bookmarks = state.isBookmarked(ref)
        ? state.bookmarks.where((b) => b != ref).toList()
        : [ref, ...state.bookmarks];
    state = QuranReading(
      lastRead: state.lastRead,
      bookmarks: List.unmodifiable(bookmarks),
      textScale: state.textScale,
    );
    await _prefs.setStringList(
      _kBookmarks,
      bookmarks.map((b) => b.toString()).toList(),
    );
  }

  Future<void> setTextScale(double scale) async {
    state = QuranReading(
      lastRead: state.lastRead,
      bookmarks: state.bookmarks,
      textScale: scale,
    );
    await _prefs.setDouble(_kTextScale, scale);
  }
}

final quranReadingProvider =
    NotifierProvider<QuranReadingNotifier, QuranReading>(
      QuranReadingNotifier.new,
    );
