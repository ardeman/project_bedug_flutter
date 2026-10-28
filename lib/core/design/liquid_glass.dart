import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../constants/app_colors.dart';
import '../theme/app_tokens.dart';
import 'glass_accessibility.dart';
import 'glass_controls.dart';
import 'platform_capabilities.dart';
import 'platform_design.dart';

/// Picks a glass tint from the system settings ([GlassAccessibility]): the
/// solid surface with Reduce Transparency, else an alpha between the clear
/// one and the opaque one by [GlassAccessibility.opacity], so glass follows
/// the system's Clear/Tinted style and Increase Contrast.
Color _adaptiveTint(
  BuildContext ctx, {
  required Color light,
  required Color dark,
  required double lightAlpha,
  required double darkAlpha,
  required double lightOpaqueAlpha,
  required double darkOpaqueAlpha,
}) {
  final theme = Theme.of(ctx);
  final glass = GlassAccessibility.of(ctx);
  if (glass.reduceTransparency) return theme.colorScheme.surface;
  final t = glass.opacity;
  return theme.brightness == Brightness.dark
      ? dark.withValues(alpha: lerpDouble(darkAlpha, darkOpaqueAlpha, t))
      : light.withValues(alpha: lerpDouble(lightAlpha, lightOpaqueAlpha, t));
}

/// Glass tint for bars and controls that float over content: a light
/// veil when Clear, milky (light) or smoked (dark) when Tinted.
Color glassTintOf(BuildContext ctx) => _adaptiveTint(
  ctx,
  light: Colors.white,
  dark: Colors.black,
  lightAlpha: 0.08,
  darkAlpha: 0.05,
  lightOpaqueAlpha: 0.85,
  darkOpaqueAlpha: 0.6,
);

/// Glass tint for content cards that scroll with their list: a white frost
/// that is faint when Clear and milky when Tinted.
Color glassCardTintOf(BuildContext ctx) => _adaptiveTint(
  ctx,
  light: Colors.white,
  dark: Colors.white,
  lightAlpha: 0.15,
  darkAlpha: 0.02,
  lightOpaqueAlpha: 0.88,
  darkOpaqueAlpha: 0.16,
);

/// Glass tint for sheets that cover most of the screen, heavier than
/// [glassTintOf] so a long list stays readable over the page behind.
Color glassSheetTintOf(BuildContext ctx) => _adaptiveTint(
  ctx,
  light: Colors.white,
  dark: Colors.black,
  lightAlpha: 0.35,
  darkAlpha: 0.25,
  lightOpaqueAlpha: 0.94,
  darkOpaqueAlpha: 0.82,
);

/// The floating Liquid Glass tab bar on iOS and macOS: a refracting
/// capsule whose selection pill can be tapped or dragged between tabs.
///
/// It places itself at the bottom of its parent, so put it last in a
/// [Stack] over the page. Where the system keeps a vertical bar on one side
/// of the screen, as iPhone Duo does, it becomes a rail in that bar instead
/// (see [railSideOf]).
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

  /// Bar height in a short window, such as a phone in landscape, where a
  /// full bar would cover a fifth of the screen. It still fits a smaller
  /// icon over its label.
  static const compactHeight = 52.0;

  /// Windows shorter than this get the compact bar: every phone in
  /// landscape (440 at most) but no phone in portrait (568 at least).
  static const _compactMaxWindowHeight = 500.0;

  static bool _isCompact(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).height < _compactMaxWindowHeight;

  /// The bar's height in this window: [compactHeight] when it is short.
  static double heightOf(BuildContext ctx) =>
      _isCompact(ctx) ? compactHeight : height;

  /// Largest text scale whose label still fits under the icon, even in
  /// the [compactHeight] bar.
  static const _maxLabelTextScale = 1.1;

  /// Widest the bar grows on tablets and desktop windows.
  static const _maxWidth = 440.0;

  /// Gap between the bar and the screen's bottom edge on devices with a
  /// home indicator. Like the native iOS 26 tab bar, the bar sits inside
  /// the bottom safe-area inset (34pt on Face ID iPhones), not above it.
  static const _homeIndicatorGap = 21.0;

  /// Gap between the bar and the bottom edge: over the home indicator
  /// area, or just off the window edge. A short window (a phone in
  /// landscape, whose home indicator inset is smaller) uses the window-edge
  /// gap, which still clears the indicator.
  static double _bottomGapOf(BuildContext ctx) =>
      MediaQuery.of(ctx).padding.bottom > 0 && !_isCompact(ctx)
      ? _homeIndicatorGap
      : AppSpacing.sm;

  /// How much of the screen bottom the floating bar covers, measured from
  /// the bottom edge, for the bottom padding of the page under it. A rail
  /// covers none of it, so the page only keeps clear of the home indicator.
  static double occupiedHeight(BuildContext ctx) => railSideOf(ctx) != null
      ? MediaQuery.of(ctx).padding.bottom
      : _bottomGapOf(ctx) + heightOf(ctx) + AppSpacing.xs;

  /// The side of the system's vertical bar, or null when there is none.
  ///
  /// iPhone Duo moves the status bar and the Dynamic Island into a bar along
  /// one side (the right, or the outer edge in Split View), reported as a
  /// safe-area inset on that side only, and puts the tab bar there too so it
  /// sits under the right thumb. Other iPhones in landscape inset both sides
  /// equally, so an uneven inset means the vertical bar.
  static TextDirection? railSideOf(BuildContext ctx) {
    final padding = MediaQuery.paddingOf(ctx);
    if (padding.left == padding.right) return null;
    return padding.right > padding.left ? TextDirection.rtl : TextDirection.ltr;
  }

  @override
  Widget build(BuildContext ctx) {
    final railSide = railSideOf(ctx);
    if (railSide != null) {
      return _GlassNavRail(
        side: railSide,
        bottomGap: _bottomGapOf(ctx),
        compact: _isCompact(ctx),
        currentIndex: currentIndex,
        onTap: onTap,
        items: items,
      );
    }
    final theme = Theme.of(ctx);
    final mq = MediaQuery.of(ctx);
    final width = math.min(mq.size.width - AppSpacing.md * 2, _maxWidth);
    final bottomGap = _bottomGapOf(ctx);
    final compact = _isCompact(ctx);
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
                  // The bar has no room for enlarged text; like the native
                  // tab bar, its labels stop growing with Dynamic Type.
                  textScaler: mq.textScaler.clamp(
                    maxScaleFactor: _maxLabelTextScale,
                  ),
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
          height: heightOf(ctx),
          margin: EdgeInsets.only(bottom: bottomGap),
          style: LiquidGlassTabBar.defaultStyle.copyWith(
            color: glassTintOf(ctx),
          ),
          itemStyle: LiquidGlassTabItemStyle(
            selectedColor: AppColors.accentOf(ctx),
            unselectedColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.62,
            ),
            iconSize: compact
                ? AppControlSizes.toolbarIcon
                : AppControlSizes.navigationIcon,
            labelFontSize: theme.textTheme.labelSmall!.fontSize!,
          ),
        ),
      ),
    );
  }
}

/// Keeps [child] clear of the system's vertical bar on iPhone Duo (see
/// [GlassNavBar.railSideOf]), which holds the status items and the tab
/// rail. Elsewhere it adds nothing.
class SideBarSafeArea extends StatelessWidget {
  final Widget child;

  const SideBarSafeArea({super.key, required this.child});

  @override
  Widget build(BuildContext ctx) {
    final side = GlassNavBar.railSideOf(ctx);
    if (side == null) return child;
    // The bar shows the page's background, not the shell's.
    return ColoredBox(
      color: Theme.of(ctx).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        bottom: false,
        left: side == TextDirection.ltr,
        right: side == TextDirection.rtl,
        child: child,
      ),
    );
  }
}

/// [GlassNavBar] as a vertical glass capsule in the system's side bar on
/// iPhone Duo, at the opposite end from the status items and the camera,
/// like the system's own tab rail. Its selection pill can be tapped or dragged
/// between tabs.
class _GlassNavRail extends StatelessWidget {
  /// The bar's side: [TextDirection.rtl] for the right, else the left.
  final TextDirection side;
  final double bottomGap;

  /// Whether the window is short, as on the folded screen turned sideways.
  final bool compact;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  const _GlassNavRail({
    required this.side,
    required this.bottomGap,
    required this.compact,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  /// Rail width: a navigation icon in a 44pt touch target plus its pill
  /// inset; it fits the 84pt side bar with room either side.
  static const _width = 56.0;

  /// Height of one tab: a 44pt touch target plus room for the pill.
  static const _itemExtent = 52.0;

  /// Space between the selection pill and the rail's edge.
  static const _pillInset = AppSpacing.xxs;

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final mq = MediaQuery.of(ctx);
    final barWidth = side == TextDirection.rtl
        ? mq.padding.right
        : mq.padding.left;
    // Keep below the status items at the top of the side bar; the rail
    // shrinks its tabs before it would reach them.
    final maxHeight = mq.size.height * 0.6;
    final extent = math.min(
      _itemExtent,
      (maxHeight - _pillInset * 2) / items.length,
    );
    final height = extent * items.length + _pillInset * 2;
    final rail = SizedBox(
      width: _width,
      height: height,
      // The package's refracting, morphing selection pill is horizontal.
      // Rotate its layout, then turn each icon back upright. LTR keeps
      // the tab order top-to-bottom in every locale.
      child: MediaQuery.removePadding(
        context: ctx,
        removeLeft: true,
        removeTop: true,
        removeRight: true,
        removeBottom: true,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RotatedBox(
            quarterTurns: 1,
            child: LiquidGlassTabBar(
              items: [
                for (final (i, item) in items.indexed)
                  LiquidGlassTabBarItem(
                    iconBuilder: (_, glyph) => RotatedBox(
                      quarterTurns: -1,
                      child: Semantics(
                        button: true,
                        selected: i == currentIndex,
                        label: item.label,
                        onTap: () => onTap(i),
                        excludeSemantics: true,
                        child: Icon(
                          glyph.selected ? item.activeIcon : item.icon,
                          size: glyph.size,
                          color: glyph.color,
                        ),
                      ),
                    ),
                  ),
              ],
              selectedIndex: currentIndex,
              onChanged: onTap,
              width: height,
              height: _width,
              margin: EdgeInsets.zero,
              itemPadding: _pillInset,
              alignment: Alignment.center,
              style: LiquidGlassTabBar.defaultStyle.copyWith(
                color: glassTintOf(ctx),
              ),
              itemStyle: LiquidGlassTabItemStyle(
                selectedColor: AppColors.accentOf(ctx),
                unselectedColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.62,
                ),
                iconSize: AppControlSizes.navigationIcon,
              ),
            ),
          ),
        ),
      ),
    );
    // Centered in the side bar, at its bottom like the tab bar it replaces,
    // unless the camera is there. On the folded screen the cutout sits at
    // the top of the bar in portrait, so turned sideways with the bar on
    // the right it ends up at the bottom. The unfolded screen keeps the
    // status items and camera at the top of the bar either way, and is
    // never short. iOS doesn't report the cutout, so this follows from
    // where the bar is and the window's height.
    final cameraBelow = side == TextDirection.rtl && compact;
    return Positioned(
      top: cameraBelow ? bottomGap : null,
      bottom: cameraBelow ? null : bottomGap,
      left: side == TextDirection.ltr ? 0 : null,
      right: side == TextDirection.rtl ? 0 : null,
      width: barWidth,
      child: Center(child: rail),
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

  /// Buttons at the trailing end: round glass on Apple, icon buttons
  /// elsewhere.
  final List<GlassTopBarAction> actions;

  const GlassTopBar({super.key, required this.title, this.actions = const []});

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
        actions: [for (final action in actions) action._materialButton()],
      );
    }
    if (!PlatformCapabilities.isApple) {
      return AppBar(
        title: Text(title),
        backgroundColor: AppColors.accentOf(ctx),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [for (final action in actions) action._materialButton()],
      );
    }

    final canPop = ModalRoute.of(ctx)?.impliesAppBarDismissal ?? false;
    const buttonSlot = AppControlSizes.toolbarButton + AppSpacing.xs;
    final leadingWidth = windowControlsInset + (canPop ? buttonSlot : 0);
    final trailingWidth = actions.length * buttonSlot;
    // Reserve the same space on both sides to keep the title centered and
    // clear of the back button, the actions and macOS traffic lights,
    // including in RTL.
    final titleInset =
        AppSpacing.md +
        (leadingWidth > trailingWidth ? leadingWidth : trailingWidth);
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
          if (actions.isNotEmpty)
            SafeArea(
              bottom: false,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (i, action) in actions.indexed) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.xs),
                        Semantics(
                          button: true,
                          label: action.tooltip,
                          enabled: action.onPressed != null,
                          child: IgnorePointer(
                            ignoring: action.onPressed == null,
                            child: GlassIconButton(
                              icon: action.icon,
                              onPressed: action.onPressed ?? () {},
                              color: action.onPressed == null
                                  ? theme.colorScheme.onSurface.withValues(
                                      alpha: 0.38,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A [GlassTopBar] button.
class GlassTopBarAction {
  final IconData icon;

  /// What the button does, read out by screen readers.
  final String tooltip;

  /// Null disables the button.
  final VoidCallback? onPressed;

  const GlassTopBarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  Widget _materialButton() =>
      IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPressed);
}

/// A content card: lite Liquid Glass on iOS and macOS, a Material [Card]
/// elsewhere. Lite glass, not a lens, because cards scroll with their list.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;

  /// Makes the whole card a press target: a highlight on Apple, ink
  /// elsewhere.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GlassCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.onLongPress,
  });

  bool get _pressable => onTap != null || onLongPress != null;

  @override
  Widget build(BuildContext ctx) {
    if (PlatformDesign.usesExpressive) {
      return Padding(
        padding: margin,
        child: M3ECard(
          variant: M3ECardVariant.filled,
          padding: EdgeInsets.zero,
          expanded: true,
          onPressed: onTap,
          onLongPress: onLongPress,
          child: child,
        ),
      );
    }
    if (!PlatformCapabilities.isApple) {
      return Card(
        margin: margin,
        clipBehavior: Clip.antiAlias,
        child: _pressable
            ? InkWell(onTap: onTap, onLongPress: onLongPress, child: child)
            : child,
      );
    }
    return Padding(
      padding: margin,
      child: Material(
        color: Colors.transparent,
        child: LiquidGlassLite(
          shape: const LiquidGlassShape.continuousRoundedRectangle(
            cornerRadius: AppRadii.lg,
          ),
          blur: 10,
          color: glassCardTintOf(ctx),
          // The glass doesn't clip its child on every renderer; keep ink
          // splashes inside the continuous corners.
          child: ClipRSuperellipse(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: _pressable
                ? GlassPressable(
                    onTap: onTap,
                    onLongPress: onLongPress,
                    child: child,
                  )
                : child,
          ),
        ),
      ),
    );
  }
}

/// How a floating glass button answers a finger: it swells under a press,
/// stretches after a drag and springs back on release. Rigid when the system
/// asks for reduced motion.
LiquidGlassTouch? glassButtonTouchOf(BuildContext ctx) =>
    MediaQuery.of(ctx).disableAnimations
    ? null
    : const LiquidGlassTouch.flexing(LiquidGlassFlex());

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
      touch: glassButtonTouchOf(ctx),
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
