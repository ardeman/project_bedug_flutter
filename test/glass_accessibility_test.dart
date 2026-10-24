import 'package:bedug/core/design/glass_accessibility.dart';
import 'package:bedug/core/design/liquid_glass.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The tints [glassTintOf], [glassCardTintOf] and [glassSheetTintOf] give
/// under [settings], with Flutter's high contrast flag set to [highContrast].
Future<List<Color>> _tints(
  WidgetTester tester, {
  GlassAccessibility settings = GlassAccessibility.standard,
  bool highContrast = false,
  Brightness brightness = Brightness.light,
}) async {
  late List<Color> tints;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(brightness),
      home: MediaQuery(
        data: MediaQueryData(highContrast: highContrast),
        child: GlassAccessibilityScope(
          settings: settings,
          child: Builder(
            builder: (ctx) {
              tints = [
                glassTintOf(ctx),
                glassCardTintOf(ctx),
                glassSheetTintOf(ctx),
              ];
              return const SizedBox();
            },
          ),
        ),
      ),
    ),
  );
  return tints;
}

void main() {
  test('reads the native settings map', () {
    expect(
      GlassAccessibility.fromMap({
        'reduceTransparency': true,
        'increaseContrast': false,
      }),
      const GlassAccessibility(reduceTransparency: true),
    );
    expect(GlassAccessibility.fromMap({}), GlassAccessibility.standard);
    expect(GlassAccessibility.fromMap({'tintAmount': 0.59}).tintAmount, 0.59);
    expect(GlassAccessibility.fromMap({'tintAmount': 3}).tintAmount, 1);
  });

  for (final brightness in Brightness.values) {
    testWidgets('Increase Contrast makes $brightness glass more opaque', (
      tester,
    ) async {
      final clear = await _tints(tester, brightness: brightness);
      final native = await _tints(
        tester,
        brightness: brightness,
        settings: const GlassAccessibility(increaseContrast: true),
      );
      final flutter = await _tints(
        tester,
        brightness: brightness,
        highContrast: true,
      );
      for (var i = 0; i < clear.length; i++) {
        expect(native[i].a, greaterThan(clear[i].a));
        expect(flutter[i], native[i]);
      }
    });

    testWidgets('the Tinted slider blends $brightness glass toward opaque', (
      tester,
    ) async {
      final clear = await _tints(tester, brightness: brightness);
      final half = await _tints(
        tester,
        brightness: brightness,
        settings: const GlassAccessibility(tintAmount: 0.5),
      );
      final full = await _tints(
        tester,
        brightness: brightness,
        settings: const GlassAccessibility(tintAmount: 1),
      );
      final contrast = await _tints(
        tester,
        brightness: brightness,
        settings: const GlassAccessibility(increaseContrast: true),
      );
      for (var i = 0; i < clear.length; i++) {
        expect(half[i].a, greaterThan(clear[i].a));
        expect(half[i].a, lessThan(full[i].a));
        expect(full[i], contrast[i]);
      }
    });

    testWidgets('Reduce Transparency makes $brightness glass solid', (
      tester,
    ) async {
      final tints = await _tints(
        tester,
        brightness: brightness,
        settings: const GlassAccessibility(
          reduceTransparency: true,
          increaseContrast: true,
        ),
      );
      final surface = buildAppTheme(brightness).colorScheme.surface;
      expect(tints, everyElement(surface));
      expect(surface.a, 1);
    });
  }
}
