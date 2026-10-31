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

/// Glass tint for bars and controls that float over content: a veil when
/// Clear, milky (light) or solid grey (dark) when Tinted. Even Clear dims
/// the page behind enough, like the system's glass, that labels on the glass
/// stay readable over text.
Color glassTintOf(BuildContext ctx) => _adaptiveTint(
  ctx,
  light: Colors.white,
  dark: _tintedDarkGlass,
  lightAlpha: 0.3,
  darkAlpha: 0.4,
  lightOpaqueAlpha: 0.85,
  darkOpaqueAlpha: 0.85,
);

/// The neutral grey of the system's Tinted glass in dark mode, a fifth of
/// the way from black to white, so Tinted bars read as grey, not black.
final _tintedDarkGlass = Color.lerp(Colors.black, Colors.white, 0.22)!;

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

/// The tab bar's glass, like the system's: the page stays sharp (no blur)
/// and bends hard along the rim, and the system's Clear/Tinted style only
/// moves the tint ([glassTintOf]).
LiquidGlassStyle _navBarStyleOf(BuildContext ctx) =>
    LiquidGlassTabBar.defaultStyle.copyWith(
      color: glassTintOf(ctx),
      blur: 0,
      refractionIndex: 1.3,
      // About a third of the bar's height, so the rim bends the page like
      // system glass while the icons and labels sit over undistorted glass.
      refractionWidth: 20,
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
    final barHeight = heightOf(ctx);
    final center = Offset(
      mq.size.width / 2,
      mq.size.height - bottomGap - barHeight / 2,
    );
    // The tab bar adds the bottom safe-area inset to its margin; drop the
    // inset so the gap is measured from the screen edge.
    return _withNavBackdrop(ctx, (backdrop) {
      final colors = _navTabColorsOf(ctx, backdrop, center);
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
                    // Semibold, like the system tab bar, so labels hold up
                    // over the page seen through clear glass.
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: l.textStyle.color,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            selectedIndex: visualIndex(currentIndex),
            onChanged: (index) => onTap(visualIndex(index)),
            width: width,
            height: barHeight,
            margin: EdgeInsets.only(bottom: bottomGap),
            style: _navBarStyleOf(ctx),
            itemStyle: LiquidGlassTabItemStyle(
              selectedColor: colors.selected,
              unselectedColor: colors.unselected,
              iconSize: compact
                  ? AppControlSizes.toolbarIcon
                  : AppControlSizes.navigationIcon,
              labelFontSize: theme.textTheme.labelSmall!.fontSize!,
            ),
            pillStyle: LiquidGlassTabPillStyle(color: colors.pill),
          ),
        ),
      );
    });
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
    // Matches the placement below.
    final cameraBelow = side == TextDirection.rtl && compact;
    final center = Offset(
      side == TextDirection.rtl ? mq.size.width - barWidth / 2 : barWidth / 2,
      cameraBelow
          ? bottomGap + height / 2
          : mq.size.height - bottomGap - height / 2,
    );
    Widget railFor(_NavTabColors colors) => SizedBox(
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
              style: _navBarStyleOf(ctx),
              itemStyle: LiquidGlassTabItemStyle(
                selectedColor: colors.selected,
                unselectedColor: colors.unselected,
                iconSize: AppControlSizes.navigationIcon,
              ),
              pillStyle: LiquidGlassTabPillStyle(color: colors.pill),
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
    return Positioned(
      top: cameraBelow ? bottomGap : null,
      bottom: cameraBelow ? null : bottomGap,
      left: side == TextDirection.ltr ? 0 : null,
      right: side == TextDirection.rtl ? 0 : null,
      width: barWidth,
      child: Center(
        child: _withNavBackdrop(
          ctx,
          (backdrop) => railFor(_navTabColorsOf(ctx, backdrop, center)),
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

/// A colored area of the page, such as the accent hero, that may sit under
/// the floating [GlassNavBar], in the [GlassNavBackdropScope]'s coordinates.
@immutable
class GlassNavBackdrop {
  final Rect rect;
  final Color color;

  const GlassNavBackdrop({required this.rect, required this.color});

  @override
  bool operator ==(Object other) =>
      other is GlassNavBackdrop && other.rect == rect && other.color == color;

  @override
  int get hashCode => Object.hash(rect, color);
}

/// Lets a page under the floating [GlassNavBar] report its colored
/// backdrops ([GlassNavBackdropRegion], such as the hero and the
/// highlighted card), so the bar's tabs turn light over a dark one and back
/// to the text color over the page. Wrap the [Stack] that holds the page
/// and the bar.
class GlassNavBackdropScope extends StatefulWidget {
  final Widget child;

  const GlassNavBackdropScope({super.key, required this.child});

  static _GlassNavBackdropInherited? _of(BuildContext ctx) =>
      ctx.getInheritedWidgetOfExactType<_GlassNavBackdropInherited>();

  @override
  State<GlassNavBackdropScope> createState() => _GlassNavBackdropScopeState();
}

class _GlassNavBackdropScopeState extends State<GlassNavBackdropScope> {
  final _backdrops = ValueNotifier<Map<Object, GlassNavBackdrop>>(const {});

  @override
  void dispose() {
    _backdrops.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => _GlassNavBackdropInherited(
    backdrops: _backdrops,
    scope: ctx,
    child: widget.child,
  );
}

class _GlassNavBackdropInherited extends InheritedWidget {
  /// Each active region's backdrop, keyed by the region.
  final ValueNotifier<Map<Object, GlassNavBackdrop>> backdrops;

  /// The scope's context, whose box the backdrop rect is measured in.
  final BuildContext scope;

  const _GlassNavBackdropInherited({
    required this.backdrops,
    required this.scope,
    required super.child,
  });

  @override
  bool updateShouldNotify(_GlassNavBackdropInherited old) =>
      old.backdrops != backdrops;
}

/// Reports [child]'s area as a [color] backdrop to the enclosing
/// [GlassNavBackdropScope] while [active], measured after each build and
/// as the enclosing scrollable scrolls.
class GlassNavBackdropRegion extends StatefulWidget {
  final Color color;
  final bool active;
  final Widget child;

  const GlassNavBackdropRegion({
    super.key,
    required this.color,
    required this.active,
    required this.child,
  });

  @override
  State<GlassNavBackdropRegion> createState() => _GlassNavBackdropRegionState();
}

class _GlassNavBackdropRegionState extends State<GlassNavBackdropRegion> {
  ValueNotifier<Map<Object, GlassNavBackdrop>>? _reported;
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A list item isn't rebuilt as it scrolls, so it measures again on
    // every scroll.
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_onScroll);
      _position = position?..addListener(_onScroll);
    }
  }

  /// Measures after the frame, once the scroll has moved the layout.
  void _onScroll() {
    if (!widget.active && _reported == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
  }

  void _clear() {
    final reported = _reported;
    if (reported == null || !reported.value.containsKey(this)) return;
    reported.value = Map.of(reported.value)..remove(this);
  }

  void _report() {
    if (!mounted) return;
    final scope = GlassNavBackdropScope._of(context);
    if (scope == null) return;
    final box = context.findRenderObject() as RenderBox?;
    final scopeBox = scope.scope.findRenderObject() as RenderBox?;
    if (!widget.active ||
        box == null ||
        scopeBox == null ||
        !box.hasSize ||
        !box.attached) {
      _clear();
      return;
    }
    final origin = box.localToGlobal(Offset.zero, ancestor: scopeBox);
    final backdrop = GlassNavBackdrop(
      rect: origin & box.size,
      color: widget.color,
    );
    final backdrops = scope.backdrops;
    if (backdrops.value[this] == backdrop) return;
    _reported = backdrops;
    backdrops.value = {...backdrops.value, this: backdrop};
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    // Cleared after the frame: listeners may not rebuild during unmount.
    if (_reported != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _clear();
        } on FlutterError {
          // The scope went away too.
        }
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
    return widget.child;
  }
}

typedef _NavTabColors = ({Color selected, Color unselected, Color pill});

/// The selected and unselected tab colors and the selection pill's fill of
/// a [GlassNavBar] whose center is at [center] in the
/// [GlassNavBackdropScope]: white over any dark backdrop, unless the glass is
/// tinted enough to turn light (the system's Tinted style), else the
/// accent, the text color and the package's grey pill. Unselected tabs stay
/// at full strength, like the system's, so they read over the page seen
/// through the glass; the pill marks the selection.
_NavTabColors _navTabColorsOf(
  BuildContext ctx,
  Iterable<GlassNavBackdrop> backdrops,
  Offset center,
) {
  final overDark = backdrops.any(
    (backdrop) =>
        backdrop.rect.contains(center) &&
        ThemeData.estimateBrightnessForColor(
              Color.alphaBlend(glassTintOf(ctx), backdrop.color),
            ) ==
            Brightness.dark,
  );
  if (overDark) {
    return (
      selected: Colors.white,
      unselected: Colors.white,
      // The package's own pill fill for a bar over a dark page.
      pill: LiquidGlassTabPillStyle.defaultRestAdaptivity.glassColorOnDark,
    );
  }
  return (
    selected: _navSelectedAccentOf(ctx),
    unselected: Theme.of(ctx).colorScheme.onSurface,
    pill: const LiquidGlassTabPillStyle().color,
  );
}

/// The selected tab's accent, moved away from the glass's brightness (a
/// little over a third of the way to white in dark mode, a fifth to black in
/// light) so it stands out from the grey pill and the page seen through the
/// glass.
Color _navSelectedAccentOf(BuildContext ctx) {
  final accent = AppColors.accentOf(ctx);
  return Theme.of(ctx).brightness == Brightness.dark
      ? Color.lerp(accent, Colors.white, 0.35)!
      : Color.lerp(accent, Colors.black, 0.2)!;
}

/// Rebuilds [builder] with the scope's backdrops, or none without a scope.
Widget _withNavBackdrop(
  BuildContext ctx,
  Widget Function(Iterable<GlassNavBackdrop> backdrops) builder,
) {
  final scope = GlassNavBackdropScope._of(ctx);
  if (scope == null) return builder(const []);
  return ValueListenableBuilder<Map<Object, GlassNavBackdrop>>(
    valueListenable: scope.backdrops,
    builder: (_, backdrops, _) => builder(backdrops.values),
  );
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
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.onSurface,
    );
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
            child: LayoutBuilder(
              builder: (ctx, box) => Padding(
                padding: _titlePadding(
                  ctx,
                  title,
                  box.maxWidth,
                  style: titleStyle,
                  leadingWidth: leadingWidth,
                  trailingWidth: trailingWidth,
                ),
                child: Center(
                  child: SizedBox(
                    height: _capsuleHeight,
                    child: LiquidGlassLens(
                      style: LiquidGlassStyle(
                        shape:
                            const LiquidGlassShape.continuousRoundedRectangle(
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
                            style: titleStyle,
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

/// Where [GlassTopBar]'s title capsule goes in a bar [width] wide: centered
/// when the title fits between equal margins, as on iOS, otherwise in the
/// room left between the back button and the actions, so a bar with several
/// actions doesn't cut its title short. Either way it stays clear of the
/// back button, the actions and the macOS traffic lights, also in RTL.
EdgeInsetsGeometry _titlePadding(
  BuildContext ctx,
  String title,
  double width, {
  required TextStyle? style,
  required double leadingWidth,
  required double trailingWidth,
}) {
  final painter = TextPainter(
    text: TextSpan(text: title, style: style),
    maxLines: 1,
    textDirection: Directionality.of(ctx),
    textScaler: MediaQuery.textScalerOf(ctx),
  )..layout();
  final capsule = painter.width + 2 * AppSpacing.md;
  painter.dispose();
  final side = math.max(leadingWidth, trailingWidth);
  if (capsule <= width - 2 * (AppSpacing.md + side)) {
    return EdgeInsets.symmetric(horizontal: AppSpacing.md + side);
  }
  final start = AppSpacing.md + leadingWidth;
  final end = AppSpacing.md + trailingWidth;
  final rtl = Directionality.of(ctx) == TextDirection.rtl;
  // The macOS traffic lights stay on the left in RTL too.
  final lights = AppSpacing.md + windowControlsInset;
  return EdgeInsets.only(
    left: math.max(rtl ? end : start, lights),
    right: rtl ? start : end,
  );
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
