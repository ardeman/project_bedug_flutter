import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The tick a picker gives as its selection moves: a haptic tap where the
/// device has a haptic engine, and a soft click sound where it doesn't.
///
/// - iPhone and Android: [HapticFeedback.selectionClick].
/// - iPad (no haptic engine): the system keyboard click.
/// - macOS, Windows and Linux: a bundled tick sound, since Flutter's system
///   click plays only on mobile.
abstract final class SelectionFeedback {
  /// Replaces the real feedback in tests.
  @visibleForTesting
  static VoidCallback? debugOverride;

  /// Smallest width, in logical pixels, of a tablet screen; iPhones are
  /// narrower. iPads have no haptic engine.
  static const _tabletShortestSide = 600.0;

  /// Players kept ready, so ticks during a fast fling can overlap.
  static const _maxPlayers = 4;

  /// Quieter than full volume: the tick should be felt more than heard.
  static const _volume = 0.6;

  static Future<AudioPool>? _pool;

  static void tick() {
    if (debugOverride != null) return debugOverride!();
    if (kIsWeb) return;
    if (Platform.isAndroid || (Platform.isIOS && !_isTablet)) {
      HapticFeedback.selectionClick();
    } else if (Platform.isIOS) {
      SystemSound.play(SystemSoundType.click);
    } else {
      _playTick();
    }
  }

  static bool get _isTablet {
    final views = PlatformDispatcher.instance.views;
    if (views.isEmpty) return false;
    final view = views.first;
    return view.physicalSize.shortestSide / view.devicePixelRatio >=
        _tabletShortestSide;
  }

  static Future<void> _playTick() async {
    try {
      final pool = await (_pool ??= AudioPool.createFromAsset(
        path: 'sounds/selection_tick.wav',
        maxPlayers: _maxPlayers,
      ));
      await pool.start(volume: _volume);
    } catch (_) {
      // No audio output (or no audio plugin): a missing tick isn't worth
      // an error. Try to load again next time.
      _pool = null;
    }
  }
}
