import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;

import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:bedug/core/design/liquid_glass.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/theme/app_theme_scope.dart';
import 'package:bedug/core/theme/app_tokens.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:bedug/core/services/selection_feedback.dart';
import 'package:bedug/core/utils/qibla_utils.dart';
import 'package:bedug/features/qibla/widgets/qibla_card.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:bedug/features/worship/worship_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePrayerNotifier extends PrayerNotifier {
  _FakePrayerNotifier(this._state);

  final PrayerState _state;

  @override
  PrayerState build() => _state;
}

Widget _app(
  PrayerState state, {
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Stream<CompassEvent>? compassEvents,
  bool feedbackEnabled = true,
  bool worshipScreen = false,
  EdgeInsets safeInsets = EdgeInsets.zero,
}) => ProviderScope(
  overrides: [
    if (compassEvents != null)
      compassEventsProvider.overrideWithValue(compassEvents),
    prayerProvider.overrideWith(() => _FakePrayerNotifier(state)),
  ],
  child: MaterialApp(
    locale: locale,
    theme: buildAppTheme(brightness),
    builder: (context, child) => AppThemeScope(
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          padding: safeInsets,
        ),
        child: child!,
      ),
    ),
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      ...AppLocalizations.localizationsDelegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: worshipScreen
        ? const WorshipScreen(isActive: false)
        : Scaffold(
            body: SingleChildScrollView(
              child: QiblaCard(feedbackEnabled: feedbackEnabled),
            ),
          ),
  ),
);

void main() {
  setUpAll(() async {
    // Measure wrapping with the bundled typeface instead of the test font.
    final loader = FontLoader(kBrandFont)
      ..addFont(
        rootBundle.load(
          'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Regular.ttf',
        ),
      );
    await loader.load();
  });
  testWidgets('ticks on alignment, stays quiet through jitter, and rearms', (
    tester,
  ) async {
    final events = StreamController<CompassEvent>();
    addTearDown(events.close);
    var ticks = 0;
    SelectionFeedback.debugOverride = () => ticks++;
    addTearDown(() => SelectionFeedback.debugOverride = null);
    final coords = Coordinates(-6.2088, 106.8456);
    final bearing = qiblaBearing(coords);
    await tester.pumpWidget(
      _app(
        PrayerState(
          times: PrayerTimes.today(
            coords,
            CalculationMethod.singapore.getParameters(),
          ),
          loading: false,
        ),
        compassEvents: events.stream,
      ),
    );

    Future<void> heading(double offset) async {
      events.add(CompassEvent.fromList([bearing + offset, 0, 1]));
      await tester.pump();
    }

    await heading(10);
    expect(ticks, 0);
    await heading(3);
    expect(ticks, 1);
    for (final offset in [0.0, -2.0, 3.5, 2.5, -5.0, 0.0]) {
      await heading(offset);
    }
    expect(ticks, 1);
    await tester.pump(const Duration(minutes: 1));
    expect(ticks, 1);
    await heading(-7);
    await heading(-3);
    expect(ticks, 2);

    events.add(CompassEvent.fromList(null));
    await tester.pump();
    expect(ticks, 2);
    await heading(0);
    expect(ticks, 3);
  });

  testWidgets('does not tick without a location or on an inactive tab', (
    tester,
  ) async {
    final events = StreamController<CompassEvent>.broadcast();
    addTearDown(events.close);
    var ticks = 0;
    SelectionFeedback.debugOverride = () => ticks++;
    addTearDown(() => SelectionFeedback.debugOverride = null);
    await tester.pumpWidget(
      _app(const PrayerState(loading: false), compassEvents: events.stream),
    );
    events.add(CompassEvent.fromList([0, 0, 1]));
    await tester.pump();
    expect(ticks, 0);

    final coords = Coordinates(-6.2088, 106.8456);
    // Recreate the provider scope with a resolved location.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      _app(
        PrayerState(
          times: PrayerTimes.today(
            coords,
            CalculationMethod.singapore.getParameters(),
          ),
          loading: false,
        ),
        compassEvents: events.stream,
        feedbackEnabled: false,
      ),
    );
    events.add(CompassEvent.fromList([qiblaBearing(coords), 0, 1]));
    await tester.pump();
    expect(ticks, 0);
  });

  testWidgets('shows the bearing and north-up guidance without a compass', (
    tester,
  ) async {
    final times = PrayerTimes.today(
      Coordinates(-6.2088, 106.8456),
      CalculationMethod.singapore.getParameters(),
    );
    await tester.pumpWidget(
      _app(PrayerState(times: times, locationLabel: 'Jakarta', loading: false)),
    );

    expect(find.text('Jakarta'), findsOneWidget);
    // Jakarta's destination is northwest of the device. The marker must
    // follow the bearing even in an RTL layout, rather than mirror it.
    final kaaba = find.byKey(const ValueKey('qibla-kaaba-marker'));
    final device = find.byKey(const ValueKey('qibla-device-marker'));
    expect(tester.getCenter(kaaba).dx, lessThan(tester.getCenter(device).dx));
    expect(tester.getCenter(kaaba).dy, lessThan(tester.getCenter(device).dy));
    expect(find.text('295° (65° from north toward west)'), findsOneWidget);
    expect(
      find.text('Point the top of the screen north, then follow the arrow.'),
      findsOneWidget,
    );

    // Wrapped guide lines share one start edge, with each icon beside the
    // first line of its text.
    final faceNorth = find.text(
      'Point the top of the screen north, then follow the arrow.',
    );
    final findNorth = find.text(
      'Find north with a phone compass, a map app, or the sun.',
    );
    expect(tester.getTopLeft(faceNorth).dx, tester.getTopLeft(findNorth).dx);
    final mapIcon = tester.getRect(find.byIcon(Icons.map_outlined));
    final findNorthRect = tester.getRect(findNorth);
    expect(mapIcon.top, lessThan(findNorthRect.top + mapIcon.height));
  });

  for (final size in [const Size(320, 568), const Size(375, 667)]) {
    for (final withSensor in [false, true]) {
      testWidgets(
        'compact card fits above navigation at $size, sensor: $withSensor',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.view.viewPadding = const FakeViewPadding(top: 44, bottom: 90);
          tester.view.padding = const FakeViewPadding(top: 44, bottom: 90);
          addTearDown(tester.view.reset);
          final events = StreamController<CompassEvent>();
          addTearDown(events.close);
          await tester.pumpWidget(
            _app(
              PrayerState(
                times: PrayerTimes.today(
                  Coordinates(-6.2088, 106.8456),
                  CalculationMethod.singapore.getParameters(),
                ),
                locationLabel: 'Jakarta',
                loading: false,
              ),
              compassEvents: events.stream,
              worshipScreen: true,
              // Model the status area and space occupied by the floating tab bar.
              safeInsets: const EdgeInsets.only(top: 44, bottom: 90),
            ),
          );
          if (withSensor) {
            events.add(CompassEvent.fromList([0, 0, 1]));
            await tester.pump();
          }
          // The Qibla card fits between the bars; entries below it, such as
          // dzikir, may scroll.
          final qiblaCard = find.descendant(
            of: find.byType(QiblaCard),
            matching: find.byType(GlassCard),
          );
          expect(qiblaCard, findsOneWidget);
          final card = tester.getRect(qiblaCard);
          expect(card.top, greaterThanOrEqualTo(44 + kToolbarHeight));
          expect(card.bottom, lessThanOrEqualTo(size.height - 90));
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant({
          TargetPlatform.android,
          TargetPlatform.macOS,
        }),
      );
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('fits a narrow RTL layout with large text in $brightness', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final times = PrayerTimes.today(
        Coordinates(-6.2088, 106.8456),
        CalculationMethod.singapore.getParameters(),
      );
      await tester.pumpWidget(
        _app(
          PrayerState(
            times: times,
            locationLabel: 'Jakarta · Daerah Khusus Ibukota Jakarta',
            loading: false,
          ),
          locale: const Locale('ar'),
          brightness: brightness,
          textScale: 2,
          worshipScreen: true,
          safeInsets: const EdgeInsets.only(top: 44, bottom: 90),
        ),
      );

      final context = tester.element(find.byType(QiblaCard));
      final l10n = AppLocalizations.of(context);
      expect(Directionality.of(context), TextDirection.rtl);
      expect(tester.takeException(), isNull);
      final kaaba = find.byKey(const ValueKey('qibla-kaaba-marker'));
      final device = find.byKey(const ValueKey('qibla-device-marker'));
      expect(tester.getCenter(kaaba).dx, lessThan(tester.getCenter(device).dx));
      expect(tester.getCenter(kaaba).dy, lessThan(tester.getCenter(device).dy));
      await tester.ensureVisible(find.text(l10n.qiblaFindNorthHint));
      await tester.pumpAndSettle();
      expect(find.text(l10n.qiblaFindNorthHint).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.all());
  }

  testWidgets('asks for a location when none is available', (tester) async {
    await tester.pumpWidget(_app(const PrayerState(loading: false)));

    expect(
      find.text("Location isn't available yet. Set it in Settings."),
      findsOneWidget,
    );
  });
}
