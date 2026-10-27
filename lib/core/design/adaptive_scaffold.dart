import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import 'liquid_glass.dart';
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

/// Scaffold adaptive with API destination-driven, example: iOS26 scaffold.
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
    final mq = MediaQuery.of(ctx);
    final navItems = destinations
        .map(
          (d) => GlassNavItem(
            icon: _materialIconFor(d.icon),
            activeIcon: _materialIconFor(d.selectedIcon ?? d.icon),
            label: d.label,
          ),
        )
        .toList(growable: false);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFF2F2F7),
      // Tabs bring their own glass top bar; [appBarActions] and [leading]
      // are Material-only.
      appBar: showAppBar ? GlassTopBar(title: title) : null,
      // The glass bar floats over the page so content refracts through it.
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Lists end clear of the floating bar.
          MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(
                bottom: GlassNavBar.occupiedHeight(ctx),
              ),
            ),
            child: child,
          ),
          GlassNavBar(
            currentIndex: selectedIndex,
            onTap: onDestinationSelected,
            items: navItems,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterial(BuildContext ctx) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(title: Text(title), actions: appBarActions, leading: leading)
          : null,
      body: child,
      bottomNavigationBar: PlatformDesign.usesExpressive
          ? M3ENavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              // Side-by-side icon and label items need room for the longest
              // label (such as "Waktu Salat") and its padding; the package's
              // fixed 600 breakpoint overflows with four tabs.
              wideBreakpoint: destinations.length * _wideDestinationWidth,
              destinations: [
                for (final d in destinations)
                  M3ENavigationBarDestination(
                    icon: Icon(_materialIconFor(d.icon)),
                    selectedIcon: Icon(
                      _materialIconFor(d.selectedIcon ?? d.icon),
                    ),
                    label: d.label,
                  ),
              ],
            )
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations
                  .map(
                    (d) => NavigationDestination(
                      icon: Icon(_materialIconFor(d.icon)),
                      selectedIcon: Icon(
                        _materialIconFor(d.selectedIcon ?? d.icon),
                      ),
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
      backgroundColor: isDark
          ? const Color(0xFF202020)
          : const Color(0xFFF3F3F3),
      appBar: showAppBar
          ? AppBar(
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
                    selectedIcon: Icon(
                      _materialIconFor(d.selectedIcon ?? d.icon),
                    ),
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

  /// Room each horizontal Expressive nav item needs: its icon, label and
  /// indicator padding.
  static const _wideDestinationWidth = 220.0;

  IconData _materialIconFor(Object icon) {
    if (icon is IconData) return icon;
    if (icon is String) {
      return SFSymbols.materialFallback(icon);
    }
    return Icons.circle;
  }
}
