import 'dart:math' show max;

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;

import 'dart:io';

import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/features/quran/khatam.dart';
import 'package:bedug/features/quran/quran.dart';
import 'package:bedug/features/quran/quran_ayah_sheet.dart';
import 'package:bedug/features/quran/quran_mushaf.dart';
import 'package:bedug/features/quran/quran_reader_screen.dart';
import 'package:bedug/features/quran/quran_screen.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:flutter/rendering.dart';
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

  test('splits the Quran into the 604 pages of the Madinah mushaf', () {
    expect(index.pageCount, 604);
    expect(index.ayahsOnPage(1), [for (var a = 1; a <= 7; a++) AyahRef(1, a)]);
    expect(index.pageOf(const AyahRef(2, 255)), 42);
    expect(index.ayahsOnPage(604).last, index.lastAyah);
    var ayahs = 0;
    for (var page = 1; page <= index.pageCount; page++) {
      ayahs += index.ayahsOnPage(page).length;
    }
    expect(ayahs, index.ayahCount);
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
    await notifier.setPageMode(true);

    final prefs = container.read(sharedPreferencesProvider);
    final restored = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restored.dispose);
    final reading = restored.read(quranReadingProvider);
    expect(reading.lastRead, const AyahRef(18, 10));
    expect(reading.bookmarks, [const AyahRef(36, 1)]);
    expect(reading.textScale, 1.3);
    expect(reading.pageMode, isTrue);
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

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget home, {
    Size size = const Size(800, 2000),
    // Most tests read the list; mushaf pages are the default.
    Map<String, Object> prefsValues = const {'quran_page_mode': false},
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = size;
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

  group('the surah heading stays clear of the glass top bar', () {
    double headingTop(WidgetTester tester) =>
        tester.getTopLeft(find.text(index.surah(2).arabic)).dy;

    testWidgets('when opened at the first ayah', (tester) async {
      await pump(tester, const QuranReaderScreen(surah: 2, initialAyah: 1));
      expect(headingTop(tester), greaterThanOrEqualTo(kToolbarHeight));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('when scrolled back to the top', (tester) async {
      await pump(tester, const QuranReaderScreen(surah: 2, initialAyah: 5));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 1500));
      await tester.pumpAndSettle();
      expect(headingTop(tester), greaterThanOrEqualTo(kToolbarHeight));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
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

  testWidgets('switches to mushaf pages at the ayah being read', (
    tester,
  ) async {
    final container = await pump(
      tester,
      const QuranReaderScreen(surah: 2, initialAyah: 255),
    );

    await tester.tap(find.byTooltip('Page view'));
    await tester.pumpAndSettle();
    expect(container.read(quranReadingProvider).pageMode, isTrue);
    expect(find.text('42'), findsOneWidget);
    // Pages fit their text, so the size buttons go.
    expect(find.byTooltip('Larger text'), findsNothing);

    // A short, slow drag lets the leaf fall back.
    final pages = find.byType(QuranMushafView);
    await tester.drag(pages, const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(find.text('42'), findsOneWidget);
    expect(find.text('43'), findsNothing);

    // Mid-drag the leaf folds back from a corner: the next page shows
    // where it lifted, and the page itself also on its back.
    final gesture = await tester.startGesture(
      tester.getBottomLeft(pages) + const Offset(20, -20),
    );
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(30, -5));
      await tester.pump();
    }
    expect(find.text('43'), findsOneWidget);
    expect(find.text('42'), findsNWidgets(2));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('42'), findsOneWidget);

    // Dragging right lifts the leaf over the spine on the right and turns
    // to the next page, as in the book.
    await tester.fling(pages, const Offset(400, 0), 2000);
    await tester.pumpAndSettle();
    expect(find.text('43'), findsOneWidget);
    expect(find.text('42'), findsNothing);
    expect(container.read(quranReadingProvider).lastRead, index.pageStarts[42]);

    await tester.tap(find.byTooltip('List view'));
    await tester.pumpAndSettle();
    expect(container.read(quranReadingProvider).pageMode, isFalse);
    expect(find.text('2:${index.pageStarts[42].ayah}'), findsOneWidget);
  });

  testWidgets('shows a tapped ayah\'s translation and bookmarks it', (
    tester,
  ) async {
    final container = await pump(
      tester,
      const QuranReaderScreen(surah: 2, initialAyah: 255),
      prefsValues: {'quran_page_mode': true},
    );

    const ayatAlKursi = AyahRef(2, 255);
    // Tap the ayah's first letters where the page lays them out.
    final page = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('\u06DD'),
    );
    final paragraph = tester.renderObject<RenderParagraph>(page);
    // Pause marks are drawn apart from the text, so only its first letters
    // are matched.
    final start = paragraph.text.toPlainText().indexOf(
      text.ayah(ayatAlKursi).substring(0, 10),
    );
    final letters = paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: start + 10),
        )
        .first
        .toRect();
    final tap = paragraph.localToGlobal(letters.center);
    await tester.tapAt(tap);
    await tester.pumpAndSettle();
    expect(find.text(english.ayah(ayatAlKursi)), findsOneWidget);
    // The sheet repeats the Arabic only when it covers the tapped ayah.
    final covered =
        tap.dy >
        tester.view.physicalSize.height / tester.view.devicePixelRatio / 2;
    expect(
      find.text(text.ayah(ayatAlKursi)),
      covered ? findsOneWidget : findsNothing,
    );

    await tester.tap(find.text('Bookmark verse'));
    await tester.pump();
    expect(container.read(quranReadingProvider).bookmarks, [ayatAlKursi]);
    expect(find.text('Remove bookmark'), findsOneWidget);
  });

  testWidgets('the ayah sheet covers taps in the lower half of the screen', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox();
        },
      ),
    );
    final height = MediaQuery.sizeOf(ctx).height;
    expect(ayahSheetCovers(ctx, Offset(0, height * 0.3)), isFalse);
    expect(ayahSheetCovers(ctx, Offset(0, height * 0.7)), isTrue);
  });

  test(
    'fits opening text to a rounded rectangle, narrowest at the corners',
    () {
      final widths = List.filled(40, 3.0);
      final shaped = fitTextToRoundedRect(
        widths: widths,
        space: 1,
        lineHeight: 2,
        size: const Size(200, 300),
        radius: 40,
      )!;
      final lines = shaped.lines;
      expect(lines.last.end, widths.length);
      final widest = lines.map((l) => l.width).reduce(max);
      // Away from the corners, lines span the whole width.
      expect(widest, 200);
      expect(lines.first.width, lessThan(widest));
      expect(lines.last.width, lessThan(widest));
      expect(lines.last.justified, isFalse);

      // A word can end its line, which is then centered.
      final broken = fitTextToRoundedRect(
        widths: widths,
        breakAfter: {0},
        space: 1,
        lineHeight: 2,
        size: const Size(200, 300),
        radius: 40,
      )!.lines.firstWhere((l) => l.end > 0);
      expect(broken.end, 1);
      expect(broken.justified, isFalse);
      // A larger size no longer fits.
      expect(
        fitTextToRoundedRect(
          widths: widths,
          space: 1,
          lineHeight: 2,
          size: Size(200 / 1.2, 300 / 1.2),
          radius: 40,
        )!.fontSize,
        lessThan(shaped.fontSize),
      );
    },
  );

  testWidgets('sets Al-Fatihah in the opening page\'s medallion', (
    tester,
  ) async {
    // A fresh install opens the reader on mushaf pages.
    await pump(tester, const QuranReaderScreen(surah: 1), prefsValues: {});

    expect(find.text('1'), findsOneWidget);
    expect(find.text('\u06DD\u0667'), findsOneWidget);
    await tester.tap(
      find.text(text.ayah(const AyahRef(1, 2)).split(' ').first),
    );
    await tester.pumpAndSettle();
    expect(find.text(english.ayah(const AyahRef(1, 2))), findsOneWidget);
  });

  testWidgets('lowers pause marks onto the words they follow', (tester) async {
    await pump(
      tester,
      const QuranReaderScreen(surah: 2),
      prefsValues: {'quran_page_mode': true},
    );

    // Al-Baqarah 2 pauses twice: لَا رَيْبَ ۛ فِيهِ ۛ. Each mark is set on a
    // base of its own, not left as a word between spaces.
    expect(find.text('\u00A0\u06DB'), findsNWidgets(2));
    expect(
      find.byWidgetPredicate((w) => w is Text && w.data == '\u06DB'),
      findsNothing,
    );
  });

  testWidgets('shows two facing pages in a wide window', (tester) async {
    await pump(
      tester,
      const QuranReaderScreen(surah: 2, initialAyah: 255),
      size: const Size(1600, 1000),
      prefsValues: {'quran_page_mode': true},
    );

    expect(find.text('41'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    // The odd page sits on the right.
    expect(
      tester.getCenter(find.text('41')).dx,
      greaterThan(tester.getCenter(find.text('42')).dx),
    );
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
