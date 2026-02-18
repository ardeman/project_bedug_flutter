import 'dart:io';

import 'package:flutter/foundation.dart';

class PlatformCapabilities {
  PlatformCapabilities._();

  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  static bool get isApple {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }
}
