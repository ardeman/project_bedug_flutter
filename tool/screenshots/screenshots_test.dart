// Renders the store screenshots from the real app with sample data (Jakarta,
// Kemenag, a fixed clock), in Indonesian and English, on every store device:
//
//   flutter test tool/screenshots --update-goldens
//   store/render.sh
//
// Not part of the Checks: it writes images instead of testing behaviour.
// This file is a test that lives in tool/, so the analyzer doesn't know it.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:adhan/adhan.dart';
import 'package:bedug/core/design/glass_accessibility.dart';
import 'package:bedug/core/design/platform_capabilities.dart';
import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/services/kemenag_method.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:bedug/core/services/selection_feedback.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/widgets/recitation_card.dart';
import 'package:bedug/core/theme/app_theme_scope.dart';
import 'package:bedug/features/fasting/fasting_log.dart';
import 'package:bedug/features/qibla/widgets/qibla_card.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:bedug/features/worship/worship_screen.dart';
import 'package:bedug/home/home_screen.dart';
import 'package:clock/clock.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A device the store slides show, in one way of holding it: its screen in
/// logical pixels, its pixel ratio, the system bars' insets (logical) and a
/// half-open fold. Renders go to `out/devices/<name>/`, and
/// `store/render.sh` draws the device's frame around them.
typedef _Device = ({
  String name,
  TargetPlatform platform,
  Size size,
  double ratio,
  EdgeInsets insets,
  Rect? fold,
  List<String> screens,
});

/// Every screen of the store slides.
const _allScreens = [
  'prayer',
  'quran',
  'qibla',
  'dzikir',
  'events',
  'fasting',
  'zakat',
  'duas',
  'asmaul',
];

/// The store's devices in every way the slides hold them, each at the size
/// of its frame's screen (`store/bezels/screens.txt`). Insets are the system
/// bars' and cutouts': `store/render.sh` draws the status bars into them.
const List<_Device> _devices = [
  // Google Play: Pixel 9 (the camera hole is on the left held sideways) and
  // Pixel Tablet (its camera is on the right held upright).
  (
    name: 'pixel',
    platform: TargetPlatform.android,
    size: Size(1080 / 2.625, 2424 / 2.625),
    ratio: 2.625,
    insets: EdgeInsets.only(top: 52, bottom: 24),
    fold: null,
    screens: _allScreens,
  ),
  (
    name: 'pixel-landscape',
    platform: TargetPlatform.android,
    size: Size(2424 / 2.625, 1080 / 2.625),
    ratio: 2.625,
    insets: EdgeInsets.only(left: 52, top: 24, bottom: 24),
    fold: null,
    screens: ['qibla'],
  ),
  (
    name: 'pixel-tablet',
    platform: TargetPlatform.android,
    size: Size(1280, 800),
    ratio: 2,
    insets: EdgeInsets.only(top: 24, bottom: 24),
    fold: null,
    screens: _allScreens,
  ),
  (
    name: 'pixel-tablet-portrait',
    platform: TargetPlatform.android,
    size: Size(800, 1280),
    ratio: 2,
    insets: EdgeInsets.only(top: 24, bottom: 24),
    fold: null,
    screens: ['qibla'],
  ),
  // App Store: iPhone 17, iPad Pro 13" and MacBook Air 13" (the app's
  // window on the desktop, below the menu bar). An iPhone held sideways
  // hides its status bar.
  (
    name: 'iphone',
    platform: TargetPlatform.iOS,
    size: Size(402, 874),
    ratio: 3,
    insets: EdgeInsets.only(top: 62, bottom: 34),
    fold: null,
    screens: _allScreens,
  ),
  (
    name: 'iphone-landscape',
    platform: TargetPlatform.iOS,
    size: Size(874, 402),
    ratio: 3,
    insets: EdgeInsets.only(left: 62, right: 62, bottom: 21),
    fold: null,
    screens: ['qibla'],
  ),
  (
    name: 'ipad',
    platform: TargetPlatform.iOS,
    size: Size(1376, 1032),
    ratio: 2,
    insets: EdgeInsets.only(top: 24, bottom: 20),
    fold: null,
    screens: _allScreens,
  ),
  (
    name: 'ipad-portrait',
    platform: TargetPlatform.iOS,
    size: Size(1032, 1376),
    ratio: 2,
    insets: EdgeInsets.only(top: 24, bottom: 20),
    fold: null,
    screens: ['qibla'],
  ),
  (
    name: 'mac',
    platform: TargetPlatform.macOS,
    size: Size(1120, 680),
    ratio: 2,
    // The transparent title bar the content runs under (traffic lights).
    insets: EdgeInsets.only(top: 28),
    fold: null,
    screens: _allScreens,
  ),
  // The iPhone Duo: its status bar runs down a side edge, at the top of the
  // right one (on the closed screen, under its camera: on the left held
  // sideways). Open (2007 x 2853) upright and sideways, closed on its outer
  // screen (1398 x 2034) both ways, and half folded on a table or like a
  // book.
  (
    name: 'duo',
    platform: TargetPlatform.iOS,
    size: Size(669, 951),
    ratio: 3,
    insets: EdgeInsets.only(right: 62, bottom: 21),
    fold: null,
    screens: ['prayer', 'fasting', 'duas', 'asmaul'],
  ),
  (
    name: 'duo-landscape',
    platform: TargetPlatform.iOS,
    size: Size(951, 669),
    ratio: 3,
    insets: EdgeInsets.only(right: 62, bottom: 21),
    fold: null,
    screens: ['dzikir'],
  ),
  (
    name: 'duo-outer',
    platform: TargetPlatform.iOS,
    size: Size(466, 678),
    ratio: 3,
    insets: EdgeInsets.only(right: 62, bottom: 21),
    fold: null,
    screens: ['events'],
  ),
  (
    name: 'duo-outer-landscape',
    platform: TargetPlatform.iOS,
    size: Size(678, 466),
    ratio: 3,
    insets: EdgeInsets.only(left: 62, bottom: 21),
    fold: null,
    screens: ['zakat'],
  ),
  (
    name: 'duo-table',
    platform: TargetPlatform.iOS,
    size: Size(669, 951),
    ratio: 3,
    insets: EdgeInsets.only(right: 62, bottom: 21),
    fold: Rect.fromLTWH(0, 475.5, 669, 0),
    screens: ['quran'],
  ),
  (
    name: 'duo-book',
    platform: TargetPlatform.iOS,
    size: Size(951, 669),
    ratio: 3,
    insets: EdgeInsets.only(right: 62, bottom: 21),
    fold: Rect.fromLTWH(475.5, 0, 0, 669),
    screens: ['qibla'],
  ),
];

/// Loads the fonts a test would otherwise draw as boxes: the app's own
/// (Plus Jakarta Sans, Amiri Quran) and the Material icons, which ship with
/// the Flutter SDK running this test.
Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  const jakarta = 'assets/fonts/plus_jakarta_sans/PlusJakartaSans';
  await load('PlusJakartaSans', [
    '$jakarta-Regular.ttf',
    '$jakarta-Medium.ttf',
    '$jakarta-SemiBold.ttf',
    '$jakarta-Bold.ttf',
    '$jakarta-ExtraBold.ttf',
  ]);
  await load('AmiriQuran', ['assets/fonts/amiri_quran/AmiriQuran-Regular.ttf']);
  final tester = Platform.resolvedExecutable;
  final root = tester.substring(0, tester.indexOf('/bin/cache/'));
  await load('MaterialIcons', [
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

/// Tests have no system fonts, which draw Arabic on a phone (the dzikir and
/// duas); Amiri Quran stands in for them.
ThemeData _withArabic(ThemeData theme) => theme.copyWith(
  textTheme: theme.textTheme.apply(fontFamilyFallback: const ['AmiriQuran']),
);

/// Jakarta, where every sample is set.
final _jakarta = Coordinates(-6.2088, 106.8456);

/// Noon on a Umm al-Qura date.
DateTime _hijriNoon(int year, int month, int day) {
  final date = HijriCalendar().hijriToGregorian(year, month, day);
  return DateTime(date.year, date.month, date.day, 12);
}

/// The sample clock of a screen: a Thursday afternoon, Dhuhr just past, with
/// the dzikir at dawn and the fasting log in the middle of Ramadan.
DateTime _now(String screen) => switch (screen) {
  'dzikir' => DateTime(2026, 11, 5, 6, 20),
  'fasting' => _hijriNoon(1448, 9, 11),
  _ => DateTime(2026, 11, 5, 14, 40),
};

/// The fasting log with a Ramadan of one missed and one excused day.
String _fastingLog() {
  var log = const FastingLog();
  for (var day = 1; day <= 10; day++) {
    log = log.withStatus(_hijriNoon(1448, 9, day), switch (day) {
      4 => FastStatus.missed,
      7 => FastStatus.excused,
      _ => FastStatus.fasted,
    });
  }
  return log.toJson();
}

class _FakePrayerNotifier extends PrayerNotifier {
  _FakePrayerNotifier(this._state);

  final PrayerState _state;

  @override
  PrayerState build() => _state;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Taps a tab of the bar: by its label, or on the iPhone Duo's rail (icons
/// only) by its semantics label.
Future<void> _tab(WidgetTester tester, String label) async {
  final byText = find.text(label).hitTestable();
  final rail = find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.label == label,
  );
  await tester.tap(byText.evaluate().isNotEmpty ? byText.first : rail.first);
  await _settle(tester);
}

/// Taps the first widget showing [text] and waits for the screen it opens.
Future<void> _tap(WidgetTester tester, String text) async {
  final target = find.text(text).hitTestable();
  if (target.evaluate().isEmpty) {
    // Lists build only the rows near the screen.
    if (find.text(text).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find
            .descendant(
              of: find.byType(WorshipScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    }
    // Then clear of the glass bars at the screen's edges.
    await Scrollable.ensureVisible(
      tester.element(find.text(text).first),
      alignment: 0.4,
    );
    await tester.pump();
  }
  await tester.tap(find.text(text).hitTestable().first);
  await _settle(tester);
}

/// Opens [screen] the way a user would: through the tabs and their lists.
Future<void> _stage(WidgetTester tester, String screen, String language) async {
  final l10n = lookupAppLocalizations(Locale(language));
  switch (screen) {
    case 'prayer':
      break;
    case 'quran':
      await _tab(tester, l10n.quran);
      await _tap(tester, language == 'id' ? 'Al-Baqarah' : 'Al-Baqara');
    case 'qibla':
      await _tab(tester, l10n.worship);
    case 'dzikir':
      await _tab(tester, l10n.worship);
      await _tap(tester, l10n.dzikir);
      // A few recitations counted on the first card.
      for (var i = 0; i < 3; i++) {
        // Near its top edge: a long card's middle can be off screen.
        await tester.tapAt(
          tester.getTopLeft(find.byType(RecitationCard).first) +
              const Offset(40, 40),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await _settle(tester);
    case 'events':
      await _tab(tester, l10n.worship);
      await _tap(tester, l10n.hijriEvents);
    case 'fasting':
      await _tab(tester, l10n.worship);
      await _tap(tester, l10n.fastingLog);
    case 'zakat':
      await _tab(tester, l10n.worship);
      await _tap(tester, l10n.zakat);
    case 'duas':
      await _tab(tester, l10n.worship);
      await _tap(tester, l10n.duas);
    case 'asmaul':
      await _tab(tester, l10n.worship);
      await _tap(tester, l10n.asmaulHusna);
  }
}

void main() {
  setUpAll(_loadFonts);
  // Counting a recitation ticks; keep the sound and haptics out of renders.
  SelectionFeedback.debugOverride = () {};

  for (final language in ['id', 'en']) {
    final suffix = language == 'id' ? '-id' : '';
    for (final d in _devices) {
      group('device ${d.name} $language', () {
        for (final screen in d.screens) {
          testWidgets(screen, (tester) async {
            debugDefaultTargetPlatformOverride = d.platform;
            tester.view.physicalSize = d.size * d.ratio;
            tester.view.devicePixelRatio = d.ratio;
            // A device reports its bars' insets as both; Material's app bar
            // reads the view padding.
            final insets = FakeViewPadding(
              left: d.insets.left * d.ratio,
              top: d.insets.top * d.ratio,
              right: d.insets.right * d.ratio,
              bottom: d.insets.bottom * d.ratio,
            );
            tester.view.padding = insets;
            tester.view.viewPadding = insets;
            if (d.fold != null) {
              tester.view.displayFeatures = [
                DisplayFeature(
                  bounds: d.fold!,
                  type: DisplayFeatureType.fold,
                  state: DisplayFeatureState.postureHalfOpened,
                ),
              ];
            }
            addTearDown(tester.view.reset);
            rootBundle.clear();

            try {
              final now = _now(screen);
              await withClock(Clock.fixed(now), () async {
                SharedPreferences.setMockInitialValues({
                  'app_locale': language,
                  'use_auto_location': false,
                  'selected_city_id': 'jakarta',
                  if (screen == 'fasting') 'fasting_log': _fastingLog(),
                  if (screen == 'zakat') 'zakat_gold_price_per_gram': 1500000,
                });
                final prefs = await SharedPreferences.getInstance();
                final times = PrayerTimes(
                  _jakarta,
                  DateComponents(now.year, now.month, now.day),
                  AppCalculationMethod.kemenag.getParameters(),
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
                      compassEventsProvider.overrideWithValue(
                        Stream.value(
                          CompassEvent.fromList([300.0, 300.0, 10.0]),
                        ),
                      ),
                    ],
                    child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      locale: Locale(language),
                      supportedLocales: AppLocalizations.supportedLocales,
                      localizationsDelegates: const [
                        AppLocalizations.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      theme: _withArabic(buildAppTheme(Brightness.light)),
                      scrollBehavior: PlatformCapabilities.isApple
                          ? const CupertinoScrollBehavior()
                          : null,
                      home: const HomeScreen(),
                      builder: (context, child) => GlassAccessibilityScope(
                        settings: GlassAccessibility.standard,
                        child: AppThemeScope(child: child!),
                      ),
                    ),
                  ),
                );
                await _settle(tester);
                await _stage(tester, screen, language);
                await expectLater(
                  find.byType(MaterialApp),
                  matchesGoldenFile('out/devices/${d.name}/$screen$suffix.png'),
                );
              });
            } finally {
              // Before the framework checks its debug variables.
              debugDefaultTargetPlatformOverride = null;
            }
          });
        }
      });
    }
  }
}
