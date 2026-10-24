import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'platform_capabilities.dart';

/// The system display settings that change how Liquid Glass looks: the
/// Clear/Tinted style, and Reduce Transparency and Increase Contrast.
///
/// Apple has no API for the Clear/Tinted style. macOS stores it as
/// `NSGlassTintAmount` in the global defaults (0 for Clear, more for Tinted),
/// which the native side reads when present; elsewhere glass stays Clear.
@immutable
class GlassAccessibility {
  final bool reduceTransparency;
  final bool increaseContrast;

  /// How tinted the system's Liquid Glass is, from 0 (Clear) to 1.
  final double tintAmount;

  const GlassAccessibility({
    this.reduceTransparency = false,
    this.increaseContrast = false,
    this.tintAmount = 0,
  });

  /// Clear glass with no accessibility setting turned on.
  static const standard = GlassAccessibility();

  /// The settings for [ctx]: the native ones from [GlassAccessibilityScope],
  /// with Increase Contrast also taken from Flutter's own accessibility
  /// features (which report it on iOS).
  static GlassAccessibility of(BuildContext ctx) {
    final native =
        ctx
            .dependOnInheritedWidgetOfExactType<GlassAccessibilityScope>()
            ?.settings ??
        standard;
    return GlassAccessibility(
      reduceTransparency: native.reduceTransparency,
      increaseContrast:
          native.increaseContrast || MediaQuery.highContrastOf(ctx),
      tintAmount: native.tintAmount,
    );
  }

  /// How far glass moves from its clear tint to its opaque one: all the way
  /// with Increase Contrast, else by the system's tint amount.
  double get opacity => increaseContrast ? 1 : tintAmount;

  /// Reads the map sent by the native `glass_accessibility` channel.
  factory GlassAccessibility.fromMap(Map<Object?, Object?> map) =>
      GlassAccessibility(
        reduceTransparency: map['reduceTransparency'] == true,
        increaseContrast: map['increaseContrast'] == true,
        tintAmount: switch (map['tintAmount']) {
          final num amount => amount.toDouble().clamp(0, 1),
          _ => 0,
        },
      );

  @override
  bool operator ==(Object other) =>
      other is GlassAccessibility &&
      other.reduceTransparency == reduceTransparency &&
      other.increaseContrast == increaseContrast &&
      other.tintAmount == tintAmount;

  @override
  int get hashCode =>
      Object.hash(reduceTransparency, increaseContrast, tintAmount);
}

const _channel = EventChannel('com.ardeman.bedug/glass_accessibility');

/// The native glass settings on iOS (`AppDelegate.swift`) and macOS
/// (`MainFlutterWindow.swift`), updated live when the user changes them.
/// Other platforms have no Liquid Glass.
final glassAccessibilityProvider = StreamProvider<GlassAccessibility>((ref) {
  if (!PlatformCapabilities.isApple) {
    return Stream.value(GlassAccessibility.standard);
  }
  return _channel
      .receiveBroadcastStream()
      .map(
        (event) => GlassAccessibility.fromMap(event as Map<Object?, Object?>),
      )
      .handleError((Object _) {}, test: (e) => e is MissingPluginException);
});

/// Shares the native glass settings with the widgets below it; read them
/// with [GlassAccessibility.of].
class GlassAccessibilityScope extends InheritedWidget {
  final GlassAccessibility settings;

  const GlassAccessibilityScope({
    super.key,
    required this.settings,
    required super.child,
  });

  @override
  bool updateShouldNotify(GlassAccessibilityScope oldWidget) =>
      settings != oldWidget.settings;
}
