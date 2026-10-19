import 'dart:io';

import 'package:flutter/foundation.dart';

/// Linux desktop families whose look Bedug follows.
enum LinuxDesktop {
  /// GNOME and desktops built on GTK/Adwaita (Budgie, Pantheon, Cinnamon).
  gnome,

  /// KDE Plasma (Breeze).
  kde,

  /// Any other desktop, or not Linux at all: keeps Material 3.
  other,
}

const _gnomeFamily = {
  'gnome',
  'gnome-classic',
  'gnome-flashback',
  'ubuntu',
  'budgie',
  'budgie-desktop',
  'pantheon',
  'cinnamon',
  'x-cinnamon',
};

const _kdeFamily = {'kde', 'plasma', 'kde-plasma', 'plasmawayland'};

/// Detects the desktop from `XDG_CURRENT_DESKTOP` (a colon-separated list,
/// e.g. `ubuntu:GNOME`), falling back to `DESKTOP_SESSION`.
LinuxDesktop linuxDesktopFrom(Map<String, String> env) {
  for (final name in ['XDG_CURRENT_DESKTOP', 'DESKTOP_SESSION']) {
    final tokens = (env[name] ?? '')
        .toLowerCase()
        .split(':')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty);
    for (final token in tokens) {
      if (_kdeFamily.contains(token)) return LinuxDesktop.kde;
      if (_gnomeFamily.contains(token)) return LinuxDesktop.gnome;
    }
  }
  return LinuxDesktop.other;
}

/// The desktop the app runs on; [LinuxDesktop.other] off Linux.
final LinuxDesktop currentLinuxDesktop = !kIsWeb && Platform.isLinux
    ? linuxDesktopFrom(Platform.environment)
    : LinuxDesktop.other;
