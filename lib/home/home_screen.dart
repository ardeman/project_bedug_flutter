import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/adaptive_scaffold.dart';
import '../core/design/platform_capabilities.dart';
import '../core/design/liquid_glass.dart';
import '../features/prayer_times/prayer_times_screen.dart';
import '../features/quran/quran_screen.dart';
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
        icon: PlatformCapabilities.isApple
            ? 'clock'
            : Icons.access_time_outlined,
        selectedIcon: PlatformCapabilities.isApple
            ? 'clock.fill'
            : Icons.access_time_filled,
        label: l10n.prayerTimes,
      ),
      AdaptiveNavigationDestination(
        icon: PlatformCapabilities.isApple
            ? 'moon.stars'
            : Icons.mosque_outlined,
        selectedIcon: PlatformCapabilities.isApple
            ? 'moon.stars.fill'
            : Icons.mosque,
        label: l10n.worship,
      ),
      AdaptiveNavigationDestination(
        icon: PlatformCapabilities.isApple ? 'book' : Icons.menu_book_outlined,
        selectedIcon: PlatformCapabilities.isApple
            ? 'book.fill'
            : Icons.menu_book,
        label: l10n.quran,
      ),
      AdaptiveNavigationDestination(
        icon: PlatformCapabilities.isApple
            ? 'gearshape'
            : Icons.settings_outlined,
        selectedIcon: PlatformCapabilities.isApple
            ? 'gearshape.fill'
            : Icons.settings,
        label: l10n.settings,
      ),
    ];

    return AdaptiveScaffold(
      title: l10n.appName,
      selectedIndex: _idx,
      onDestinationSelected: (index) => setState(() => _idx = index),
      destinations: destinations,
      showAppBar: false,
      child: IndexedStack(
        index: _idx,
        children: [
          // Its header runs under the side bar; its cards keep clear.
          const PrayerTimesScreen(),
          SideBarSafeArea(child: WorshipScreen(isActive: _idx == 1)),
          const SideBarSafeArea(child: QuranScreen()),
          const SideBarSafeArea(child: SettingsScreen()),
        ],
      ),
    );
  }
}
