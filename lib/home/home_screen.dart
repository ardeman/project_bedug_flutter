import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/adaptive_scaffold.dart';
import '../core/design/platform_capabilities.dart';
import '../features/hijri_calendar/hijri_calendar_screen.dart';
import '../features/prayer_times/prayer_times_screen.dart';
import '../features/settings/settings_screen.dart';
import '../generated/l10n/app_localizations.dart';

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

    final destinations = [
      AdaptiveNavigationDestination(
        icon:
            PlatformCapabilities.isApple ? 'clock' : Icons.access_time_outlined,
        selectedIcon: PlatformCapabilities.isApple
            ? 'clock.fill'
            : Icons.access_time_filled,
        label: l10n.prayerTimes,
      ),
      AdaptiveNavigationDestination(
        icon: PlatformCapabilities.isApple
            ? 'calendar'
            : Icons.calendar_month_outlined,
        selectedIcon: PlatformCapabilities.isApple
            ? 'calendar.circle.fill'
            : Icons.calendar_month,
        label: l10n.hijriCalendar,
      ),
      AdaptiveNavigationDestination(
        icon: PlatformCapabilities.isApple
            ? 'gearshape'
            : Icons.settings_outlined,
        selectedIcon:
            PlatformCapabilities.isApple ? 'gearshape.fill' : Icons.settings,
        label: l10n.settings,
      ),
    ];

    return AdaptiveScaffold(
      title: l10n.appName,
      selectedIndex: _idx,
      onDestinationSelected: (index) => setState(() => _idx = index),
      destinations: destinations,
      showAppBar: false,
      child: IndexedStack(index: _idx, children: _screens),
    );
  }
}
