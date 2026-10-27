import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import 'daily_ayah.dart';
import 'quran.dart';
import 'quran_reader_screen.dart';

/// The ayah of the day under the prayer times: why it was picked, the Arabic
/// and its translation. Tapping it opens the reader there.
class DailyAyahCard extends ConsumerWidget {
  /// The day shown, which picks the ayah.
  final DateTime day;

  const DailyAyahCard({super.key, required this.day});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final ayahs = ref.watch(dailyAyahsProvider).value;
    final index = ref.watch(quranIndexProvider).value;
    // The card is an extra under the times, so it stays out of the way
    // until its small files load.
    if (ayahs == null || index == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final accent = AppColors.accentOf(ctx);
    final languageCode = Localizations.localeOf(ctx).languageCode;
    final pick = ayahs.pick(
      day,
      ref.watch(settingsProvider.select((s) => s.hijriAdjustment)),
    );
    final ayahRef = pick.ayah.ref;
    final translation = pick.ayah.translationFor(languageCode);
    final mq = MediaQuery.of(ctx);
    final landscape = mq.orientation == Orientation.landscape;

    return Semantics(
      button: true,
      onTapHint: l10n.dailyAyahOpen,
      child: GlassCard(
        margin: EdgeInsets.fromLTRB(
          AppSpacing.md + (landscape ? mq.padding.left : 0),
          AppSpacing.sm,
          AppSpacing.md + (landscape ? mq.padding.right : 0),
          AppSpacing.xxs,
        ),
        onTap: () => Navigator.of(ctx).push(
          MaterialPageRoute<void>(
            builder: (_) => QuranReaderScreen(
              surah: ayahRef.surah,
              initialAyah: ayahRef.ayah,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // Matches the title's line height.
                  Icon(Icons.auto_stories_outlined, size: 18, color: accent),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.dailyAyah,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.quranReference(
                      index.surah(ayahRef.surah).nameFor(languageCode),
                      ayahRef.surah,
                      ayahRef.ayah,
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                pick.group.whyFor(languageCode),
                style: theme.textTheme.labelMedium?.copyWith(color: accent),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                pick.ayah.arabic,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                // Tall lines keep the harakat of adjacent lines apart.
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: quranFontFamily,
                  height: 2.2,
                ),
              ),
              if (translation != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(translation, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
