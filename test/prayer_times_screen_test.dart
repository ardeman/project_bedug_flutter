import 'package:adhan/adhan.dart';
import 'package:bedug/core/design/platform_capabilities.dart';
import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:bedug/features/prayer_times/prayer_times_screen.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePrayerNotifier extends PrayerNotifier {
  _FakePrayerNotifier(this._state);

  final PrayerState _state;

  @override
  PrayerState build() => _state;
}

void main() {
  testWidgets('a short day still scrolls the header to its compact bar',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // Taller than the header plus every card, so nothing would scroll.
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final times = PrayerTimes.today(
      Coordinates(-6.2088, 106.8456),
      CalculationMethod.singapore.getParameters(),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        prayerProvider.overrideWith(() => _FakePrayerNotifier(PrayerState(
              times: times,
              locationLabel: 'Jakarta',
              loading: false,
            ))),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PrayerTimesScreen(),
      ),
    ));
    await tester.pump();

    final page = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    final position = tester.state<ScrollableState>(page).position;
    // How far the header shrinks, expanded to compact: the glass header
    // goes from 260 to a toolbar on macOS (in line with the traffic lights)
    // or a toolbar plus 44 on iOS, the Material app bar from 200 to a
    // toolbar.
    final collapseRange = PlatformCapabilities.isMacOS
        ? 260 - kToolbarHeight
        : PlatformCapabilities.isApple
            ? 260 - (kToolbarHeight + 44)
            : 200 - kToolbarHeight;
    expect(position.maxScrollExtent, moreOrLessEquals(collapseRange));

    await tester.fling(page, const Offset(0, -1500), 3000);
    await tester.pumpAndSettle();
    expect(position.pixels, moreOrLessEquals(collapseRange));
  });
  testWidgets('the pill, place, name and countdown move into the capsule',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final times = PrayerTimes.today(
      Coordinates(-6.2088, 106.8456),
      CalculationMethod.singapore.getParameters(),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        prayerProvider.overrideWith(() => _FakePrayerNotifier(PrayerState(
              times: times,
              locationLabel: 'Jakarta',
              loading: false,
            ))),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PrayerTimesScreen(),
      ),
    ));
    await tester.pump();

    const moving = ValueKey('countdown-moving');
    if (find.byKey(moving).evaluate().isEmpty) {
      // Only the glass header moves its countdown, and after the day's
      // last prayer there is none.
      return;
    }
    void expectLanded(String place) {
      for (final part in ['pill', 'location', 'name', 'countdown']) {
        final target = part == 'countdown' && place == 'hero'
            ? 'countdown-badge'
            : '$part-$place';
        expect(tester.getRect(find.byKey(ValueKey('$part-moving'))),
            _rectCloseTo(tester.getRect(find.byKey(ValueKey(target)))),
            reason: '$part in the $place');
      }
    }

    expectLanded('hero');

    final page = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    // Halfway, the moving labels still fit: none is cut to an ellipsis.
    await tester.drag(page, const Offset(0, -80));
    await tester.pump();
    for (final part in ['location', 'name']) {
      final text = tester
          .renderObject<RenderParagraph>(find.byKey(ValueKey('$part-moving')));
      expect(text.didExceedMaxLines, isFalse, reason: '$part mid-collapse');
    }

    await tester.fling(page, const Offset(0, -1500), 3000);
    await tester.pumpAndSettle();
    expectLanded('capsule');
  });
}

Matcher _rectCloseTo(Rect expected) => isA<Rect>()
    .having(
        (r) => r.left, 'left', moreOrLessEquals(expected.left, epsilon: 0.5))
    .having((r) => r.top, 'top', moreOrLessEquals(expected.top, epsilon: 0.5))
    .having(
        (r) => r.width, 'width', moreOrLessEquals(expected.width, epsilon: 0.5))
    .having((r) => r.height, 'height',
        moreOrLessEquals(expected.height, epsilon: 0.5));
