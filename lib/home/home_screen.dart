import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/adaptive_scaffold.dart';
import '../core/design/platform_capabilities.dart';
import '../features/prayer_times/prayer_times_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/worship/worship_screen.dart';
import '../generated/l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _idx = 0;

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
        icon:
            PlatformCapabilities.isApple ? 'moon.stars' : Icons.mosque_outlined,
        selectedIcon:
            PlatformCapabilities.isApple ? 'moon.stars.fill' : Icons.mosque,
        label: l10n.worship,
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
      child: IndexedStack(index: _idx, children: [
        const PrayerTimesScreen(),
        WorshipScreen(isActive: _idx == 1),
        const SettingsScreen(),
      ]),
    );
  }
}
