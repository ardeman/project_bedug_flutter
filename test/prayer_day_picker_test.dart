import 'package:bedug/core/design/liquid_glass.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/theme/app_theme_scope.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:bedug/core/services/selection_feedback.dart';
import 'package:bedug/core/utils/hijri_utils.dart';
import 'package:bedug/features/prayer_times/widgets/hijri_month_grid.dart';
import 'package:bedug/features/prayer_times/widgets/prayer_day_picker.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 20);

  Widget app() {
    var selected = today;
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (ctx, setState) => PrayerDayPicker(
            today: today,
            selected: selected,
            onSelected: (d) => setState(() => selected = d),
          ),
        ),
      ),
    );
  }

  for (final brightness in Brightness.values) {
    for (final locale in ['en', 'ar']) {
      testWidgets(
        'calendar fits narrow layouts with large text in $brightness $locale',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(brightness),
              locale: Locale(locale),
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                ...AppLocalizations.localizationsDelegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => AppThemeScope(
                child: MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(2)),
                  child: child!,
                ),
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: PrayerDayPicker(
                    today: today,
                    selected: today.subtract(const Duration(days: 1)),
                    onSelected: (_) {},
                  ),
                ),
              ),
            ),
          );
          expect(find.byType(GlassCard), findsOneWidget);
          await tester.tap(find.byIcon(Icons.calendar_month_outlined));
          await tester.pumpAndSettle();
          expect(find.byType(HijriMonthGrid), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant({
          TargetPlatform.iOS,
          TargetPlatform.macOS,
          TargetPlatform.android,
          TargetPlatform.windows,
          TargetPlatform.linux,
        }),
      );
    }
  }

  testWidgets('picks future and past days and jumps back to today', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    expect(find.text('Tuesday, October 20'), findsOneWidget);
    expect(find.text('Today'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Wednesday, October 21, 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Wednesday, October 21'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Monday, October 19, 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Monday, October 19'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Tuesday, October 20'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('picks the centered day while scrolling, with a tick for each', (
    tester,
  ) async {
    var ticks = 0;
    SelectionFeedback.debugOverride = () => ticks++;
    addTearDown(() => SelectionFeedback.debugOverride = null);
    await tester.pumpWidget(app());

    // Drag three chips (64 px each) left past the touch slop, then hold
    // still before lifting so nothing flings.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CustomScrollView)),
    );
    for (var i = 0; i < 14; i++) {
      await gesture.moveBy(const Offset(-15, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Friday, October 23'), findsOneWidget);
    expect(ticks, 3);
  });

  testWidgets('scrolls without end into the past', (tester) async {
    await tester.pumpWidget(app());

    for (var i = 0; i < 10; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(800, 0));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    // 8000 px of drag at 64 px a chip lands about four months back.
    expect(find.bySemanticsLabel('Tuesday, October 20, 2026'), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'June \d+, 2026$')), findsWidgets);
  });

  testWidgets('picks days from the expanded Hijri month grid', (tester) async {
    await tester.pumpWidget(app());
    final month = hijriMonthOf(today);
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    final shownTitle = '${hijriMonthName(l10n, month.month)} ${month.year} H';
    expect(find.text(shownTitle), findsNothing);

    await tester.tap(find.bySemanticsLabel('Hijri Calendar'));
    await tester.pumpAndSettle();
    expect(find.text(shownTitle), findsOneWidget);
    // The grid takes the strip's place.
    expect(
      find.bySemanticsLabel('Wednesday, October 21, 2026').hitTestable(),
      findsNothing,
    );

    // A day in the grid picks its Gregorian date, and the strip follows.
    await tester.tap(
      find.bySemanticsLabel(RegExp(r'H, Wednesday, October 28, 2026$')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Wednesday, October 28'), findsOneWidget);

    // Paging months leaves the picked day alone; "Today" brings its month
    // back.
    await tester.tap(find.bySemanticsLabel('Next month'));
    await tester.pumpAndSettle();
    expect(find.text(shownTitle), findsNothing);
    expect(find.text('Wednesday, October 28'), findsOneWidget);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text(shownTitle), findsOneWidget);
    expect(find.text('Tuesday, October 20'), findsOneWidget);

    // With today already picked, "Today" shows only once the grid pages
    // away, and brings its month back.
    expect(find.text('Today'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text(shownTitle), findsNothing);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text(shownTitle), findsOneWidget);
    expect(find.text('Today'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Hijri Calendar'));
    await tester.pumpAndSettle();
    expect(find.text(shownTitle), findsNothing);
  });

  testWidgets('moves the picked chip into its grid cell while opening', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    // Only today's strip chip names its month.
    final start = tester.getCenter(find.text('Oct'));

    await tester.tap(find.bySemanticsLabel('Hijri Calendar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final moving = tester.getCenter(
      find.descendant(
        of: find.byType(HijriMonthGrid),
        matching: find.text('Oct'),
      ),
    );
    // Tuesday's column is left of the middle, and the weeks sit below the
    // month header.
    expect(moving.dx, lessThan(start.dx));
    expect(moving.dy, greaterThan(start.dy));

    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(HijriMonthGrid),
        matching: find.text('Oct'),
      ),
      findsNothing,
    );
  });

  testWidgets('shows the picked day as a Hijri date', (tester) async {
    await tester.pumpWidget(app());
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    expect(find.text(hijriDateLabel(l10n, today)!), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Wednesday, October 21, 2026'));
    await tester.pumpAndSettle();
    expect(
      find.text(hijriDateLabel(l10n, DateTime(2026, 10, 21))!),
      findsOneWidget,
    );
  });

  testWidgets('pulls the handle down to open the grid and up to close it', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    final month = hijriMonthOf(today);
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    final shownTitle = '${hijriMonthName(l10n, month.month)} ${month.year} H';
    final handle = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_DragHandle',
    );

    // A short, slow pull that stops before halfway springs back closed.
    await tester.timedDrag(
      handle,
      const Offset(0, 60),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(find.text(shownTitle), findsNothing);

    await tester.drag(handle, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text(shownTitle), findsOneWidget);

    await tester.drag(handle, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text(shownTitle), findsNothing);
  });

  test('labels dates outside the Hijri table with nothing', () {
    expect(
      hijriDateLabel(
        lookupAppLocalizations(const Locale('en')),
        DateTime(1900),
      ),
      isNull,
    );
  });

  test('clamps Hijri months to the supported table', () {
    expect(hijriMonthOf(DateTime(1900)), (year: 1356, month: 1));
    expect(hijriMonthOf(DateTime(2100)), (year: 1499, month: 12));
  });

  test('counts calendar days across a year boundary', () {
    expect(daysBetween(today, DateTime(2027, 1, 1, 23, 59)), 73);
    expect(daysBetween(today, DateTime(2026, 10, 19)), -1);
    expect(addDays(today, 73), DateTime(2027, 1, 1));
  });
}
