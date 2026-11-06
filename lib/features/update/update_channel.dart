import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where this build's updates come from.
enum UpdateChannel {
  /// A build from the GitHub releases: the app downloads, verifies and
  /// installs the new release itself.
  github,

  /// Google Play: Play's in-app update flow downloads and installs it.
  playStore,

  /// The App Store: the app opens its listing, where the user updates.
  appStore,

  /// No update path (web, tests).
  none,
}

/// Set to `github` with `--dart-define=BEDUG_DISTRIBUTION=github` for the
/// builds published on GitHub. Windows and Linux are only published there.
const _distribution = String.fromEnvironment('BEDUG_DISTRIBUTION');

UpdateChannel updateChannelFor(
  TargetPlatform platform, {
  bool isWeb = false,
  String distribution = _distribution,
}) {
  if (isWeb) return UpdateChannel.none;
  final github = distribution == 'github';
  return switch (platform) {
    TargetPlatform.windows || TargetPlatform.linux => UpdateChannel.github,
    TargetPlatform.android =>
      github ? UpdateChannel.github : UpdateChannel.playStore,
    TargetPlatform.macOS =>
      github ? UpdateChannel.github : UpdateChannel.appStore,
    TargetPlatform.iOS => UpdateChannel.appStore,
    TargetPlatform.fuchsia => UpdateChannel.none,
  };
}

/// This build's update channel; [UpdateChannel.none] under `flutter test`, so
/// widget tests never reach the network or the stores.
final updateChannelProvider = Provider<UpdateChannel>((ref) {
  if (kIsWeb) return UpdateChannel.none;
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return UpdateChannel.none;
  }
  return updateChannelFor(defaultTargetPlatform);
});
