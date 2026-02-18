import 'dart:io';
import 'package:flutter/foundation.dart';

/// Deteksi platform untuk adaptive design
enum DesignSystem { liquidGlass, materialYou, fluentDesign }

class PlatformDesign {
  static DesignSystem get current {
    if (kIsWeb) return DesignSystem.materialYou;
    if (Platform.isIOS || Platform.isMacOS) return DesignSystem.liquidGlass;
    if (Platform.isWindows) return DesignSystem.fluentDesign;
    return DesignSystem.materialYou; // Android, Linux
  }

  static bool get isApple => current == DesignSystem.liquidGlass;
  static bool get isWindows => current == DesignSystem.fluentDesign;
  static bool get isMaterial => current == DesignSystem.materialYou;
}