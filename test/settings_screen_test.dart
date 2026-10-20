import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/design/liquid_glass.dart';
import 'package:bedug/core/services/kemenag_method.dart';
import 'package:bedug/core/widgets/calculation_method_picker.dart';
import 'package:bedug/features/settings/settings_screen.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/theme/app_theme_scope.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pumpSettings(
  WidgetTester tester, {
  Size size = const Size(800, 2400),
  Locale locale = const Locale('en'),
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  // Tall enough that every row is built.
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(brightness),
        locale: locale,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
        builder: (context, child) => AppThemeScope(
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('uses glass switches and menus on Apple platforms', (
    tester,
  ) async {
    final container = await _pumpSettings(tester);

    expect(find.byType(LiquidGlassSwitch), findsNWidgets(2));
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(DropdownButton<int>), findsNothing);
    expect(find.byType(ToggleButtons), findsNothing);

    // The theme row opens a glass menu; picking an option saves it.
    await tester.tap(find.text('System Default'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).themeMode, 2);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('Expressive controls save settings', (tester) async {
    final container = await _pumpSettings(tester);

    expect(find.byType(M3ESwitch), findsNWidgets(2));
    expect(find.byType(M3ESegmentedButton<bool>), findsOneWidget);
    expect(find.byType(M3EDropdownMenu<int>), findsOneWidget);
    expect(find.byType(LiquidGlassSwitch), findsNothing);
    final before = container.read(settingsProvider).useAutoLocation;
    await tester.tap(find.byType(M3ESwitch).last);
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).useAutoLocation, !before);
    await tester.tap(find.text('Hanafi'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).isHanafi, isTrue);
    await tester.tap(find.byType(M3EDropdownMenu<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).themeMode, 2);
  });

  for (final brightness in Brightness.values) {
    testWidgets('narrow Arabic settings support large text in $brightness', (
      tester,
    ) async {
      await _pumpSettings(
        tester,
        size: const Size(320, 932),
        locale: const Locale('ar'),
        textScale: 1.6,
        brightness: brightness,
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).first, const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'the calculation method opens as a page that saves the pick',
    (tester) async {
      final container = await _pumpSettings(tester);

      await tester.tap(find.text('Calculation Method'));
      await tester.pumpAndSettle();
      // A pushed page, not a sheet, so the edge swipe takes it back.
      expect(find.byType(CalculationMethodScreen), findsOneWidget);

      final screenContext = tester.element(
        find.byType(CalculationMethodScreen),
      );
      final description = find.text(
        AppLocalizations.of(screenContext).calculationMethodDesc,
      );
      expect(
        tester.getTopLeft(description).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.byType(GlassTopBar)).dy),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Umm Al-Qura (Saudi Arabia)'));
      await tester.pumpAndSettle();
      expect(find.byType(CalculationMethodScreen), findsNothing);
      expect(
        container.read(settingsProvider).method,
        AppCalculationMethod.ummAlQura,
      );
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );
}
