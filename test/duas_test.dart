import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;

import 'dart:io';

import 'package:bedug/features/asmaul_husna/asmaul_husna.dart';
import 'package:bedug/features/asmaul_husna/asmaul_husna_screen.dart';
import 'package:bedug/features/duas/duas.dart';
import 'package:bedug/features/duas/duas_screen.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final languages = AppLocalizations.supportedLocales
      .map((l) => l.languageCode)
      .toSet();
  // Arabic readers read the text itself, so it has no translation.
  final translated = languages.difference({'ar'});
  final book = parseDuaBook(File(dailyDuasAsset).readAsStringSync());
  final asmaulHusna = parseAsmaulHusna(
    File(asmaulHusnaAsset).readAsStringSync(),
  );

  test('every dua is complete in every app language', () {
    expect(book.source.keys.toSet(), languages);
    expect(book.categories, isNotEmpty);
    expect(
      book.categories.map((c) => c.id).toSet(),
      hasLength(book.categories.length),
    );
    for (final category in book.categories) {
      expect(category.name.keys.toSet(), languages, reason: category.id);
      expect(category.items, isNotEmpty, reason: category.id);
      for (final dua in category.items) {
        final reason = '${category.id}: ${dua.transliteration}';
        expect(dua.title.keys.toSet(), languages, reason: reason);
        expect(dua.arabic.trim(), isNotEmpty, reason: reason);
        expect(dua.transliteration.trim(), isNotEmpty, reason: reason);
        // A hadith number or verse, so readers can look it up.
        expect(dua.reference, contains(RegExp(r'\d')), reason: reason);
        expect(dua.translation.keys.toSet(), translated, reason: reason);
        expect(dua.translationFor('ar'), isNull);
      }
    }
  });

  test('the Asmaul Husna has 99 distinct names, each with its meaning', () {
    expect(asmaulHusna.source.keys.toSet(), languages);
    expect(asmaulHusna.names, hasLength(99));
    expect(asmaulHusna.names.map((n) => n.arabic).toSet(), hasLength(99));
    for (final name in asmaulHusna.names) {
      expect(name.transliteration.trim(), isNotEmpty);
      expect(name.meaning.keys.toSet(), translated, reason: name.arabic);
      expect(name.meaningFor('ar'), isNull);
    }
    expect(asmaulHusna.names.first.transliteration, 'Ar-Raḥmān');
    expect(asmaulHusna.names.last.transliteration, 'Aṣ-Ṣabūr');
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          duaBookProvider.overrideWith((ref) async => book),
          asmaulHusnaProvider.overrideWith((ref) async => asmaulHusna),
        ],
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
  }

  testWidgets('lists the situations and opens one\'s duas', (tester) async {
    await pump(tester, const DuasScreen());

    for (final category in book.categories) {
      expect(find.text(category.nameFor('en')), findsOneWidget);
    }
    final eating = book.categories.firstWhere((c) => c.id == 'eating');
    await tester.tap(find.text(eating.nameFor('en')));
    await tester.pumpAndSettle();

    for (final dua in eating.items) {
      expect(find.text(dua.titleFor('en')), findsOneWidget);
      expect(find.text(dua.arabic), findsOneWidget);
      expect(find.text(dua.translationFor('en')!), findsOneWidget);
    }
  });

  testWidgets('numbers the names from 1', (tester) async {
    await pump(tester, const AsmaulHusnaScreen());

    final first = asmaulHusna.names.first;
    expect(find.text('1'), findsOneWidget);
    expect(find.text(first.arabic), findsOneWidget);
    expect(find.text(first.meaningFor('en')!), findsOneWidget);
  });
}
