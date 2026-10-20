import 'package:flutter/foundation.dart';

import 'linux_desktop.dart';

/// Platform detection for the adaptive design.
enum DesignSystem { liquidGlass, materialYou, fluentDesign }

class PlatformDesign {
  static DesignSystem get current {
    if (kIsWeb) return DesignSystem.materialYou;
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return DesignSystem.liquidGlass;
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return DesignSystem.fluentDesign;
    }
    return DesignSystem.materialYou; // Android, Linux
  }

  static bool get isApple => current == DesignSystem.liquidGlass;
  static bool get isWindows => current == DesignSystem.fluentDesign;
  static bool get isMaterial => current == DesignSystem.materialYou;
  static bool get usesExpressive =>
      isMaterial && currentLinuxDesktop == LinuxDesktop.other;
}
