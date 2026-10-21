import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:adhan/adhan.dart';
import 'package:clock/clock.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:bedug/core/design/platform_capabilities.dart';
import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:bedug/features/prayer_times/prayer_times_screen.dart';
import 'package:bedug/features/prayer_times/widgets/prayer_day_picker.dart';
import 'package:bedug/features/prayer_times/widgets/hijri_month_grid.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
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
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      'after-Isha header identifies the upcoming date in $locale',
      (tester) async {
        final times = PrayerTimes(
          Coordinates(-6.2088, 106.8456),
          DateComponents(2026, 10, 20),
          CalculationMethod.singapore.getParameters(),
        );
        final now = times.isha.add(const Duration(minutes: 1));
        await withClock(Clock.fixed(now), () async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = const Size(375, 932);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                prayerProvider.overrideWith(
                  () => _FakePrayerNotifier(
                    PrayerState(times: times, loading: false),
                  ),
                ),
              ],
              child: MaterialApp(
                locale: locale,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  ...AppLocalizations.localizationsDelegates,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: const PrayerTimesScreen(),
              ),
            ),
          );
          await tester.pump();
          final tomorrow = DateTime(2026, 10, 21);
          final date = DateFormat.MMMd(locale.languageCode).format(tomorrow);
          expect(find.textContaining(date), findsOneWidget);
          final header = tester.widget<Text>(find.textContaining(date)).data;
          final l10n = AppLocalizations.of(
            tester.element(find.byType(PrayerTimesScreen)),
          );
          expect(find.text(hijriDateLabel(l10n, tomorrow)!), findsOneWidget);
          expect(find.text(l10n.hijriAfterMaghrib), findsOneWidget);
          expect(
            tester
                .widget<PrayerDayPicker>(find.byType(PrayerDayPicker))
                .selected,
            DateTime(2026, 10, 20),
          );
          tester
              .widget<PrayerDayPicker>(find.byType(PrayerDayPicker))
              .onSelected(tomorrow);
          await tester.pump();
          expect(find.text(header!), findsOneWidget);
          expect(find.text(hijriDateLabel(l10n, tomorrow)!), findsOneWidget);
          expect(find.text(l10n.hijriAfterMaghrib), findsNothing);
          await tester.scrollUntilVisible(
            find.text(l10n.upNext),
            150,
            scrollable: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            ),
          );
          expect(find.text(l10n.upNext), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      },
      variant: TargetPlatformVariant({
        TargetPlatform.iOS,
        TargetPlatform.android,
      }),
    );
  }

  testWidgets('a short day still scrolls the header to its compact bar', (
    tester,
  ) async {
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          prayerProvider.overrideWith(
            () => _FakePrayerNotifier(
              PrayerState(
                times: times,
                locationLabel: 'Jakarta',
                loading: false,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: PrayerTimesScreen(),
        ),
      ),
    );
    await tester.pump();

    final page = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
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
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  testWidgets('the Material hero text travels into the collapsed toolbar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(393, 851);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final times = PrayerTimes.today(
      Coordinates(-6.2088, 106.8456),
      CalculationMethod.singapore.getParameters(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          prayerProvider.overrideWith(
            () => _FakePrayerNotifier(
              PrayerState(
                times: times,
                locationLabel:
                    'Kecamatan Pagedangan, Kabupaten Tangerang, Banten',
                loading: false,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: PrayerTimesScreen(),
        ),
      ),
    );
    await tester.pump();

    const name = ValueKey('material-name');
    const location = ValueKey('material-location');
    final tune = find.byIcon(Icons.tune);
    // Expanded, the place sits below the toolbar instead of beside the
    // tune and refresh buttons.
    expect(
      tester.getRect(find.byKey(location)).top,
      greaterThanOrEqualTo(tester.getRect(tune).bottom),
    );

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -400),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    // Tests have no status bar, so the collapsed toolbar is the top row.
    const toolbar = Rect.fromLTWH(0, 0, 393, kToolbarHeight);
    final nameRect = tester.getRect(find.byKey(name));
    final locationRect = tester.getRect(find.byKey(location));
    expect(nameRect.top, greaterThanOrEqualTo(toolbar.top));
    expect(locationRect.top, greaterThanOrEqualTo(nameRect.bottom - 1));
    expect(locationRect.bottom, lessThanOrEqualTo(toolbar.bottom));
    expect(locationRect.right, lessThanOrEqualTo(tester.getRect(tune).left));
  }, variant: const TargetPlatformVariant({TargetPlatform.android}));

  testWidgets('the pill, place, name and countdown move into the capsule', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final times = PrayerTimes.today(
      Coordinates(-6.2088, 106.8456),
      CalculationMethod.singapore.getParameters(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          prayerProvider.overrideWith(
            () => _FakePrayerNotifier(
              PrayerState(
                times: times,
                locationLabel: 'Jakarta',
                loading: false,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: PrayerTimesScreen(),
        ),
      ),
    );
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
        expect(
          tester.getRect(find.byKey(ValueKey('$part-moving'))),
          _rectCloseTo(tester.getRect(find.byKey(ValueKey(target)))),
          reason: '$part in the $place',
        );
      }
    }

    expectLanded('hero');

    final page = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    // Halfway, the moving labels still fit: none is cut to an ellipsis.
    await tester.drag(page, const Offset(0, -80));
    await tester.pump();
    for (final part in ['location', 'name']) {
      final text = tester.renderObject<RenderParagraph>(
        find.byKey(ValueKey('$part-moving')),
      );
      expect(text.didExceedMaxLines, isFalse, reason: '$part mid-collapse');
    }

    await tester.fling(page, const Offset(0, -1500), 3000);
    await tester.pumpAndSettle();
    expectLanded('capsule');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}

Matcher _rectCloseTo(Rect expected) => isA<Rect>()
    .having(
      (r) => r.left,
      'left',
      moreOrLessEquals(expected.left, epsilon: 0.5),
    )
    .having((r) => r.top, 'top', moreOrLessEquals(expected.top, epsilon: 0.5))
    .having(
      (r) => r.width,
      'width',
      moreOrLessEquals(expected.width, epsilon: 0.5),
    )
    .having(
      (r) => r.height,
      'height',
      moreOrLessEquals(expected.height, epsilon: 0.5),
    );
