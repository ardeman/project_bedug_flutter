import 'package:flutter/foundation.dart';

/// Where a build is distributed, passed as `--dart-define=CHANNEL=<name>`.
/// Store billing only works inside its own store and some stores ban ad
/// SDKs, so the infaq method and the ads follow the channel, not only the
/// platform. See "Revenue: ads and infaq" in `README.md`.
enum DistributionChannel {
  /// Android on Google Play: AdMob and Play Billing.
  play,

  /// iOS and the Mac App Store: AdMob on iOS only, and StoreKit.
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

  /// Whether builds for [platform] show ads: AdMob only has Android and
  /// iOS SDKs, and F-Droid bans it.
  bool showsAdsOn(TargetPlatform platform) =>
      !kIsWeb &&
      this != fdroid &&
      (platform == TargetPlatform.android || platform == TargetPlatform.iOS);
}
