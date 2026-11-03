import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/adaptive_scaffold.dart';
import '../core/design/platform_capabilities.dart';
import '../core/design/liquid_glass.dart';
import '../features/prayer_times/prayer_times_screen.dart';
import '../features/quran/quran_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tour/app_tour_provider.dart';
import '../features/tour/app_tour_screen.dart';
import '../features/tour/tour_targets.dart';
import '../features/worship/worship_screen.dart';
import '../generated/l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _idx = 0;
  final _anchors = TourAnchors();

  @override
  void dispose() {
    _anchors.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final step = ref.watch(appTourControllerProvider);
    final tour = ref.read(appTourControllerProvider.notifier);
    final index = step == null ? _idx : tourStops[step].tab;
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

    final scaffold = AdaptiveScaffold(
      navigationKey: _anchors.keys[TourControl.navigation],
      title: l10n.appName,
      selectedIndex: index,
      onDestinationSelected: (index) => setState(() => _idx = index),
      destinations: destinations,
      showAppBar: false,
      child: IndexedStack(
        index: index,
        children: [
          // Its header runs under the side bar; its cards keep clear.
          const PrayerTimesScreen(),
          SideBarSafeArea(child: WorshipScreen(isActive: index == 1)),
          const SideBarSafeArea(child: QuranScreen()),
          const SideBarSafeArea(child: SettingsScreen()),
        ],
      ),
    );
    return TourAnchorScope(
      anchors: _anchors,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            excluding: step != null,
            child: AbsorbPointer(absorbing: step != null, child: scaffold),
          ),
          if (step != null)
            AppTourOverlay(
              step: step,
              anchors: _anchors,
              onNext: tour.next,
              onBack: tour.back,
              onFinish: () async {
                setState(() => _idx = 0);
                await tour.finish();
              },
            ),
        ],
      ),
    );
  }
}
