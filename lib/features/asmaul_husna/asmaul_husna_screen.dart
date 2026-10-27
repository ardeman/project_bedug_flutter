import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/theme/app_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import 'asmaul_husna.dart';

/// The 99 names of Allah, numbered, with transliteration and meaning.
class AsmaulHusnaScreen extends ConsumerWidget {
  const AsmaulHusnaScreen({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final l10n = AppLocalizations.of(ctx);
    final asmaulHusna = ref.watch(asmaulHusnaProvider);
    final languageCode = Localizations.localeOf(ctx).languageCode;

    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: l10n.asmaulHusna),
      body: asmaulHusna.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(l10n.asmaulHusnaLoadError, textAlign: TextAlign.center),
          ),
        ),
        data: (asmaulHusna) => Center(
          child: ConstrainedBox(
            // Keep lines readable on wide desktop windows.
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView.builder(
              // No padding here: the list adds the top bar's inset itself.
              // A gap, the names, then the source.
              itemCount: asmaulHusna.names.length + 2,
              itemBuilder: (ctx, i) => i == 0
                  ? const SizedBox(height: AppSpacing.sm)
                  : i <= asmaulHusna.names.length
                  ? _NameCard(
                      number: i,
                      name: asmaulHusna.names[i - 1],
                      languageCode: languageCode,
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      child: Text(
                        l10n.dzikirSource(asmaulHusna.sourceFor(languageCode)),
                        textAlign: TextAlign.center,
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  final int number;
  final DivineName name;
  final String languageCode;

  const _NameCard({
    required this.number,
    required this.name,
    required this.languageCode,
  });

  /// Fits three digits in the number badge.
  static const _badgeSize = 36.0;

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final accent = AppColors.accentOf(ctx);
    final meaning = name.meaningFor(languageCode);

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: _badgeSize,
              height: _badgeSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: meaning == null
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.transliteration,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          meaning,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              name.arabic,
              textDirection: TextDirection.rtl,
              style: theme.textTheme.headlineSmall?.copyWith(color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
