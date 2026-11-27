import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/design/platform_design.dart';
import '../../core/theme/app_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import '../update/update_channel.dart';
import '../update/update_flow.dart';
import 'changelog.dart';

/// This version's changes, plus check-for-updates when the build has a
/// channel. The full history stays on the website.
class WhatsNewScreen extends ConsumerWidget {
  const WhatsNewScreen({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final l10n = AppLocalizations.of(ctx);
    final changelog = ref.watch(changelogProvider);
    final showUpdates = ref.watch(updateChannelProvider) != UpdateChannel.none;

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
        data: (releases) {
          if (releases.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  l10n.changelogLoadError,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            children: [
              if (showUpdates) ...[
                const _UpdateCheckTile(),
                const _UpdateOnLaunchTile(),
              ],
              _ReleaseCard(release: releases.first),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
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

enum _UpdateCheckStatus { idle, checking, upToDate, updateAvailable, failed }

/// Checks for an update on tap and offers to install it.
class _UpdateCheckTile extends ConsumerStatefulWidget {
  const _UpdateCheckTile();

  @override
  ConsumerState<_UpdateCheckTile> createState() => _UpdateCheckTileState();
}

class _UpdateCheckTileState extends ConsumerState<_UpdateCheckTile> {
  _UpdateCheckStatus _status = _UpdateCheckStatus.idle;
  String? _latestVersion;

  Future<void> _onTap() async {
    if (_status == _UpdateCheckStatus.checking) return;
    setState(() => _status = _UpdateCheckStatus.checking);
    final (outcome, version) = await runUpdateCheck(ref.read, quiet: false);
    if (!mounted) return;
    setState(() {
      _latestVersion = version;
      _status = switch (outcome) {
        UpdateOutcome.upToDate => _UpdateCheckStatus.upToDate,
        UpdateOutcome.available || UpdateOutcome.started =>
          version == null
              ? _UpdateCheckStatus.idle
              : _UpdateCheckStatus.updateAvailable,
        UpdateOutcome.failed => _UpdateCheckStatus.failed,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subtitle = switch (_status) {
      _UpdateCheckStatus.idle => l10n.checkForUpdatesSubtitle,
      _UpdateCheckStatus.checking => l10n.checkingForUpdates,
      _UpdateCheckStatus.upToDate => l10n.upToDate,
      _UpdateCheckStatus.updateAvailable => l10n.updateAvailable(
        _latestVersion!,
      ),
      _UpdateCheckStatus.failed => l10n.updateCheckFailed,
    };

    return PlatformListTile(
      leading: Icon(
        Icons.system_update_alt,
        color: AppColors.accentOf(context),
      ),
      title: Text(l10n.checkForUpdates),
      subtitle: Text(subtitle),
      trailing: _status == _UpdateCheckStatus.checking
          ? const AdaptiveSpinner()
          : const Icon(Icons.chevron_right),
      onTap: _onTap,
    );
  }
}

class _UpdateOnLaunchTile extends ConsumerWidget {
  const _UpdateOnLaunchTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PlatformListTile(
      leading: Icon(Icons.update, color: AppColors.accentOf(context)),
      title: Text(l10n.checkUpdatesOnLaunch),
      subtitle: Text(l10n.checkUpdatesOnLaunchSubtitle),
      trailing: _AdaptiveSwitch(
        value: ref.watch(updateOnLaunchProvider),
        onChanged: ref.read(updateOnLaunchProvider.notifier).set,
      ),
    );
  }
}

class _AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AdaptiveSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext ctx) {
    final accent = AppColors.accentOf(ctx);
    if (PlatformCapabilities.isApple) {
      return LiquidGlassSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: accent,
      );
    }
    if (PlatformDesign.usesExpressive) {
      return M3ESwitch(value: value, onChanged: onChanged);
    }
    return Switch(value: value, activeThumbColor: accent, onChanged: onChanged);
  }
}
