import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppColors {
  AppColors._();
  // Brand palette ("refined emerald"). Each color has a lighter dark-mode
  // twin so it keeps its contrast on the dark surfaces.
  static const emerald = Color(0xFF1F7A5A);
  static const emeraldDark = Color(0xFF4FBF8F);
  static const teal = Color(0xFF2A8C82);
  static const tealDark = Color(0xFF5CC7BA);
  static const gold = Color(0xFFC99A3B);
  static const goldDark = Color(0xFFE2B65C);

  // Warm sand background and white cards in light mode; green-black
  // background and green-tinted cards in dark mode.
  static const lightBg = Color(0xFFF7F4EE);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF16201B);
  static const darkBg = Color(0xFF0E1512);
  static const darkSurface = Color(0xFF17201C);
  static const darkText = Color(0xFFE8EFEB);

  // Adwaita (libadwaita 1.6) window, view and card backgrounds and text.
  static const adwaitaLightWindow = Color(0xFFFAFAFB);
  static const adwaitaLightView = Color(0xFFFFFFFF);
  static const adwaitaLightCard = Color(0xFFFFFFFF);
  static const adwaitaLightText = Color(0xFF333338); // rgba(0,0,6,0.8) on white
  static const adwaitaDarkWindow = Color(0xFF222226);
  static const adwaitaDarkView = Color(0xFF1D1D20);
  static const adwaitaDarkCard = Color(0xFF343437); // 8% white on window
  static const adwaitaDarkText = Color(0xFFFFFFFF);

  // Breeze (Plasma 6) window, view and button backgrounds and text.
  static const breezeLightWindow = Color(0xFFEFF0F1);
  static const breezeLightView = Color(0xFFFFFFFF);
  static const breezeLightCard = Color(0xFFFCFCFC);
  static const breezeLightText = Color(0xFF232629);
  static const breezeDarkWindow = Color(0xFF202326);
  static const breezeDarkView = Color(0xFF141618);
  static const breezeDarkCard = Color(0xFF292C30);
  static const breezeDarkText = Color(0xFFFCFCFC);

  /// The app's accent: emerald, or the desktop accent on GNOME and KDE.
  /// Use this instead of [emerald] for anything that should follow it.
  static Color accentOf(BuildContext ctx) => BrandColors.of(ctx).accent;

  /// The gradient partner of [accentOf]: teal next to emerald.
  static Color secondaryOf(BuildContext ctx) => BrandColors.of(ctx).secondary;
}
