import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../constants/app_colors.dart';
import '../theme/app_tokens.dart';

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

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final mq = MediaQuery.of(ctx);
    final bottomInset = mq.padding.bottom;
    final width = math.min(mq.size.width - AppSpacing.md * 2, _maxWidth);
    return LiquidGlassTabBar(
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
      // Float above the home indicator, or just off the window edge.
      margin: EdgeInsets.only(
        bottom: bottomInset > 0 ? AppSpacing.lg : AppSpacing.sm,
      ),
      style: LiquidGlassTabBar.defaultStyle.copyWith(color: glassTintOf(ctx)),
      itemStyle: LiquidGlassTabItemStyle(
        selectedColor: AppColors.accentOf(ctx),
        unselectedColor: theme.colorScheme.onSurface.withValues(alpha: 0.62),
        iconSize: 22,
        labelFontSize: theme.textTheme.labelSmall?.fontSize ?? 11,
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
