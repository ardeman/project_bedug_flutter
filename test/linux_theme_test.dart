import 'package:bedug/core/constants/app_colors.dart';
import 'package:bedug/core/design/linux_desktop.dart';
import 'package:bedug/core/providers/system_accent_provider.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('linuxDesktopFrom', () {
    test('reads the GNOME family from XDG_CURRENT_DESKTOP', () {
      for (final value in [
        'GNOME',
        'ubuntu:GNOME',
        'Budgie:GNOME',
        'Pantheon',
        'X-Cinnamon',
      ]) {
        expect(linuxDesktopFrom({'XDG_CURRENT_DESKTOP': value}),
            LinuxDesktop.gnome,
            reason: value);
      }
    });

    test('reads KDE', () {
      expect(
          linuxDesktopFrom({'XDG_CURRENT_DESKTOP': 'KDE'}), LinuxDesktop.kde);
    });

    test('falls back to DESKTOP_SESSION', () {
      expect(linuxDesktopFrom({'DESKTOP_SESSION': 'plasma'}), LinuxDesktop.kde);
      expect(
          linuxDesktopFrom(
              {'XDG_CURRENT_DESKTOP': '', 'DESKTOP_SESSION': 'gnome'}),
          LinuxDesktop.gnome);
    });

    test('keeps Material 3 elsewhere', () {
      expect(linuxDesktopFrom({'XDG_CURRENT_DESKTOP': 'XFCE'}),
          LinuxDesktop.other);
      expect(linuxDesktopFrom({}), LinuxDesktop.other);
    });
  });

  group('accentFromPortalValue', () {
    DBusValue rgb(double r, double g, double b) =>
        DBusStruct([DBusDouble(r), DBusDouble(g), DBusDouble(b)]);

    test('parses an sRGB struct, also inside variants', () {
      final color =
          accentFromPortalValue(DBusVariant(DBusVariant(rgb(1, 0, 0.5))));
      expect(color, isNotNull);
      expect(color!.r, 1);
      expect(color.g, 0);
      expect(color.b, closeTo(0.5, 0.001));
    });

    test('treats out-of-range channels as no accent', () {
      expect(accentFromPortalValue(rgb(-1, -1, -1)), isNull);
      expect(accentFromPortalValue(DBusString('blue')), isNull);
    });
  });

  group('buildAppTheme', () {
    const blue = Color(0xFF3584E4);

    test('keeps the brand theme off GNOME and KDE', () {
      final theme = buildAppTheme(Brightness.light, accent: blue);
      expect(theme.scaffoldBackgroundColor, AppColors.lightBg);
      expect(theme.extension<BrandColors>()!.accent, AppColors.emerald);
    });

    test('uses Adwaita surfaces and the desktop accent on GNOME', () {
      final theme = buildAppTheme(Brightness.dark,
          desktop: LinuxDesktop.gnome, accent: blue);
      expect(theme.scaffoldBackgroundColor, AppColors.adwaitaDarkWindow);
      expect(theme.colorScheme.primary, blue);
      expect(theme.extension<BrandColors>()!.accent, blue);
      expect(theme.textTheme.bodyMedium!.fontFamily, 'Adwaita Sans');
    });

    test('uses Breeze surfaces and emerald without an accent on KDE', () {
      final theme = buildAppTheme(Brightness.light, desktop: LinuxDesktop.kde);
      expect(theme.scaffoldBackgroundColor, AppColors.breezeLightWindow);
      expect(theme.extension<BrandColors>()!.accent, AppColors.emerald);
      expect(theme.textTheme.bodyMedium!.fontFamily, 'Noto Sans');
    });
  });
}
