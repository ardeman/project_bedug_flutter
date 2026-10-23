import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'notification_preferences.dart';

/// Opens Android's own notification sound picker (`MainActivity.kt`), so an
/// alert can play a tone already on the phone. iOS and macOS can't use the
/// system's installed tones in a notification.
abstract final class PhoneSoundPicker {
  static const _channel = MethodChannel('com.ardeman.bedug/phone_sound');

  /// Replaces the native picker in tests.
  @visibleForTesting
  static Future<PhoneSound?> Function(PhoneSound? current)? debugOverride;

  /// Whether this platform has a phone sound picker.
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// The tone the user picked, or null if they cancelled.
  static Future<PhoneSound?> pick({PhoneSound? current}) async {
    if (debugOverride != null) return debugOverride!(current);
    try {
      final picked = await _channel.invokeMapMethod<String, String>('pick', {
        'current': current?.uri,
      });
      if (picked case {'uri': final uri, 'title': final title}) {
        return PhoneSound(uri: uri, title: title);
      }
    } on PlatformException catch (_) {
      // Already open, or no picker on this device.
    } on MissingPluginException catch (_) {}
    return null;
  }
}
