import 'package:bedug/core/services/selection_feedback.dart';
import 'package:bedug/features/prayer_times/widgets/prayer_day_picker.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 20);

  Widget app() {
    var selected = today;
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
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

  testWidgets('picks future and past days and jumps back to today',
      (tester) async {
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

  testWidgets('picks the centered day while scrolling, with a tick for each',
      (tester) async {
    var ticks = 0;
    SelectionFeedback.debugOverride = () => ticks++;
    addTearDown(() => SelectionFeedback.debugOverride = null);
    await tester.pumpWidget(app());

    // Drag three chips (64 px each) left past the touch slop, then hold
    // still before lifting so nothing flings.
    final gesture = await tester
        .startGesture(tester.getCenter(find.byType(CustomScrollView)));
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

  test('counts calendar days across a year boundary', () {
    expect(daysBetween(today, DateTime(2027, 1, 1, 23, 59)), 73);
    expect(daysBetween(today, DateTime(2026, 10, 19)), -1);
    expect(addDays(today, 73), DateTime(2027, 1, 1));
  });
}
