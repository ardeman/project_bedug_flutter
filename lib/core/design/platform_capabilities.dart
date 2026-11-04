import 'package:flutter/foundation.dart';

class PlatformCapabilities {
  PlatformCapabilities._();

  static bool get isIOS {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool get isMacOS {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.macOS;
  }

  static bool get isApple {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Whether the app is installed from a store that delivers its updates
  /// (App Store on iOS and macOS, Google Play on Android). Store policies
  /// forbid pointing those users to downloads elsewhere, so the manual
  /// update check only appears on Windows and Linux.
  static bool get updatesThroughStore {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS ||
      TargetPlatform.macOS ||
      TargetPlatform.android => true,
      _ => false,
    };
  }
}
