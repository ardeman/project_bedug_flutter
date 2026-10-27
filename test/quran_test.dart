import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;

import 'dart:io';

import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/features/quran/khatam.dart';
import 'package:bedug/features/quran/quran.dart';
import 'package:bedug/features/quran/quran_reader_screen.dart';
import 'package:bedug/features/quran/quran_screen.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final languages = AppLocalizations.supportedLocales
      .map((l) => l.languageCode)
      .toSet();
  final index = parseQuranIndex(File(quranIndexAsset).readAsStringSync());
  final text = parseQuranText(File(quranTextAsset).readAsStringSync());
  final english = parseQuranText(
    File(quranTranslationAsset('en')!).readAsStringSync(),
  );

  test('the index lists 114 surahs, 6236 ayahs and 30 juz', () {
    expect(index.surahs, hasLength(114));
    expect(index.surahs.fold(0, (sum, s) => sum + s.ayahCount), 6236);
    expect(index.juzStarts, hasLength(30));
    for (final surah in index.surahs) {
      expect(surah.name.keys.toSet(), languages.difference({'ar'}));
    }
    expect(index.surah(1).nameFor('id'), 'Al-Fatihah');
    expect(index.surah(1).nameFor('ar'), 'الفاتحة');
    expect(index.surah(9).revelation, Revelation.medinan);
  });

  test('the text and every translation have each surah\'s ayahs', () {
    final counts = [for (final s in index.surahs) s.ayahCount];
    expect(text.surahs.map((s) => s.length), counts);
    expect(quranTranslationAsset('ar'), isNull);
    for (final language in languages.difference({'ar'})) {
      final translation = parseQuranText(
        File(quranTranslationAsset(language)!).readAsStringSync(),
      );
      expect(translation.surahs.map((s) => s.length), counts, reason: language);
      expect(translation.source, isNotEmpty, reason: language);
    }
  });

  test('the basmala moves out of each first ayah into the heading', () {
    final basmala = text.ayah(const AyahRef(1, 1));
    expect(ayahWithoutBasmala(text, const AyahRef(1, 1)), basmala);
    expect(ayahWithoutBasmala(text, const AyahRef(2, 1)), 'الٓمٓ');
    expect(
      ayahWithoutBasmala(text, const AyahRef(2, 2)),
      text.ayah(const AyahRef(2, 2)),
    );
    expect(
      ayahWithoutBasmala(text, const AyahRef(9, 1)),
      isNot(startsWith(basmala)),
    );
    for (var surah = 2; surah <= 114; surah++) {
      expect(
        ayahWithoutBasmala(text, AyahRef(surah, 1)),
        isNot(startsWith(basmala)),
        reason: '$surah',
      );
    }
    expect(hasBasmalaHeading(1), isFalse);
    expect(hasBasmalaHeading(9), isFalse);
    expect(hasBasmalaHeading(2), isTrue);
  });

  test('finds the juz of an ayah', () {
    expect(index.juzOf(const AyahRef(1, 1)), 1);
    expect(index.juzOf(const AyahRef(2, 141)), 1);
    expect(index.juzOf(const AyahRef(2, 142)), 2);
    expect(index.juzOf(const AyahRef(114, 6)), 30);
  });

  test('parses ayah references and rejects malformed ones', () {
    expect(AyahRef.tryParse('2:255'), const AyahRef(2, 255));
    expect(AyahRef.tryParse('2'), isNull);
    expect(AyahRef.tryParse('a:b'), isNull);
    expect(AyahRef.tryParse(null), isNull);
    expect(index.contains(const AyahRef(1, 8)), isFalse);
    expect(index.contains(const AyahRef(115, 1)), isFalse);
  });

  Future<ProviderContainer> containerWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('keeps the last-read ayah, bookmarks and text size', () async {
    final container = await containerWith({});
    final notifier = container.read(quranReadingProvider.notifier);
    await notifier.setLastRead(const AyahRef(18, 10));
    await notifier.toggleBookmark(const AyahRef(2, 255));
    await notifier.toggleBookmark(const AyahRef(36, 1));
    await notifier.toggleBookmark(const AyahRef(2, 255));
    await notifier.setTextScale(1.3);

    final prefs = container.read(sharedPreferencesProvider);
    final restored = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restored.dispose);
    final reading = restored.read(quranReadingProvider);
    expect(reading.lastRead, const AyahRef(18, 10));
    expect(reading.bookmarks, [const AyahRef(36, 1)]);
    expect(reading.textScale, 1.3);
  });

  test('ignores a stored text size the reader no longer offers', () async {
    final container = await containerWith({'quran_text_scale': 9.0});
    expect(container.read(quranReadingProvider).textScale, 1.0);
  });

  test('counts ayahs across the whole Quran', () {
    expect(index.ayahCount, 6236);
    expect(index.lastAyah, const AyahRef(114, 6));
    expect(index.ordinalOf(const AyahRef(1, 1)), 0);
    expect(index.ordinalOf(const AyahRef(2, 1)), 7);
    for (final ref in [
      const AyahRef(2, 255),
      const AyahRef(36, 1),
      index.lastAyah,
    ]) {
      expect(index.ayahAt(index.ordinalOf(ref)), ref);
    }
  });

  test('measures khatam progress in juz', () {
    expect(juzProgress(index, null), 0);
    expect(juzProgress(index, index.lastAyah), 30);
    // The ayah before a juz starts ends the previous juz.
    final juz2 = index.juzStarts[1];
    final endOfJuz1 = index.ayahAt(index.ordinalOf(juz2) - 1);
    expect(juzProgress(index, endOfJuz1), closeTo(1, 1e-9));
    expect(ayahAtProgress(index, 1), endOfJuz1);
    expect(ayahAtProgress(index, 30), index.lastAyah);
    expect(ayahAtProgress(index, 0), isNull);
    // Halfway through a juz lands halfway through its ayahs.
    final half = ayahAtProgress(index, 29.5)!;
    expect(juzProgress(index, half), greaterThanOrEqualTo(29.5));
    expect(index.juzOf(half), 30);
  });

  test('spreads a khatam plan evenly over its days', () {
    final plan = KhatamPlan(
      start: DateTime.utc(2026, 11, 1),
      finish: DateTime.utc(2026, 11, 30),
    );
    final endOfJuz = [
      for (final start in index.juzStarts.skip(1))
        index.ayahAt(index.ordinalOf(start) - 1),
    ];
    expect(plan.days, 30);
    expect(plan.targetFor(index, DateTime(2026, 11, 1, 23)), endOfJuz[0]);
    expect(plan.targetFor(index, DateTime(2026, 11, 2)), endOfJuz[1]);
    expect(plan.targetFor(index, DateTime(2026, 12, 5)), index.lastAyah);
    expect(plan.daysLeft(DateTime(2026, 11, 30, 8)), 1);
    expect(plan.daysLeft(DateTime(2026, 12, 1)), 0);
    expect(plan.next(index), const AyahRef(1, 1));
    expect(
      plan.withReached(const AyahRef(1, 7)).next(index),
      const AyahRef(2, 1),
    );

    // A plan begun mid-way spreads only what is left.
    final rest = KhatamPlan(
      start: DateTime.utc(2026, 11, 1),
      finish: DateTime.utc(2026, 11, 2),
      from: endOfJuz[27],
    );
    expect(rest.targetFor(index, DateTime(2026, 11, 1)), endOfJuz[28]);
    expect(rest.targetFor(index, DateTime(2026, 11, 2)), index.lastAyah);
  });

  test(
    'keeps the khatam plan and carries progress into a new length',
    () async {
      final container = await containerWith({});
      final notifier = container.read(khatamProvider.notifier);
      await notifier.markRead(const AyahRef(2, 1));
      expect(container.read(khatamProvider), isNull);

      await notifier.start(today: DateTime(2026, 11, 1, 21), days: 30);
      await notifier.markRead(const AyahRef(2, 141));
      await notifier.start(today: DateTime(2026, 11, 5), days: 7);

      final prefs = container.read(sharedPreferencesProvider);
      final restored = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restored.dispose);
      final plan = restored.read(khatamProvider)!;
      expect(plan.start, DateTime.utc(2026, 11, 5));
      expect(plan.finish, DateTime.utc(2026, 11, 11));
      expect(plan.from, const AyahRef(2, 141));
      expect(plan.reached, const AyahRef(2, 141));

      await restored.read(khatamProvider.notifier).end();
      expect(prefs.getString('quran_khatam'), isNull);
    },
  );

  test('ignores a malformed stored khatam plan', () async {
    final container = await containerWith({'quran_khatam': '{"start": 1}'});
    expect(container.read(khatamProvider), isNull);
  });

  Future<ProviderContainer> pump(WidgetTester tester, Widget home) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localeProvider.overrideWith(_EnglishLocale.new),
        quranIndexProvider.overrideWith((ref) async => index),
        quranTextProvider.overrideWith((ref) async => text),
        quranTranslationProvider.overrideWith((ref) async => english),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('opens a surah from the list and remembers it', (tester) async {
    final container = await pump(tester, const QuranScreen());

    expect(find.text('Al-Faatiha'), findsOneWidget);
    await tester.tap(find.text('Al-Baqara'));
    await tester.pumpAndSettle();

    expect(find.text('الٓمٓ'), findsOneWidget);
    expect(find.text(english.ayah(const AyahRef(2, 2))), findsOneWidget);
    expect(container.read(quranReadingProvider).lastRead, const AyahRef(2, 1));
  });

  testWidgets('opens at an ayah and bookmarks it', (tester) async {
    final container = await pump(
      tester,
      const QuranReaderScreen(surah: 2, initialAyah: 255),
    );

    final ayatAlKursi = find.text(english.ayah(const AyahRef(2, 255)));
    expect(ayatAlKursi, findsOneWidget);
    // The ayah sits at the top, with the ones before it built above.
    expect(tester.getTopLeft(find.text('2:255')).dy, lessThan(100));

    // Scrolling up reaches the ayahs before it.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('2:254'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey(255)),
        matching: find.byTooltip('Bookmark verse'),
      ),
    );
    await tester.pump();
    expect(container.read(quranReadingProvider).bookmarks, [
      const AyahRef(2, 255),
    ]);
  });

  testWidgets('starts a khatam plan and marks reading in the reader', (
    tester,
  ) async {
    final container = await pump(tester, const QuranScreen());

    expect(find.text('Khatam planner'), findsOneWidget);
    await tester.tap(find.text('7 days'));
    await tester.pump();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(container.read(khatamProvider)!.days, 7);
    expect(find.textContaining('Today: read up to'), findsOneWidget);

    await tester.tap(find.text('Continue reading').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey(7)),
        matching: find.byTooltip('Mark as read up to here'),
      ),
    );
    await tester.pump();
    expect(container.read(khatamProvider)!.reached, const AyahRef(1, 7));
  });

  testWidgets('steps the text size from the top bar', (tester) async {
    final container = await pump(tester, const QuranReaderScreen(surah: 1));

    await tester.tap(find.byTooltip('Larger text'));
    await tester.pump();
    expect(container.read(quranReadingProvider).textScale, 1.15);
    await tester.tap(find.byTooltip('Smaller text'));
    await tester.tap(find.byTooltip('Smaller text'));
    await tester.pump();
    expect(container.read(quranReadingProvider).textScale, 0.9);
  });
}

class _EnglishLocale extends LocaleNotifier {
  @override
  Locale build() => const Locale('en');
}
