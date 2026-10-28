import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

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
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final posture in [
      DisplayFeatureState.postureHalfOpened,
      DisplayFeatureState.postureFlat,
    ]) {
      for (final locale in ['en', 'ar']) {
        testWidgets('folded prayer panes: $platform $posture $locale', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = const Size(466, 678);
          tester.view.devicePixelRatio = 1;
          tester.view.padding = const FakeViewPadding(right: 84, bottom: 34);
          addTearDown(tester.view.reset);
          final times = PrayerTimes(
            Coordinates(-6.2088, 106.8456),
            DateComponents(2026, 10, 28),
            CalculationMethod.singapore.getParameters(),
          );
          await withClock(Clock.fixed(times.fajr), () async {
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
                  locale: Locale(locale),
                  theme: ThemeData(
                    brightness: locale == 'ar'
                        ? Brightness.dark
                        : Brightness.light,
                  ),
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                    ...AppLocalizations.localizationsDelegates,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(1.5),
                      displayFeatures: [
                        DisplayFeature(
                          bounds: Rect.fromLTWH(
                            0,
                            320,
                            466,
                            locale == 'ar' ? 0 : 16,
                          ),
                          type: locale == 'ar'
                              ? DisplayFeatureType.fold
                              : DisplayFeatureType.hinge,
                          state: posture,
                        ),
                      ],
                    ),
                    child: child!,
                  ),
                  home: const PrayerTimesScreen(),
                ),
              ),
            );
            await tester.pump();
            final summary = find.byKey(const ValueKey('folded-prayer-summary'));
            final split =
                platform == TargetPlatform.iOS &&
                posture == DisplayFeatureState.postureHalfOpened;
            expect(summary, split ? findsOneWidget : findsNothing);
            if (split) {
              final schedule = find.byKey(
                const ValueKey('folded-prayer-schedule'),
              );
              expect(tester.getBottomRight(summary).dy, 320);
              expect(
                tester.getTopLeft(schedule).dy,
                locale == 'ar' ? 320 : 336,
              );
              expect(tester.getBottomRight(schedule).dy, 678);
              final before = tester.getRect(summary);
              await tester.drag(schedule, const Offset(0, -220));
              await tester.pump();
              expect(tester.getRect(summary), before);
            }
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          });
        }, variant: TargetPlatformVariant.only(platform));
      }
    }
  }

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
  for (final config in [
    (locale: 'en', size: const Size(393, 851), scale: 1.0),
    (locale: 'ar', size: const Size(393, 851), scale: 1.0),
    (locale: 'en', size: const Size(851, 393), scale: 1.0),
    (locale: 'ar', size: const Size(320, 700), scale: 1.3),
  ]) {
    testWidgets('Material header aligns and collapses in $config', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = config.size;
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
          child: MaterialApp(
            locale: Locale(config.locale),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(config.scale)),
              child: child!,
            ),
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
      // The location shares the action's centerline and leaves it room.
      final expandedLocation = tester.getRect(find.byKey(location));
      final actions = tester.getRect(find.byIcon(Icons.refresh));
      expect(expandedLocation.center.dy, closeTo(actions.center.dy, 1));
      final isRtl = config.locale == 'ar';
      expect(expandedLocation.overlaps(actions), isFalse);
      final nameRectExpanded = tester.getRect(find.byKey(name));
      final labelRect = tester.getRect(
        find.byKey(const ValueKey('material-label')),
      );
      expect(
        isRtl ? nameRectExpanded.right : nameRectExpanded.left,
        closeTo(isRtl ? labelRect.right : labelRect.left, 1),
      );
      expect(nameRectExpanded.top, greaterThan(expandedLocation.bottom));
      final nameLeft = nameRectExpanded.left;
      expect(nameLeft, greaterThan(0));

      final badgeRect = tester.getRect(
        find.byKey(const ValueKey('material-badge')),
      );
      expect(
        isRtl ? badgeRect.right : badgeRect.left,
        closeTo(isRtl ? nameRectExpanded.right : nameRectExpanded.left, 1),
      );
      expect(badgeRect.bottom, lessThanOrEqualTo(200));

      // Scroll the page directly: at larger text sizes the center of the
      // viewport can land on the day picker's own drag gesture.
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(400);
      await tester.pump();
      expect(tester.takeException(), isNull);
      // Tests have no status bar, so the collapsed toolbar is the top row.
      final toolbar = Rect.fromLTWH(0, 0, config.size.width, kToolbarHeight);
      final nameRect = tester.getRect(find.byKey(name));
      final locationRect = tester.getRect(find.byKey(location));
      expect(nameRect.top, greaterThanOrEqualTo(toolbar.top));
      expect(locationRect.top, greaterThanOrEqualTo(nameRect.bottom - 1));
      expect(locationRect.bottom, lessThanOrEqualTo(toolbar.bottom));
      expect(locationRect.overlaps(actions), isFalse);
    }, variant: const TargetPlatformVariant({TargetPlatform.android}));
  }

  // A regular iPhone's top inset (59) and the taller one of the unfolded
  // iPhone Duo in portrait (84): the collapsed bar must clear either.
  for (final topInset in [59.0, 84.0]) {
    testWidgets('the collapsed glass header fits below a $topInset inset', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(720, 1024);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(top: topInset);
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
      await tester.fling(page.first, const Offset(0, -1500), 3000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }

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

  for (final locale in ['en', 'ar']) {
    testWidgets('a long place in the glass header clears refresh in $locale', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(393, 852);
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
          child: MaterialApp(
            locale: Locale(locale),
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

      final location = tester.getRect(
        find.byKey(const ValueKey('location-moving')),
      );
      final refresh = tester.getRect(find.byIcon(Icons.refresh));
      expect(location.overlaps(refresh), isFalse);
      expect(
        location,
        _rectCloseTo(
          tester.getRect(find.byKey(const ValueKey('location-hero'))),
        ),
      );
      final pin = tester.getRect(find.byIcon(Icons.location_on));
      expect(pin.overlaps(refresh), isFalse);
      expect(
        locale == 'ar' ? pin.left : pin.right,
        locale == 'ar'
            ? greaterThanOrEqualTo(location.right)
            : lessThanOrEqualTo(location.left),
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }
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
