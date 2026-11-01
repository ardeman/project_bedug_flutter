import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/theme/app_theme_scope.dart';
import 'package:bedug/features/fasting/fasting_log.dart';
import 'package:bedug/features/fasting/fasting_log_screen.dart';
import 'package:bedug/features/fasting/ramadan_card.dart';
import 'package:adhan/adhan.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:clock/clock.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Noon on a Umm al-Qura date.
DateTime _noon(int year, int month, int day) {
  final date = HijriCalendar().hijriToGregorian(year, month, day);
  return DateTime(date.year, date.month, date.day, 12);
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Widget home = const FastingLogScreen(),
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
        builder: (context, child) => AppThemeScope(child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('logs Ramadan days and counts what is owed', (tester) async {
    await withClock(Clock.fixed(_noon(1447, 9, 3)), () async {
      final container = await _pump(tester);
      expect(find.text('Ramadan 1447 AH'), findsOneWidget);
      expect(find.text('No fasts to make up'), findsOneWidget);

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Missed').last);
      await tester.pumpAndSettle();
      expect(find.text('1 fast to make up'), findsOneWidget);

      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fasted').last);
      await tester.pumpAndSettle();
      expect(find.text('1 of 30 days fasted'), findsOneWidget);
      final log = container.read(fastingLogProvider);
      expect(log.statusOn(_noon(1447, 9, 2)), FastStatus.fasted);

      // Days still ahead can't be logged, and a make-up fast can't be kept
      // in Ramadan.
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
      expect(find.text('Excused'), findsNothing);
      expect(find.text('Log a make-up fast today'), findsNothing);
    });
  });

  testWidgets('logs a make-up fast after Ramadan', (tester) async {
    await withClock(Clock.fixed(_noon(1447, 11, 5)), () async {
      final container = await _pump(tester);
      expect(find.textContaining('Ramadan 1448 AH begins on'), findsOneWidget);
      await tester.tap(find.text('Log a make-up fast today'));
      await tester.pumpAndSettle();
      expect(
        container.read(fastingLogProvider).statusOn(_noon(1447, 11, 5)),
        FastStatus.qada,
      );
      expect(find.text("Remove today's make-up fast"), findsOneWidget);
    });
  });

  testWidgets('renders the glass path on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await withClock(Clock.fixed(_noon(1447, 9, 3)), () async {
        await _pump(tester);
        expect(find.text('Ramadan 1447 AH'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the card counts down to iftar during a fast', (tester) async {
    final noon = _noon(1447, 9, 3);
    // On the equator at the local meridian, so Maghrib is this evening.
    final times = PrayerTimes(
      Coordinates(0, noon.timeZoneOffset.inMinutes / 4),
      DateComponents(noon.year, noon.month, noon.day),
      CalculationMethod.singapore.getParameters(),
    );
    Widget card() => Scaffold(body: RamadanCard(times: times));
    await withClock(Clock.fixed(noon), () async {
      await _pump(tester, home: card());
      expect(find.text('Ramadan 3'), findsOneWidget);
      expect(find.text('Until iftar'), findsOneWidget);
    });
    await withClock(Clock.fixed(_noon(1447, 11, 5)), () async {
      await _pump(tester, home: card());
      expect(find.text('Until iftar'), findsNothing);
    });
    // Stop the card's ticker.
    await tester.pumpWidget(const SizedBox());
  });
}
