import 'package:bedug/core/constants/app_colors.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Material Expressive theme', () {
    for (final brightness in Brightness.values) {
      test('tonal cards and selected navigation in $brightness', () {
        final theme =
            buildAppTheme(brightness, platform: TargetPlatform.android);
        final scheme = theme.colorScheme;
        expect(theme.cardTheme.color, scheme.surfaceContainerLow);
        expect(scheme.surfaceContainerLow, isNot(scheme.surfaceContainer));
        expect(
            theme.navigationBarTheme.indicatorColor, scheme.secondaryContainer);
        expect(
            theme.navigationBarTheme.iconTheme!
                .resolve({WidgetState.selected})!.color,
            scheme.onSecondaryContainer);
        expect((theme.cardTheme.shape! as RoundedRectangleBorder).side,
            BorderSide.none);
      });
    }

    test('buttons animate corners while keeping accessible touch targets', () {
      final theme =
          buildAppTheme(Brightness.light, platform: TargetPlatform.android);
      final style = theme.filledButtonTheme.style!;
      expect(style.shape!.resolve({}),
          isNot(style.shape!.resolve({WidgetState.pressed})));
      expect(style.tapTargetSize, MaterialTapTargetSize.padded);
      expect(style.animationDuration, const Duration(milliseconds: 200));
    });

    test('Apple and Windows retain their original card shapes', () {
      for (final platform in [
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.windows
      ]) {
        final theme = buildAppTheme(Brightness.light, platform: platform);
        final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(AppRadii.lg));
        expect(shape.side, isNot(BorderSide.none));
      }
    });
  });

  group('brand theme', () {
    test('uses emerald on sand with the brand font in light mode', () {
      final theme = buildAppTheme(Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppColors.lightBg);
      expect(theme.colorScheme.primary, AppColors.emerald);
      expect(theme.colorScheme.tertiary, AppColors.gold);
      expect(theme.extension<BrandColors>()!.accent, AppColors.emerald);
      expect(theme.textTheme.bodyMedium!.fontFamily, kBrandFont);
    });

    test('uses the lighter dark-mode twins in dark mode', () {
      final theme = buildAppTheme(Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.darkBg);
      expect(theme.colorScheme.primary, AppColors.emeraldDark);
      expect(theme.colorScheme.tertiary, AppColors.goldDark);
      expect(theme.extension<BrandColors>()!.secondary, AppColors.tealDark);
    });

    test('gives cards large radii and no shadow', () {
      final card = buildAppTheme(Brightness.light, platform: TargetPlatform.iOS)
          .cardTheme;
      expect(card.elevation, 0);
      final shape = card.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppRadii.lg));
    });
  });
}
