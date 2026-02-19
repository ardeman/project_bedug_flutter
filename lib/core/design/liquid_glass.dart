import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cupertino_native/cupertino_native.dart';
import '../constants/app_colors.dart';
import 'sf_symbols.dart';

/// Liquid Glass effect widget — Apple only
/// Simulation liquid glass effect from iOS 26 / macOS 26
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color tintColor;
  final double tintOpacity;
  final EdgeInsetsGeometry? padding;
  final Border? border;

  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 24,
    this.tintColor = Colors.white,
    this.tintOpacity = 0.15,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext ctx) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          inner: ImageFilter.dilate(radiusX: 0.5, radiusY: 0.5),
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tintColor.withValues(alpha: tintOpacity + 0.05),
                tintColor.withValues(alpha: tintOpacity - 0.05),
              ],
            ),
            border: border ??
                Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 0.8,
                ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 32,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 1,
                spreadRadius: 0,
                offset: const Offset(0, -0.5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Liquid Glass — dark varian
class LiquidGlassDark extends LiquidGlass {
  const LiquidGlassDark({
    super.key,
    required super.child,
    super.borderRadius = 20,
    super.blur = 28,
    super.padding,
  }) : super(
          tintColor: const Color(0xFF1C1C1E),
          tintOpacity: 0.45,
          border: const Border.fromBorderSide(
            BorderSide(color: Color(0x33FFFFFF), width: 0.5),
          ),
        );
}

/// App Bar with Liquid Glass
class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const LiquidGlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: preferredSize.height + MediaQuery.of(ctx).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(ctx).padding.top),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E).withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.72),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: NavigationToolbar(
            leading: leading,
            middle: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            trailing: actions != null
                ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
                : null,
            centerMiddle: centerTitle,
          ),
        ),
      ),
    );
  }
}

/// Bottom Navigation Bar with Liquid Glass
class LiquidGlassNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidGlassNavItem> items;

  const LiquidGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar> {
  int? _draggedToIndex;
  bool _isDraggingNav = false;

  bool get _supportsMacDrag =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  void _onNavDragStart(DragStartDetails _) {
    _draggedToIndex = widget.currentIndex;
    if (_supportsMacDrag) {
      setState(() => _isDraggingNav = true);
    }
  }

  void _onNavDragUpdate(DragUpdateDetails details, double width) {
    if (!_supportsMacDrag || width <= 0) return;
    final slotWidth = width / widget.items.length;
    final rawIndex = (details.localPosition.dx / slotWidth).floor();
    final nextIndex = rawIndex.clamp(0, widget.items.length - 1);

    if (nextIndex != _draggedToIndex && nextIndex != widget.currentIndex) {
      _draggedToIndex = nextIndex;
      widget.onTap(nextIndex);
    }
  }

  void _onNavDragEnd(DragEndDetails _) {
    _draggedToIndex = null;
    if (_supportsMacDrag) {
      setState(() => _isDraggingNav = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final bottom = MediaQuery.of(ctx).padding.bottom;

    final selectedColor = AppColors.emerald;
    final unselectedColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : Colors.black.withValues(alpha: 0.58);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom > 0 ? 8 : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1C1F28).withValues(alpha: 0.82),
                        const Color(0xFF10141B).withValues(alpha: 0.76),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.80),
                        Colors.white.withValues(alpha: 0.68),
                      ],
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.82),
                width: 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                const navPadding = 6.0;
                final slotWidth = constraints.maxWidth / widget.items.length;
                final pillWidth = slotWidth - (navPadding * 2);
                final pillLeft = (widget.currentIndex * slotWidth) + navPadding;

                return MouseRegion(
                  cursor: _supportsMacDrag
                      ? (_isDraggingNav
                          ? SystemMouseCursors.grabbing
                          : SystemMouseCursors.grab)
                      : MouseCursor.defer,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart:
                        _supportsMacDrag ? _onNavDragStart : null,
                    onHorizontalDragUpdate: _supportsMacDrag
                        ? (details) =>
                            _onNavDragUpdate(details, constraints.maxWidth)
                        : null,
                    onHorizontalDragEnd:
                        _supportsMacDrag ? _onNavDragEnd : null,
                    child: Stack(
                    children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: pillLeft,
                      top: navPadding,
                      bottom: navPadding,
                      width: pillWidth,
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.13)
                                    : Colors.white.withValues(alpha: 0.62),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.75),
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                      Row(
                        children: List.generate(widget.items.length, (i) {
                          final selected = i == widget.currentIndex;
                          final item = widget.items[i];
                          return Expanded(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => widget.onTap(i),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.all(navPadding),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        transitionBuilder: (child, anim) =>
                                            FadeTransition(
                                          opacity: anim,
                                          child: ScaleTransition(
                                              scale: anim, child: child),
                                        ),
                                        child: _buildNavIcon(
                                          selected
                                              ? item.activeIcon
                                              : item.icon,
                                          fallback: selected
                                              ? Icons.circle
                                              : Icons.circle_outlined,
                                          key: ValueKey('${selected}_$i'),
                                          size: 22,
                                          color: selected
                                              ? selectedColor
                                              : unselectedColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: selected
                                              ? selectedColor
                                              : unselectedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(
    Object icon, {
    required IconData fallback,
    required Key key,
    required double size,
    required Color color,
  }) {
    if (icon is String && _supportsNativeAppleSymbols) {
      return CNIcon(
        key: key,
        symbol: CNSymbol(
          icon,
          size: size,
          color: color,
          mode: CNSymbolRenderingMode.monochrome,
        ),
      );
    }

    if (icon is String) {
      return Icon(
        SFSymbols.materialFallback(icon),
        key: key,
        size: size,
        color: color,
      );
    }

    return Icon(
      icon is IconData ? icon : fallback,
      key: key,
      size: size,
      color: color,
    );
  }

  bool get _supportsNativeAppleSymbols {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }
}

class LiquidGlassNavItem {
  final Object icon;
  final Object activeIcon;
  final String label;
  const LiquidGlassNavItem(
      {required this.icon, required this.activeIcon, required this.label});
}

/// Modal / Bottom Sheet with Liquid Glass
class LiquidGlassSheet extends StatelessWidget {
  final Widget child;
  final String? title;

  const LiquidGlassSheet({super.key, required this.child, this.title});

  static Future<T?> show<T>(BuildContext ctx,
      {required Widget child, String? title}) {
    return showCupertinoModalPopup<T>(
      context: ctx,
      builder: (_) => LiquidGlassSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final bottom = MediaQuery.of(ctx).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: EdgeInsets.only(bottom: bottom),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E).withValues(alpha: 0.78)
                : Colors.white.withValues(alpha: 0.78),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: 12),
                Text(
                  title!,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Divider(color: isDark ? Colors.white12 : Colors.black12),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
