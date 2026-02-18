import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../features/prayer_times/prayer_times_screen.dart';
import '../features/hijri_calendar/hijri_calendar_screen.dart';
import '../features/settings/settings_screen.dart';

// Deteksi Apple platform
bool get _isApple => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _idx = 0;

  static const _screens = [
    PrayerTimesScreen(),
    HijriCalendarScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);

    return Scaffold(
      extendBody: _isApple, // biar body tembus ke belakang nav bar
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: _isApple
          ? _LiquidGlassNavBar(
              currentIndex: _idx,
              onTap: (i) => setState(() => _idx = i),
              l10n: l10n,
            )
          : NavigationBar(
              selectedIndex: _idx,
              onDestinationSelected: (i) => setState(() => _idx = i),
              indicatorColor: AppColors.emerald.withOpacity(.2),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.access_time_outlined),
                  selectedIcon: const Icon(Icons.access_time_filled,
                      color: AppColors.emerald),
                  label: l10n.prayerTimes,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_month_outlined),
                  selectedIcon: const Icon(Icons.calendar_month,
                      color: AppColors.emerald),
                  label: l10n.hijriCalendar,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon:
                      const Icon(Icons.settings, color: AppColors.emerald),
                  label: l10n.settings,
                ),
              ],
            ),
    );
  }
}

// ── Liquid Glass Nav Bar (Apple only) ─────────────────────────────────────────
class _LiquidGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final AppLocalizations l10n;

  const _LiquidGlassNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final bottom = MediaQuery.of(ctx).padding.bottom;

    final items = [
      (Icons.access_time_outlined, Icons.access_time_filled, l10n.prayerTimes),
      (Icons.calendar_month_outlined, Icons.calendar_month, l10n.hijriCalendar),
      (Icons.settings_outlined, Icons.settings, l10n.settings),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 64 + bottom,
          padding: EdgeInsets.only(bottom: bottom),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E).withOpacity(0.72)
                : Colors.white.withOpacity(0.72),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.black.withOpacity(0.08),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              final (icon, activeIcon, label) = items[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 96,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: selected
                            ? BoxDecoration(
                                color: AppColors.emerald.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                              )
                            : null,
                        child: Icon(
                          selected ? activeIcon : icon,
                          size: 22,
                          color: selected
                              ? AppColors.emerald
                              : (isDark ? Colors.white54 : Colors.black38),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected
                              ? AppColors.emerald
                              : (isDark ? Colors.white54 : Colors.black38),
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
