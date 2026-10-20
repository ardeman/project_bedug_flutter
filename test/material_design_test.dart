import 'package:bedug/core/design/adaptive_scaffold.dart';
import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/services/kemenag_method.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/theme/app_theme_scope.dart';
import 'package:bedug/core/widgets/calculation_method_picker.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart' as bundled;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: buildAppTheme(brightness),
      locale: const Locale('en'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => AppThemeScope(child: child!),
      home: child,
    );

void main() {
  testWidgets(
    'Expressive navigation selects tabs and clears the gesture area',
    (tester) async {
      tester.view.physicalSize = const Size(320, 932);
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.reset);
      var selected = 0;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  viewPadding: const EdgeInsets.only(bottom: 34),
                  padding: const EdgeInsets.only(bottom: 34),
                  textScaler: const TextScaler.linear(1.6),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: AdaptiveScaffold(
                    title: 'Bedug',
                    showAppBar: false,
                    selectedIndex: selected,
                    onDestinationSelected: (value) =>
                        setState(() => selected = value),
                    destinations: const [
                      AdaptiveNavigationDestination(
                        icon: Icons.schedule,
                        label: 'Prayer times',
                      ),
                      AdaptiveNavigationDestination(
                        icon: Icons.mosque,
                        label: 'Worship',
                      ),
                      AdaptiveNavigationDestination(
                        icon: Icons.settings,
                        label: 'Settings',
                      ),
                    ],
                    child: const SizedBox.expand(key: ValueKey('page')),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(M3ENavigationBar), findsOneWidget);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(selected, 2);
      final page = tester.getRect(find.byKey(const ValueKey('page')));
      final bar = tester.getRect(find.byType(M3ENavigationBar));
      expect(page.bottom, lessThanOrEqualTo(bar.top));
      expect(
        tester.getRect(find.text('Settings')).bottom,
        lessThanOrEqualTo(932 - 34),
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final platform in [TargetPlatform.android, TargetPlatform.macOS]) {
    testWidgets('manual dark mode reaches package themes on $platform', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              expect(Theme.of(context).brightness, Brightness.dark);
              expect(bundled.Theme.of(context).brightness, Brightness.dark);
              if (platform == TargetPlatform.android) {
                final expressive = M3ETheme.of(context);
                expect(expressive.brightness, Brightness.dark);
                expect(
                  expressive.colorScheme.primary,
                  Theme.of(context).colorScheme.primary,
                );
                expect(
                  expressive.typeScale.bodyMedium.fontFamily,
                  'PlusJakartaSans',
                );
              } else {
                expect(M3ETheme.maybeOf(context), isNull);
              }
              return const SizedBox();
            },
          ),
          brightness: Brightness.dark,
        ),
      );
    }, variant: TargetPlatformVariant.only(platform));
  }

  testWidgets('Expressive calculation sheet saves a method and dismisses', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _app(
          Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: M3EButton(
                  onPressed: () => showCalculationMethodPicker(
                    context,
                    ref,
                    current: AppCalculationMethod.kemenag,
                  ),
                  child: const Text('Methods'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Methods'));
    await tester.pumpAndSettle();
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.calculationMethod), findsOneWidget);
    await tester.tap(find.text(l10n.methodMWL));
    await tester.pumpAndSettle();
    expect(
      container.read(settingsProvider).method,
      AppCalculationMethod.muslimWorldLeague,
    );
    expect(find.text(l10n.calculationMethod), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
