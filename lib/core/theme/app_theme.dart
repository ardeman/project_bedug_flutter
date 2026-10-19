import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../design/linux_desktop.dart';

/// Brand colors that screens read from the theme, so the accent can follow
/// the desktop on Linux while every other platform keeps emerald and teal.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({required this.accent, required this.secondary});

  static const brand =
      BrandColors(accent: AppColors.emerald, secondary: AppColors.teal);

  /// Builds the pair from a desktop accent. The secondary color sits 20°
  /// further round the hue wheel, as teal does from emerald.
  factory BrandColors.fromAccent(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    return BrandColors(
      accent: accent,
      secondary: hsl.withHue((hsl.hue + 20) % 360).toColor(),
    );
  }

  final Color accent;
  final Color secondary;

  static BrandColors of(BuildContext ctx) =>
      Theme.of(ctx).extension<BrandColors>() ?? brand;

  @override
  BrandColors copyWith({Color? accent, Color? secondary}) => BrandColors(
        accent: accent ?? this.accent,
        secondary: secondary ?? this.secondary,
      );

  @override
  BrandColors lerp(BrandColors? other, double t) {
    if (other == null) return this;
    return BrandColors(
      accent: Color.lerp(accent, other.accent, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
    );
  }
}

/// Desktop palette for one brightness on GNOME or KDE.
class _DesktopPalette {
  const _DesktopPalette({
    required this.window,
    required this.view,
    required this.card,
    required this.text,
    required this.fontFamily,
    required this.fontFallback,
  });

  final Color window;
  final Color view;
  final Color card;
  final Color text;
  final String fontFamily;
  final List<String> fontFallback;

  static _DesktopPalette? of(LinuxDesktop desktop, bool isDark) =>
      switch ((desktop, isDark)) {
        (LinuxDesktop.gnome, false) => const _DesktopPalette(
            window: AppColors.adwaitaLightWindow,
            view: AppColors.adwaitaLightView,
            card: AppColors.adwaitaLightCard,
            text: AppColors.adwaitaLightText,
            fontFamily: _adwaitaFont,
            fontFallback: _adwaitaFallback,
          ),
        (LinuxDesktop.gnome, true) => const _DesktopPalette(
            window: AppColors.adwaitaDarkWindow,
            view: AppColors.adwaitaDarkView,
            card: AppColors.adwaitaDarkCard,
            text: AppColors.adwaitaDarkText,
            fontFamily: _adwaitaFont,
            fontFallback: _adwaitaFallback,
          ),
        (LinuxDesktop.kde, false) => const _DesktopPalette(
            window: AppColors.breezeLightWindow,
            view: AppColors.breezeLightView,
            card: AppColors.breezeLightCard,
            text: AppColors.breezeLightText,
            fontFamily: _breezeFont,
            fontFallback: _breezeFallback,
          ),
        (LinuxDesktop.kde, true) => const _DesktopPalette(
            window: AppColors.breezeDarkWindow,
            view: AppColors.breezeDarkView,
            card: AppColors.breezeDarkCard,
            text: AppColors.breezeDarkText,
            fontFamily: _breezeFont,
            fontFallback: _breezeFallback,
          ),
        (LinuxDesktop.other, _) => null,
      };

  // GNOME 48+ ships Adwaita Sans; older GNOME uses Cantarell.
  static const _adwaitaFont = 'Adwaita Sans';
  static const _adwaitaFallback = ['Cantarell', 'Inter'];
  static const _breezeFont = 'Noto Sans';
  static const _breezeFallback = ['Hack', 'DejaVu Sans'];
}

/// Builds the app theme for [brightness]. On GNOME and KDE it uses the
/// desktop's surfaces and fonts and its [accent] (falling back to emerald);
/// everywhere else it is the brand Material 3 theme.
ThemeData buildAppTheme(
  Brightness brightness, {
  LinuxDesktop desktop = LinuxDesktop.other,
  Color? accent,
}) {
  final isDark = brightness == Brightness.dark;
  final palette = _DesktopPalette.of(desktop, isDark);

  if (palette == null) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.emerald,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      extensions: const [BrandColors.brand],
    );
  }

  final brand =
      accent == null ? BrandColors.brand : BrandColors.fromAccent(accent);
  final scheme = ColorScheme.fromSeed(
    seedColor: brand.accent,
    brightness: brightness,
  ).copyWith(
    // Desktop accents are designed for white text on top.
    primary: brand.accent,
    onPrimary: Colors.white,
    surface: palette.view,
    onSurface: palette.text,
    surfaceContainerLow: palette.card,
    surfaceContainer: palette.card,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.window,
    canvasColor: palette.window,
    cardColor: palette.card,
    cardTheme: CardThemeData(color: palette.card, elevation: 0),
    fontFamily: palette.fontFamily,
    fontFamilyFallback: palette.fontFallback,
    extensions: [brand],
  );
}
