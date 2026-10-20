import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/theme/app_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import 'changelog.dart';

/// What's new: every release, newest first, read from the changelog the
/// website also builds from.
class ChangelogScreen extends ConsumerWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final l10n = AppLocalizations.of(ctx);
    final changelog = ref.watch(changelogProvider);

    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: l10n.whatsNew),
      body: changelog.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(l10n.changelogLoadError, textAlign: TextAlign.center),
          ),
        ),
        data: (releases) => ListView(
          children: [
            for (final release in releases) _ReleaseCard(release: release),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  final Release release;

  const _ReleaseCard({required this.release});

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final locale = Localizations.localeOf(ctx).languageCode;
    final date = release.date;

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    l10n.version(release.version),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  date == null
                      ? l10n.changelogUnreleased
                      : DateFormat.yMMMMd(locale).format(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            for (final change in release.changes)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: _ChangeRow(change: change, languageCode: locale),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final Change change;
  final String languageCode;

  const _ChangeRow({required this.change, required this.languageCode});

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final (icon, label, color) = switch (change.type) {
      ChangeType.added => (
        Icons.auto_awesome_outlined,
        l10n.changelogNew,
        AppColors.accentOf(ctx),
      ),
      ChangeType.improved => (
        Icons.trending_up,
        l10n.changelogImproved,
        AppColors.secondaryOf(ctx),
      ),
      ChangeType.fixed => (
        Icons.build_outlined,
        l10n.changelogFixed,
        theme.colorScheme.tertiary,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                change.textFor(languageCode),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
