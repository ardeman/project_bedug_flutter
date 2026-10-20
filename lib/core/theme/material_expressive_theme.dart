import 'package:material_ui/material_ui.dart';

import 'app_tokens.dart';

/// Expressive styling for the Material path. Native desktop palettes and
/// Apple/Windows themes keep their own component treatments.
ThemeData materialExpressiveTheme(ThemeData base) {
  final tonal = ColorScheme.fromSeed(
    seedColor: base.colorScheme.primary,
    brightness: base.brightness,
  );
  final scheme = base.colorScheme.copyWith(
    surfaceContainerLow: tonal.surfaceContainerLow,
    surfaceContainer: tonal.surfaceContainer,
    surfaceContainerHigh: tonal.surfaceContainerHigh,
  );
  final text = base.textTheme;
  const round = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.xl)),
  );
  const pressed = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
  );
  // Matching border types let Flutter interpolate the corners on press.
  final buttonStyle = ButtonStyle(
    shape: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.pressed) ? pressed : round,
    ),
    minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
    ),
    textStyle: WidgetStatePropertyAll(text.labelLarge),
    animationDuration: const Duration(milliseconds: 200),
    // A compact visual button still has a 48dp accessible touch target.
    tapTargetSize: MaterialTapTargetSize.padded,
  );

  return base.copyWith(
    colorScheme: scheme,
    textTheme: text.copyWith(
      headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    cardTheme: base.cardTheme.copyWith(
      color: scheme.surfaceContainerLow,
      shape: round,
    ),
    listTileTheme: base.listTileTheme.copyWith(
      minVerticalPadding: AppSpacing.sm,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.sm)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: buttonStyle.copyWith(elevation: const WidgetStatePropertyAll(0)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
    textButtonTheme: TextButtonThemeData(style: buttonStyle),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: round,
        minimumSize: const Size(48, 48),
      ),
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium?.copyWith(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: scheme.onSurface,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.onSecondaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: scheme.surfaceContainerHigh,
    ),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: scheme.surfaceContainerLow,
    ),
  );
}
