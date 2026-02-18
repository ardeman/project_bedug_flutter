import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Liquid Glass effect widget — Apple only
/// Simulasi efek kaca cair dari iOS 26 / macOS 26
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
                tintColor.withOpacity(tintOpacity + 0.05),
                tintColor.withOpacity(tintOpacity - 0.05),
              ],
            ),
            border: border ?? Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 32,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.6),
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

/// Liquid Glass — varian gelap (untuk dark mode)
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

/// App Bar dengan Liquid Glass
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
    final isDark = MediaQuery.of(ctx).platformBrightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: preferredSize.height + MediaQuery.of(ctx).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(ctx).padding.top),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E).withOpacity(0.72)
                : Colors.white.withOpacity(0.72),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
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
            trailing: actions != null ? Row(mainAxisSize: MainAxisSize.min, children: actions!) : null,
            centerMiddle: centerTitle,
          ),
        ),
      ),
    );
  }
}

/// Bottom Navigation Bar dengan Liquid Glass
class LiquidGlassNavBar extends StatelessWidget {
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
  Widget build(BuildContext ctx) {
    final isDark = MediaQuery.of(ctx).platformBrightness == Brightness.dark;
    final bottom = MediaQuery.of(ctx).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 56 + bottom,
          padding: EdgeInsets.only(bottom: bottom),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E).withOpacity(0.72)
                : Colors.white.withOpacity(0.72),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              final item = items[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: selected
                            ? BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              )
                            : null,
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 24,
                          color: selected
                              ? CupertinoColors.activeBlue
                              : (isDark ? Colors.white54 : Colors.black45),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected
                              ? CupertinoColors.activeBlue
                              : (isDark ? Colors.white54 : Colors.black45),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class LiquidGlassNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const LiquidGlassNavItem({required this.icon, required this.activeIcon, required this.label});
}

/// Modal / Bottom Sheet dengan Liquid Glass
class LiquidGlassSheet extends StatelessWidget {
  final Widget child;
  final String? title;

  const LiquidGlassSheet({super.key, required this.child, this.title});

  static Future<T?> show<T>(BuildContext ctx, {required Widget child, String? title}) {
    return showCupertinoModalPopup<T>(
      context: ctx,
      builder: (_) => LiquidGlassSheet(child: child, title: title),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final isDark = MediaQuery.of(ctx).platformBrightness == Brightness.dark;
    final bottom = MediaQuery.of(ctx).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: EdgeInsets.only(bottom: bottom),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E).withOpacity(0.78)
                : Colors.white.withOpacity(0.78),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.2),
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