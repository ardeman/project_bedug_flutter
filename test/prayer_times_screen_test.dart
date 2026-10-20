import 'package:adhan/adhan.dart';
import 'package:bedug/core/design/platform_capabilities.dart';
import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:bedug/features/prayer_times/prayer_times_screen.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
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
    // goes from 240 to a toolbar plus 44 off iOS, the Material app bar from
    // 200 to a toolbar.
    final collapseRange = PlatformCapabilities.isApple
        ? 240 - (kToolbarHeight + 44)
        : 200 - kToolbarHeight;
    expect(position.maxScrollExtent, moreOrLessEquals(collapseRange));

    await tester.fling(page, const Offset(0, -1500), 3000);
    await tester.pumpAndSettle();
    expect(position.pixels, moreOrLessEquals(collapseRange));
  });
}
