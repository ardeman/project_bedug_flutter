import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/theme/app_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import '../dzikir/dzikir.dart';
import '../dzikir/dzikir_screen.dart';
import '../qibla/widgets/qibla_card.dart';

/// Worship tab: Qibla and morning and evening dzikir, and later duas.
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
    final l10n = AppLocalizations.of(ctx);
    final languageCode = Localizations.localeOf(ctx).languageCode;
    final collection = ref.watch(selectedDzikirCollectionProvider).value;

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: PlatformListTile(
        leading: Icon(Icons.wb_twilight, color: AppColors.accentOf(ctx)),
        title: Text(l10n.dzikirMorningEvening),
        subtitle: collection == null
            ? null
            : Text(collection.nameFor(languageCode)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(
          ctx,
        ).push(MaterialPageRoute<void>(builder: (_) => const DzikirScreen())),
      ),
    );
  }
}
