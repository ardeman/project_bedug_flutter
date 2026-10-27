import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';
import '../design/liquid_glass.dart';
import '../theme/app_tokens.dart';

/// A text to recite, such as a dzikir or a dua: its Arabic, and for readers
/// of other languages its transliteration and translation, with a reference
/// to look it up.
class RecitationCard extends StatelessWidget {
  /// A heading above the text, such as when a dua is read.
  final String? title;

  /// A short highlighted label beside the reference, such as how many times
  /// to recite it. Shown only without a [title].
  final String? badge;

  /// When it applies, such as "After Fajr", shown under the heading.
  final String? note;

  final String arabic;
  final String transliteration;

  /// The meaning in the reader's language; null for Arabic readers, who read
  /// the text itself, which also hides the transliteration.
  final String? translation;

  /// Where it comes from, such as a surah or hadith collection.
  final String reference;

  const RecitationCard({
    super.key,
    this.title,
    this.badge,
    this.note,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.reference,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final accent = AppColors.accentOf(ctx);
    final muted = theme.colorScheme.onSurfaceVariant;
    final referenceStyle = theme.textTheme.labelSmall?.copyWith(color: muted);

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title case final title?) ...[
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(reference, style: referenceStyle),
            ] else
              Row(
                children: [
                  if (badge case final badge?) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      child: Text(
                        badge,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      reference,
                      textAlign: TextAlign.end,
                      style: referenceStyle,
                    ),
                  ),
                ],
              ),
            if (note case final note?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                note,
                style: theme.textTheme.labelMedium?.copyWith(color: accent),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              // Tall lines keep the harakat of adjacent lines apart.
              style: theme.textTheme.headlineSmall?.copyWith(height: 2),
            ),
            if (translation case final translation?) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                transliteration,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: accent,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(translation, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
