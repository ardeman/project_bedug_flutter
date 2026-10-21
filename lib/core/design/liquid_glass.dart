import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../constants/app_colors.dart';
import '../theme/app_tokens.dart';
import 'platform_capabilities.dart';
import 'platform_design.dart';

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
    final direction = Directionality.of(ctx);
    final isRtl = direction == TextDirection.rtl;
    final visualItems = isRtl ? items.reversed : items;
    int visualIndex(int index) => isRtl ? items.length - 1 - index : index;
    // The tab bar adds the bottom safe-area inset to its margin; drop the
    // inset so the gap is measured from the screen edge.
    return MediaQuery.removePadding(
      context: ctx,
      removeBottom: true,
      // The package measures taps, drags and pill offsets from the left.
      // Reverse the items explicitly so its geometry also matches RTL labels.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: LiquidGlassTabBar(
          items: [
            for (final item in visualItems)
              LiquidGlassTabBarItem(
                icon: item.icon,
                selectedIcon: item.activeIcon,
                label: item.label,
                // Long translations would wrap and overflow the bar.
                labelBuilder: (_, l) => Text(
                  l.text ?? '',
                  textDirection: direction,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: l.textStyle.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          selectedIndex: visualIndex(currentIndex),
          onChanged: (index) => onTap(visualIndex(index)),
          width: width,
          height: height,
          margin: EdgeInsets.only(bottom: bottomGap),
          style: LiquidGlassTabBar.defaultStyle.copyWith(
            color: glassTintOf(ctx),
          ),
          itemStyle: LiquidGlassTabItemStyle(
            selectedColor: AppColors.accentOf(ctx),
            unselectedColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.62,
            ),
            iconSize: AppControlSizes.navigationIcon,
            labelFontSize: theme.textTheme.labelSmall!.fontSize!,
          ),
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

/// Width of the macOS traffic lights, which sit in the window's top leading
/// corner: a 14 inset, three 14 buttons and two 10 gaps (see
/// `macos/Runner/MainFlutterWindow.swift`).
const _macWindowControlsWidth = 14.0 + 3 * 14.0 + 2 * 10.0;

/// Leading space that content on a top bar's row leaves for the window
/// controls: the traffic-light width on macOS, zero elsewhere.
double get windowControlsInset =>
    PlatformCapabilities.isMacOS ? _macWindowControlsWidth : 0;

/// The top bar of a tab or a pushed page. On iOS and macOS the title floats
/// in a glass capsule over a scroll-edge band, so the page scrolls under it;
/// give the [Scaffold] `extendBodyBehindAppBar: PlatformCapabilities.isApple`.
/// A pushed page also gets a round glass back button. Elsewhere it is the
/// accent [AppBar], which adds its own back button.
class GlassTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const GlassTopBar({super.key, required this.title});

  /// Height of the title capsule: one title line plus padding.
  static const _capsuleHeight = AppControlSizes.toolbarButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    if (PlatformDesign.usesExpressive) {
      return M3EAppBar.top(
        title: Text(
          title,
          style: theme.textTheme.titleLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        automaticallyImplyLeading: true,
        toolbarHeight: kToolbarHeight,
      );
    }
    if (!PlatformCapabilities.isApple) {
      return AppBar(
        title: Text(title),
        backgroundColor: AppColors.accentOf(ctx),
        foregroundColor: Colors.white,
        centerTitle: true,
      );
    }

    final canPop = ModalRoute.of(ctx)?.impliesAppBarDismissal ?? false;
    // Reserve the same space on both sides to keep the title centered and
    // clear of the back button and macOS traffic lights, including in RTL.
    final titleInset =
        AppSpacing.md +
        windowControlsInset +
        (canPop ? AppControlSizes.toolbarButton + AppSpacing.xs : 0);
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: titleInset),
              child: Center(
                child: SizedBox(
                  height: _capsuleHeight,
                  child: LiquidGlassLens(
                    style: LiquidGlassStyle(
                      shape: const LiquidGlassShape.continuousRoundedRectangle(
                        cornerRadius: _capsuleHeight / 2,
                      ),
                      color: glassTintOf(ctx),
                      blur: 6,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (canPop)
            SafeArea(
              bottom: false,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: AppSpacing.md + windowControlsInset,
                  ),
                  child: Semantics(
                    button: true,
                    label: MaterialLocalizations.of(ctx).backButtonTooltip,
                    child: GlassIconButton(
                      icon: Icons.arrow_back_ios_new,
                      onPressed: () => Navigator.of(ctx).maybePop(),
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

/// A content card: lite Liquid Glass on iOS and macOS, a Material [Card]
/// elsewhere. Lite glass, not a lens, because cards scroll with their list.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;

  const GlassCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext ctx) {
    if (PlatformDesign.usesExpressive) {
      return Padding(
        padding: margin,
        child: M3ECard(
          variant: M3ECardVariant.filled,
          padding: EdgeInsets.zero,
          expanded: true,
          child: child,
        ),
      );
    }
    if (!PlatformCapabilities.isApple) {
      return Card(margin: margin, clipBehavior: Clip.antiAlias, child: child);
    }
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Padding(
      padding: margin,
      child: Material(
        color: Colors.transparent,
        child: LiquidGlassLite(
          shape: const LiquidGlassShape.continuousRoundedRectangle(
            cornerRadius: AppRadii.lg,
          ),
          blur: 10,
          color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.62),
          // The glass doesn't clip its child on every renderer; keep ink
          // splashes inside the continuous corners.
          child: ClipRSuperellipse(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A round, refracting Liquid Glass icon button for iOS and macOS.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  /// Icon color; defaults to `onSurface`.
  final Color? color;

  /// Diameter: a standard toolbar control.
  final double size;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = AppControlSizes.toolbarButton,
  });

  @override
  Widget build(BuildContext ctx) {
    return LiquidGlassButton(
      icon: icon,
      onPressed: onPressed,
      width: size,
      height: size,
      padding: EdgeInsets.zero,
      iconSize: AppControlSizes.toolbarIcon,
      foregroundColor: color ?? Theme.of(ctx).colorScheme.onSurface,
      style: LiquidGlassStyle(
        shape: LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: size / 2,
        ),
        color: glassTintOf(ctx),
      ),
    );
  }
}
