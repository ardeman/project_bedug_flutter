/// Spacing steps on a 4-pt grid. Use these for padding and gaps instead of
/// raw numbers so screens share one rhythm.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii. Large, soft corners for cards and sheets; controls are
/// pill-shaped through the theme (`StadiumBorder`).
abstract final class AppRadii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 28;
}

/// The brand typeface, bundled in `assets/fonts/plus_jakarta_sans/`.
const kBrandFont = 'PlusJakartaSans';
