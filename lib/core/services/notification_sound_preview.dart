import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'notification_preferences.dart';

/// Plays a bundled alert sound once when the user picks it, so they hear
/// what the alert will sound like. The system sound and silence have
/// nothing to play.
abstract final class NotificationSoundPreview {
  /// Replaces the real playback in tests.
  @visibleForTesting
  static ValueChanged<PrayerNotificationSound>? debugOverride;

  static AudioPlayer? _player;

  static Future<void> play(PrayerNotificationSound sound) async {
    if (debugOverride != null) return debugOverride!(sound);
    final player = _player ??= AudioPlayer();
    try {
      // A new pick cuts off the previous preview.
      await player.stop();
      final resource = sound.resource;
      if (resource != null) {
        await player.play(AssetSource('sounds/$resource.wav'));
      }
    } catch (_) {
      // No audio output (or no audio plugin): the preview is optional.
    }
  }

  static Future<void> stop() async {
    if (debugOverride != null) return;
    try {
      await _player?.stop();
    } catch (_) {}
  }
}
