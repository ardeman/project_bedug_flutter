import 'package:flutter/material.dart' as bundled;
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../design/platform_design.dart';
import 'app_tokens.dart';

/// Keeps package components on the app's chosen theme, including overlays.
class AppThemeScope extends StatelessWidget {
  const AppThemeScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // liquid_glass_easy reads Flutter's bundled Theme. Bridge it while the
    // app uses material_ui so its controls follow manual theme changes.
    // Cover the whole window, including a foldable phone's side status area.
    // App bars and the prayer hero can override this for their backgrounds.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: bundled.Theme(
        data: bundled.ThemeData(
          brightness: theme.brightness,
          colorScheme:
              bundled.ColorScheme.fromSeed(
                seedColor: scheme.primary,
                brightness: theme.brightness,
              ).copyWith(
                primary: scheme.primary,
                onPrimary: scheme.onPrimary,
                surface: scheme.surface,
                onSurface: scheme.onSurface,
              ),
          fontFamily: kBrandFont,
        ),
        child: PlatformDesign.usesExpressive
            ? M3ETheme(
                data: M3EThemeData.fromMaterial(theme)
                    .copyWith(fontFamily: kBrandFont),
                child: child,
              )
            : child,
      ),
    );
  }
}
