import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/theme/app_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import '../asmaul_husna/asmaul_husna_screen.dart';
import '../duas/duas_screen.dart';
import '../dzikir/dzikir.dart';
import '../dzikir/dzikir_screen.dart';
import '../qibla/widgets/qibla_card.dart';

/// Worship tab: Qibla, dzikir (morning and evening, and after prayer), daily
/// duas and the Asmaul Husna.
class WorshipScreen extends StatelessWidget {
  const WorshipScreen({super.key, this.isActive = true});

  final bool isActive;

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: l10n.worship),
      body: Center(
        child: ConstrainedBox(
          // Keep the card readable on wide desktop windows.
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            children: [
              QiblaCard(feedbackEnabled: isActive),
              const _DzikirEntry(),
              _WorshipEntry(
                icon: Icons.mosque,
                title: l10n.afterPrayerDzikir,
                subtitle: l10n.afterPrayerDzikirSubtitle,
                builder: (_) => const DzikirScreen.afterPrayer(),
              ),
              _WorshipEntry(
                icon: Icons.menu_book_outlined,
                title: l10n.duas,
                subtitle: l10n.duasSubtitle,
                builder: (_) => const DuasScreen(),
              ),
              _WorshipEntry(
                icon: Icons.auto_awesome_outlined,
                title: l10n.asmaulHusna,
                subtitle: l10n.asmaulHusnaSubtitle,
                builder: (_) => const AsmaulHusnaScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DzikirEntry extends ConsumerWidget {
  const _DzikirEntry();

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final languageCode = Localizations.localeOf(ctx).languageCode;
    final collection = ref.watch(selectedDzikirCollectionProvider).value;
    return _WorshipEntry(
      icon: Icons.wb_twilight,
      title: AppLocalizations.of(ctx).dzikir,
      subtitle: collection?.nameFor(languageCode),
      builder: (_) => const DzikirScreen(),
    );
  }
}

/// A card that opens one of the Worship tab's screens.
class _WorshipEntry extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final WidgetBuilder builder;

  const _WorshipEntry({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.builder,
  });

  @override
  Widget build(BuildContext ctx) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: PlatformListTile(
        leading: Icon(icon, color: AppColors.accentOf(ctx)),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.of(ctx).push(MaterialPageRoute<void>(builder: builder)),
      ),
    );
  }
}
