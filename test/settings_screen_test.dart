import 'package:bedug/core/design/platform_capabilities.dart';
import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/features/settings/settings_screen.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pumpSettings(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  // Tall enough that every row is built.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SettingsScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  // `flutter test` takes the host's platform path, so each test runs only
  // where its design system applies.
  final isApple = PlatformCapabilities.isApple;

  testWidgets('uses glass switches and menus on Apple platforms',
      (tester) async {
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
  }, skip: !isApple);

  testWidgets('uses Material controls elsewhere', (tester) async {
    await _pumpSettings(tester);

    expect(find.byType(Switch), findsNWidgets(2));
    expect(find.byType(ToggleButtons), findsOneWidget);
    expect(find.byType(LiquidGlassSwitch), findsNothing);
  }, skip: isApple);
}
