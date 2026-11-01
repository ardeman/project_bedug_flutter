import 'package:flutter/foundation.dart';

/// Where a build is distributed, passed as `--dart-define=CHANNEL=<name>`.
/// Store billing only works inside its own store, so the infaq method
/// follows the channel, not only the platform. See "Revenue: infaq" in `README.md`.
enum DistributionChannel {
  /// Android on Google Play: Play Billing.
  play,

  /// iOS and the Mac App Store: StoreKit.
  appStore,

  /// Windows, Linux and sideloaded builds: Trakteer and Ko-fi links.
  direct,

  /// Android on F-Droid: no proprietary SDKs, so links only.
  fdroid;

  /// The channel this build was made for. Without a define, a build gets
  /// its platform's store, so `flutter run` behaves like a store build.
  static DistributionChannel get current =>
      parse(const String.fromEnvironment('CHANNEL'), defaultTargetPlatform);

  static DistributionChannel parse(String name, TargetPlatform platform) =>
      switch (name) {
        'play' => play,
        'appstore' => appStore,
        'direct' => direct,
        'fdroid' => fdroid,
        _ when kIsWeb => direct,
        _ => switch (platform) {
          TargetPlatform.android => play,
          TargetPlatform.iOS || TargetPlatform.macOS => appStore,
          _ => direct,
        },
      };

  /// Whether infaq is an in-app purchase rather than an external link.
  bool get usesStoreBilling => this == play || this == appStore;
}
