import 'package:bedug/core/constants/app_colors.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      final card = buildAppTheme(Brightness.light).cardTheme;
      expect(card.elevation, 0);
      final shape = card.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppRadii.lg));
    });
  });
}
