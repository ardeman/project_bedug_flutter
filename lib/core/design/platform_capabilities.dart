import 'dart:io';

import 'package:flutter/foundation.dart';

class PlatformCapabilities {
  PlatformCapabilities._();

  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }
}
