import 'package:flutter/material.dart';
import 'package:cupertino_native/cupertino_native.dart';

import 'liquid_glass.dart';
import 'platform_capabilities.dart';
import 'platform_design.dart';
import 'sf_symbols.dart';

class AdaptiveNavigationDestination {
  final Object icon;
  final Object? selectedIcon;
  final String label;
  final bool isSearch;

  const AdaptiveNavigationDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.isSearch = false,
  });
}

/// Scaffold adaptive dengan API destination-driven seperti contoh iOS26 scaffold.
class AdaptiveScaffold extends StatelessWidget {
  final String title;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AdaptiveNavigationDestination> destinations;
  final Widget child;
  final List<Widget>? appBarActions;
  final Widget? leading;
  final bool showAppBar;

  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.child,
    this.appBarActions,
    this.leading,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext ctx) {
    return switch (PlatformDesign.current) {
      DesignSystem.liquidGlass => _buildApple(ctx),
      DesignSystem.fluentDesign => _buildFluent(ctx),
      DesignSystem.materialYou => _buildMaterial(ctx),
    };
  }

  Widget _buildApple(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final nativeItems = destinations
        .map(
          (d) => CNTabBarItem(
            label: d.label,
            icon: CNSymbol(_symbolNameFor(d.selectedIcon ?? d.icon)),
          ),
        )
        .toList(growable: false);
    final navItems = destinations
        .map(
          (d) => LiquidGlassNavItem(
            icon: d.icon,
            activeIcon: d.selectedIcon ?? d.icon,
            label: d.label,
          ),
        )
        .toList(growable: false);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor:
          isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: showAppBar
          ? LiquidGlassAppBar(
              title: title,
              actions: appBarActions,
              leading: leading,
            )
          : null,
      body: child,
      bottomNavigationBar: PlatformCapabilities.isIOS
          ? CNTabBar(
              currentIndex: selectedIndex,
              onTap: onDestinationSelected,
              items: nativeItems,
            )
          : LiquidGlassNavBar(
              currentIndex: selectedIndex,
              onTap: onDestinationSelected,
              items: navItems,
            ),
    );
  }

  Widget _buildMaterial(BuildContext ctx) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              actions: appBarActions,
              leading: leading,
            )
          : null,
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(_materialIconFor(d.icon)),
                selectedIcon: Icon(_materialIconFor(d.selectedIcon ?? d.icon)),
                label: d.label,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildFluent(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF202020) : const Color(0xFFF3F3F3),
      appBar: showAppBar
          ? AppBar(
              title: Text(
                title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              elevation: 0,
              backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              actions: appBarActions,
              leading: leading,
            )
          : null,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            labelType: NavigationRailLabelType.all,
            destinations: destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(_materialIconFor(d.icon)),
                    selectedIcon:
                        Icon(_materialIconFor(d.selectedIcon ?? d.icon)),
                    label: Text(d.label),
                  ),
                )
                .toList(growable: false),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  String _symbolNameFor(Object icon) {
    if (icon is String) return icon;
    if (icon is IconData) {
      if (icon == Icons.access_time_outlined ||
          icon == Icons.access_time_filled) {
        return 'clock.fill';
      }
      if (icon == Icons.calendar_month_outlined ||
          icon == Icons.calendar_month) {
        return 'calendar.circle.fill';
      }
      if (icon == Icons.settings_outlined || icon == Icons.settings) {
        return 'gearshape.fill';
      }
      if (icon == Icons.search) return 'magnifyingglass';
    }
    return 'circle.fill';
  }

  IconData _materialIconFor(Object icon) {
    if (icon is IconData) return icon;
    if (icon is String) {
      return SFSymbols.materialFallback(icon);
    }
    return Icons.circle;
  }
}
