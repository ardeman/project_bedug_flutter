import 'package:flutter/material.dart';
import 'platform_design.dart';
import 'liquid_glass.dart';

/// Scaffold utama yang adaptive per platform
class AdaptiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final List<Widget>? appBarActions;
  final Widget? leading;

  static const _navItems = [
    LiquidGlassNavItem(
      icon: Icons.access_time_outlined,
      activeIcon: Icons.access_time_filled,
      label: 'Sholat',
    ),
    LiquidGlassNavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Kalender',
    ),
    LiquidGlassNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Kiblat',
    ),
    LiquidGlassNavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Setelan',
    ),
  ];

  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentIndex,
    required this.onNavTap,
    this.appBarActions,
    this.leading,
  });

  @override
  Widget build(BuildContext ctx) {
    return switch (PlatformDesign.current) {
      DesignSystem.liquidGlass => _buildApple(ctx),
      DesignSystem.fluentDesign => _buildFluent(ctx),
      DesignSystem.materialYou => _buildMaterial(ctx),
    };
  }

  // ── Apple ────────────────────────────────────────────────────────────────
  Widget _buildApple(BuildContext ctx) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: MediaQuery.of(ctx).platformBrightness == Brightness.dark
          ? const Color(0xFF000000)
          : const Color(0xFFF2F2F7),
      appBar: LiquidGlassAppBar(
        title: title,
        actions: appBarActions,
        leading: leading,
      ),
      body: body,
      bottomNavigationBar: LiquidGlassNavBar(
        currentIndex: currentIndex,
        onTap: onNavTap,
        items: _navItems,
      ),
    );
  }

  // ── Material / Android ───────────────────────────────────────────────────
  Widget _buildMaterial(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: appBarActions,
        leading: leading,
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onNavTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time_filled),
            label: 'Sholat',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Kalender',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Kiblat',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Setelan',
          ),
        ],
      ),
    );
  }

  // ── Fluent / Windows ─────────────────────────────────────────────────────
  Widget _buildFluent(BuildContext ctx) {
    final isDark = MediaQuery.of(ctx).platformBrightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF202020) : const Color(0xFFF3F3F3),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFFFFF),
        actions: appBarActions,
        leading: leading,
      ),
      body: Row(
        children: [
          // Fluent left navigation rail
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onNavTap,
            backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.access_time_outlined),
                selectedIcon: Icon(Icons.access_time_filled),
                label: Text('Sholat'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: Text('Kalender'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: Text('Kiblat'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Setelan'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}