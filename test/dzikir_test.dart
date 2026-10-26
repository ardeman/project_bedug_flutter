import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;

import 'dart:io';

import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:bedug/features/dzikir/dzikir.dart';
import 'package:bedug/features/dzikir/dzikir_screen.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoPrayerTimes extends PrayerNotifier {
  @override
  PrayerState build() => const PrayerState(loading: false);
}

void main() {
  final collections = {
    for (final MapEntry(:key, :value) in dzikirCollectionAssets.entries)
      key: parseDzikirCollection(File(value).readAsStringSync()),
  };

  test('every collection is complete in every app language', () {
    final languages = AppLocalizations.supportedLocales
        .map((l) => l.languageCode)
        .toSet();
    expect(collections, contains(defaultDzikirCollectionId));
    for (final MapEntry(:key, value: collection) in collections.entries) {
      expect(collection.id, key);
      expect(collection.name.keys.toSet(), languages, reason: key);
      expect(collection.source.keys.toSet(), languages, reason: key);
      for (final session in DzikirSession.values) {
        expect(
          collection.itemsFor(session),
          isNotEmpty,
          reason: '$key $session',
        );
      }
      for (final item in collection.items) {
        final reason = '$key: ${item.transliteration}';
        expect(item.sessions, isNotEmpty, reason: reason);
        expect(item.arabic.trim(), isNotEmpty, reason: reason);
        expect(item.transliteration.trim(), isNotEmpty, reason: reason);
        // A hadith number, verse or page, so readers can look it up.
        expect(item.reference, contains(RegExp(r'\d')), reason: reason);
        expect(item.repeat, greaterThan(0), reason: reason);
        // Arabic readers read the text itself, so it has no translation.
        expect(item.translation.keys.toSet(), languages.difference({'ar'}));
        expect(item.translationFor('ar'), isNull);
      }
    }
  });

  group('dzikirSessionAt', () {
    final fajr = DateTime(2026, 10, 27, 4, 30);
    final asr = DateTime(2026, 10, 27, 15, 10);
    DzikirSession at(int hour, int minute) => dzikirSessionAt(
      DateTime(2026, 10, 27, hour, minute),
      fajr: fajr,
      asr: asr,
    );

    test('is morning from Subuh until Asar', () {
      expect(at(4, 30), DzikirSession.morning);
      expect(at(15, 9), DzikirSession.morning);
    });

    test('is evening from Asar until the next Subuh', () {
      expect(at(15, 10), DzikirSession.evening);
      expect(at(23, 0), DzikirSession.evening);
      expect(at(4, 29), DzikirSession.evening);
    });

    test('falls back to fixed hours without prayer times', () {
      expect(
        dzikirSessionAt(DateTime(2026, 10, 27, 14)),
        DzikirSession.morning,
      );
      expect(
        dzikirSessionAt(DateTime(2026, 10, 27, 16)),
        DzikirSession.evening,
      );
    });
  });

  test('an unknown stored collection falls back to the default', () async {
    SharedPreferences.setMockInitialValues({'dzikir_collection': 'removed'});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(
      container.read(dzikirCollectionIdProvider),
      defaultDzikirCollectionId,
    );
  });

  testWidgets('opens on the current session and switches', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final collection = collections[defaultDzikirCollectionId]!;
    // Tall enough that the lazy list builds the first session-only items.
    tester.view.physicalSize = const Size(800, 12000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await withClock(Clock.fixed(DateTime(2026, 10, 27, 7)), () async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            prayerProvider.overrideWith(_NoPrayerTimes.new),
            dzikirCollectionsProvider.overrideWith((ref) async => [collection]),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              ...AppLocalizations.localizationsDelegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: DzikirScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    final morningOnly = collection.items.firstWhere(
      (i) =>
          i.sessions.length == 1 && i.sessions.contains(DzikirSession.morning),
    );
    final eveningOnly = collection.items.firstWhere(
      (i) =>
          i.sessions.length == 1 && i.sessions.contains(DzikirSession.evening),
    );
    expect(find.text('Morning and evening dzikir'), findsOneWidget);
    expect(find.text(collection.items.first.arabic), findsOneWidget);
    expect(find.text(morningOnly.arabic, skipOffstage: false), findsOneWidget);
    expect(find.text(eveningOnly.arabic, skipOffstage: false), findsNothing);

    await tester.tap(find.text('Evening'));
    await tester.pumpAndSettle();
    expect(find.text(eveningOnly.arabic, skipOffstage: false), findsOneWidget);
    expect(find.text(morningOnly.arabic, skipOffstage: false), findsNothing);
  });
}
