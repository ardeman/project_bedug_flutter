import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';
import '../design/linux_desktop.dart';
import 'app_tokens.dart';
import 'material_expressive_theme.dart';

/// Brand colors that screens read from the theme, so the accent can follow
/// the desktop on Linux while every other platform keeps emerald and teal.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({required this.accent, required this.secondary});

  static const brand = BrandColors(
    accent: AppColors.emerald,
    secondary: AppColors.teal,
  );
  static const brandDark = BrandColors(
    accent: AppColors.emeraldDark,
    secondary: AppColors.tealDark,
  );

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
  TargetPlatform? platform,
}) {
  final isDark = brightness == Brightness.dark;
  final palette = _DesktopPalette.of(desktop, isDark);

  if (palette == null) {
    final base = _brandTheme(brightness);
    final target = platform ?? defaultTargetPlatform;
    return kIsWeb ||
            target == TargetPlatform.android ||
            target == TargetPlatform.linux
        ? materialExpressiveTheme(base)
        : base;
  }

  final brand = accent == null
      ? BrandColors.brand
      : BrandColors.fromAccent(accent);
  final scheme =
      ColorScheme.fromSeed(
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

/// The brand theme on every platform except GNOME and KDE: a deep emerald on
/// warm sand (light) or green-black (dark), Plus Jakarta Sans, flat tonal
/// cards with large radii and pill-shaped controls.
ThemeData _brandTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final brand = isDark ? BrandColors.brandDark : BrandColors.brand;
  final background = isDark ? AppColors.darkBg : AppColors.lightBg;
  final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
  final text = isDark ? AppColors.darkText : AppColors.lightText;

  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.emerald,
        brightness: brightness,
      ).copyWith(
        primary: brand.accent,
        secondary: brand.secondary,
        tertiary: isDark ? AppColors.goldDark : AppColors.gold,
        surface: surface,
        onSurface: text,
        surfaceContainerLow: surface,
        surfaceContainer: surface,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: kBrandFont,
  );
  // Large text is tightened slightly; geometric sans looks loose at size.
  final textTheme = base.textTheme
      .copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
        ),
        displayMedium: base.textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      )
      .apply(bodyColor: text, displayColor: text);

  // A hairline instead of a shadow separates cards from the background.
  final hairline = scheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6);
  const pill = StadiumBorder();
  const buttonPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.sm,
  );

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    cardColor: surface,
    dividerColor: hairline,
    splashFactory: InkSparkle.splashFactory,
    extensions: [brand],
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: hairline),
      ),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      iconColor: brand.accent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: pill, padding: buttonPadding),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: pill,
        padding: buttonPadding,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: pill,
        padding: buttonPadding,
        side: BorderSide(color: hairline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: pill),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(shape: pill),
    ),
    chipTheme: ChipThemeData(
      shape: pill,
      side: BorderSide(color: hairline),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: brand.accent.withValues(alpha: 0.16),
      indicatorShape: pill,
      elevation: 0,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: background,
      indicatorColor: brand.accent.withValues(alpha: 0.16),
      indicatorShape: pill,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: hairline),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    dividerTheme: DividerThemeData(color: hairline, thickness: 1, space: 1),
  );
}
