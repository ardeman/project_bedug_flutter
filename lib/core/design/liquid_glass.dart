import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../constants/app_colors.dart';
import '../theme/app_tokens.dart';
import 'platform_capabilities.dart';

/// Glass tint for bars and controls that float over content: milky in
/// light mode, smoked in dark mode, so their icons and text stay legible.
Color glassTintOf(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.55);

/// The floating Liquid Glass tab bar on iOS and macOS: a refracting
/// capsule whose selection pill can be tapped or dragged between tabs.
///
/// It places itself at the bottom of its parent, so put it last in a
/// [Stack] over the page.
class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  /// Bar height without the system inset (see AGENTS.md).
  static const height = 64.0;

  /// Widest the bar grows on tablets and desktop windows.
  static const _maxWidth = 440.0;

  /// Gap between the bar and the screen's bottom edge on devices with a
  /// home indicator. Like the native iOS 26 tab bar, the bar sits inside
  /// the bottom safe-area inset (34pt on Face ID iPhones), not above it.
  static const _homeIndicatorGap = 21.0;

  /// Gap between the bar and the bottom edge: over the home indicator
  /// area, or just off the window edge.
  static double _bottomGapOf(BuildContext ctx) =>
      MediaQuery.of(ctx).padding.bottom > 0 ? _homeIndicatorGap : AppSpacing.sm;

  /// How much of the screen bottom the floating bar covers, measured from
  /// the bottom edge, for the bottom padding of the page under it.
  static double occupiedHeight(BuildContext ctx) =>
      _bottomGapOf(ctx) + height + AppSpacing.xs;

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final mq = MediaQuery.of(ctx);
    final width = math.min(mq.size.width - AppSpacing.md * 2, _maxWidth);
    final bottomGap = _bottomGapOf(ctx);
    // The tab bar adds the bottom safe-area inset to its margin; drop the
    // inset so the gap is measured from the screen edge.
    return MediaQuery.removePadding(
      context: ctx,
      removeBottom: true,
      child: LiquidGlassTabBar(
        items: [
          for (final item in items)
            LiquidGlassTabBarItem(
              icon: item.icon,
              selectedIcon: item.activeIcon,
              label: item.label,
              // Long translations would wrap and overflow the bar.
              labelBuilder: (_, l) => Text(
                l.text ?? '',
                style: l.textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        selectedIndex: currentIndex,
        onChanged: onTap,
        width: width,
        height: height,
        margin: EdgeInsets.only(bottom: bottomGap),
        style: LiquidGlassTabBar.defaultStyle.copyWith(color: glassTintOf(ctx)),
        itemStyle: LiquidGlassTabItemStyle(
          selectedColor: AppColors.accentOf(ctx),
          unselectedColor: theme.colorScheme.onSurface.withValues(alpha: 0.62),
          iconSize: 22,
          labelFontSize: theme.textTheme.labelSmall?.fontSize ?? 11,
        ),
      ),
    );
  }
}

class GlassNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// The top bar of a tab. On iOS and macOS the title floats in a glass
/// capsule over a scroll-edge band, so the page scrolls under it; give the
/// [Scaffold] `extendBodyBehindAppBar: PlatformCapabilities.isApple`.
/// Elsewhere it is the accent [AppBar].
class GlassTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const GlassTopBar({super.key, required this.title});

  /// Height of the title capsule: one title line plus padding.
  static const _capsuleHeight = 40.0;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    if (!PlatformCapabilities.isApple) {
      return AppBar(
        title: Text(title),
        backgroundColor: AppColors.accentOf(ctx),
        foregroundColor: Colors.white,
        centerTitle: true,
      );
    }

    return SizedBox(
      height: kToolbarHeight + MediaQuery.of(ctx).padding.top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Scroll edge: keeps the title legible over the page below.
          IgnorePointer(
            child: LiquidGlassScrollEdge(
              edge: LiquidGlassEdge.top,
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Center(
              child: SizedBox(
                height: _capsuleHeight,
                child: LiquidGlassLens(
                  style: LiquidGlassStyle(
                    shape: const LiquidGlassShape.continuousRoundedRectangle(
                        cornerRadius: _capsuleHeight / 2),
                    color: glassTintOf(ctx),
                    blur: 6,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
