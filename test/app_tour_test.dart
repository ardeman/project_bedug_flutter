import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:adhan/adhan.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:bedug/features/quran/quran.dart';
import 'package:bedug/features/prayer_times/prayer_times_screen.dart';
import 'package:bedug/core/design/platform_capabilities.dart';
import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/theme/app_theme_scope.dart';
import 'package:bedug/features/tour/app_tour_provider.dart';
import 'package:bedug/features/tour/app_tour_screen.dart';
import 'package:bedug/features/tour/tour_targets.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:bedug/home/home_screen.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpTour(
  WidgetTester tester, {
  required Widget child,
  Locale locale = const Locale('en'),
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      theme: buildAppTheme(brightness),
      builder: (context, child) => AppThemeScope(
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
      home: RepaintBoundary(key: const ValueKey('tour-preview'), child: child),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapLabel(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'completion survives a new provider container and settings stay intact',
    () async {
      SharedPreferences.setMockInitialValues({'selected_city_id': 'jakarta'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      expect(container.read(appTourCompletedProvider), isFalse);
      await container.read(appTourCompletedProvider.notifier).complete();
      expect(container.read(appTourCompletedProvider), isTrue);
      container.dispose();
      final restarted = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restarted.dispose);
      expect(restarted.read(appTourCompletedProvider), isTrue);
      expect(prefs.getString('selected_city_id'), 'jakarta');
    },
  );

  testWidgets('tour switches the real tabs beneath its coachmarks', (
    tester,
  ) async {
    if (Platform.environment['BEDUG_TOUR_PREVIEW'] == '1') {
      await tester.runAsync(() async {
        final font = FontLoader('PlusJakartaSans')
          ..addFont(
            Future.value(
              ByteData.sublistView(
                File(
                  'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Regular.ttf',
                ).readAsBytesSync(),
              ),
            ),
          );
        await font.load();
      });
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await pumpTour(
      tester,
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          prayerProvider.overrideWith(_TourPrayerNotifier.new),
          quranIndexProvider.overrideWith(
            (ref) async =>
                parseQuranIndex(File(quranIndexAsset).readAsStringSync()),
          ),
        ],
        child: const HomeScreen(),
      ),
    );
    expect(find.text('Step 1 of ${tourStops.length}'), findsOneWidget);
    expect(find.byType(AppTourOverlay), findsOneWidget);
    expect(find.byType(PrayerTimesScreen), findsOneWidget);
    for (var step = 0; step < tourStops.length; step++) {
      expect(
        tester.widget<AppTourOverlay>(find.byType(AppTourOverlay)).step,
        step,
      );
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack).first).index,
        tourStops[step].tab,
      );
      if (step == 1 && Platform.environment['BEDUG_TOUR_PREVIEW'] == '1') {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('tour-preview')),
          );
          final picture = await boundary.toImage(pixelRatio: 1);
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          File(
            '/tmp/bedug-control-tour-${Theme.of(tester.element(find.byType(HomeScreen))).platform.name}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          picture.dispose();
        });
      }
      await tapLabel(tester, step == tourStops.length - 1 ? 'Done' : 'Next');
      expect(tester.takeException(), isNull);
    }
    expect(find.byType(AppTourOverlay), findsNothing);
    expect(
      tester.widget<IndexedStack>(find.byType(IndexedStack).first).index,
      0,
    );
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

  testWidgets('unavailable controls are skipped in both directions', (
    tester,
  ) async {
    await pumpTour(
      tester,
      child: _TourHarness(
        unavailable: const {TourControl.calendar},
        onFinish: () async {},
      ),
    );
    await tapLabel(tester, 'Next');
    expect(find.text('Step 3 of ${tourStops.length}'), findsOneWidget);
    await tapLabel(tester, 'Back');
    expect(find.text('Step 1 of ${tourStops.length}'), findsOneWidget);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('tour goes back, completes and skips on $platform', (
      tester,
    ) async {
      var finishes = 0;
      await pumpTour(
        tester,
        child: _TourHarness(
          onFinish: () async {
            finishes++;
          },
        ),
      );
      expect(PlatformCapabilities.isApple, platform == TargetPlatform.iOS);
      await tapLabel(tester, 'Next');
      expect(find.text('Step 2 of ${tourStops.length}'), findsOneWidget);
      await tapLabel(tester, 'Back');
      expect(find.text('Step 1 of ${tourStops.length}'), findsOneWidget);
      for (var i = 0; i < tourStops.length - 1; i++) {
        await tapLabel(tester, 'Next');
      }
      expect(
        find.text('Step ${tourStops.length} of ${tourStops.length}'),
        findsOneWidget,
      );
      expect(find.text('Skip tour'), findsNothing);
      await tapLabel(tester, 'Done');
      expect(finishes, 1);
      await tester.pumpWidget(const SizedBox());
      await pumpTour(
        tester,
        child: _TourHarness(
          onFinish: () async {
            finishes++;
          },
        ),
      );
      await tapLabel(tester, 'Skip tour');
      expect(finishes, 2);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant({platform}));

    for (final code in ['en', 'id', 'ms', 'ar']) {
      testWidgets('tour fits $code large text in landscape on $platform', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(640, 320);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpTour(
          tester,
          locale: Locale(code),
          textScale: 2,
          brightness: Brightness.dark,
          child: _TourHarness(onFinish: () async {}),
        );
        final context = tester.element(find.byType(AppTourOverlay));
        final l10n = AppLocalizations.of(context);
        for (var i = 0; i < tourStops.length - 1; i++) {
          await tapLabel(tester, l10n.tourNext);
          expect(tester.takeException(), isNull);
        }
        await tapLabel(tester, l10n.tourDone);
        expect(tester.takeException(), isNull);
      }, variant: TargetPlatformVariant({platform}));
    }
  }
}

class _TourPrayerNotifier extends PrayerNotifier {
  @override
  PrayerState build() => PrayerState(
    loading: false,
    locationLabel: 'Jakarta',
    times: PrayerTimes.today(
      Coordinates(-6.2, 106.8),
      CalculationMethod.singapore.getParameters(),
    ),
  );
}

class _TourHarness extends StatefulWidget {
  const _TourHarness({required this.onFinish, this.unavailable = const {}});
  final Set<TourControl> unavailable;
  final Future<void> Function() onFinish;

  @override
  State<_TourHarness> createState() => _TourHarnessState();
}

class _TourHarnessState extends State<_TourHarness> {
  int _step = 0;
  final _anchors = TourAnchors();

  @override
  void dispose() {
    _anchors.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TourAnchorScope(
    anchors: _anchors,
    child: Stack(
      children: [
        Scaffold(
          body: Center(
            child: widget.unavailable.contains(tourStops[_step].control)
                ? const SizedBox()
                : TourTarget(
                    control: tourStops[_step].control,
                    child: const SizedBox(
                      width: 200,
                      height: 48,
                      child: Text('A real control'),
                    ),
                  ),
          ),
        ),
        AppTourOverlay(
          step: _step,
          anchors: _anchors,
          onNext: () => setState(() => _step++),
          onBack: () => setState(() => _step--),
          onFinish: widget.onFinish,
        ),
      ],
    ),
  );
}
