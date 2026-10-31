import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/design/platform_design.dart';
import '../../core/theme/app_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import 'khatam.dart';
import 'quran.dart';

/// A sheet for an ayah tapped on a mushaf page: its translation, then its
/// bookmark and khatam mark. A native sheet on Apple platforms and an
/// Expressive one on Material paths.
Future<void> showAyahSheet(
  BuildContext ctx, {
  required QuranIndex index,
  required AyahRef ayah,
  required QuranText? translation,
}) {
  Widget content(ScrollController? controller) => _AyahSheet(
    index: index,
    ayah: ayah,
    translation: translation,
    controller: controller,
  );
  if (PlatformCapabilities.isApple) {
    return showCupertinoSheet<void>(
      context: ctx,
      showDragHandle: true,
      // About half the screen, so the page stays in view above it.
      topGap: 0.45,
      scrollableBuilder: (_, controller) {
        final colors = Theme.of(ctx).colorScheme;
        return CupertinoPageScaffold(
          backgroundColor: colors.surface,
          child: SafeArea(top: false, child: content(controller)),
        );
      },
    );
  }
  final l10n = AppLocalizations.of(ctx);
  if (PlatformDesign.usesExpressive) {
    return M3EBottomSheet.show<void>(
      ctx,
      labels: M3EBottomSheetLabels(
        dragHandle: l10n.sheetHandle,
        expand: l10n.sheetExpand,
        collapse: l10n.sheetCollapse,
        dismiss: l10n.sheetDismiss,
        close: l10n.sheetDismiss,
        scrim: l10n.sheetDismiss,
        preview: l10n.sheetPreview,
        collapsed: l10n.sheetCollapsed,
        expanded: l10n.sheetExpanded,
        fullScreen: l10n.sheetFullScreen,
      ),
      builder: (_) => content(null),
    );
  }
  return showModalBottomSheet<void>(
    context: ctx,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => SafeArea(child: content(null)),
  );
}

class _AyahSheet extends ConsumerWidget {
  final QuranIndex index;
  final AyahRef ayah;
  final QuranText? translation;
  final ScrollController? controller;

  const _AyahSheet({
    required this.index,
    required this.ayah,
    required this.translation,
    required this.controller,
  });

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final languageCode = Localizations.localeOf(ctx).languageCode;
    final scale = ref.watch(quranReadingProvider.select((r) => r.textScale));
    final bookmarked = ref.watch(
      quranReadingProvider.select((r) => r.isBookmarked(ayah)),
    );
    final khatam = ref.watch(khatamProvider);
    final translation = this.translation;
    return ListView(
      controller: controller,
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Text(
          l10n.quranReference(
            index.surah(ayah.surah).nameFor(languageCode),
            ayah.surah,
            ayah.ayah,
          ),
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.accentOf(ctx),
            fontWeight: FontWeight.bold,
          ),
        ),
        if (translation != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            translation.ayah(ayah),
            style: theme.textTheme.bodyLarge?.apply(fontSizeFactor: scale),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.dzikirSource(translation.source),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _SheetButton(
              icon: bookmarked ? Icons.bookmark : Icons.bookmark_border,
              label: bookmarked
                  ? l10n.quranRemoveBookmark
                  : l10n.quranAddBookmark,
              onPressed: () =>
                  ref.read(quranReadingProvider.notifier).toggleBookmark(ayah),
            ),
            if (khatam != null)
              _SheetButton(
                icon: khatam.reached == ayah ? Icons.flag : Icons.outlined_flag,
                label: l10n.khatamMarkRead,
                onPressed: () =>
                    ref.read(khatamProvider.notifier).markRead(ayah),
              ),
          ],
        ),
      ],
    );
  }
}

class _SheetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SheetButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext ctx) => PlatformCapabilities.isApple
      ? GlassPillButton(icon: icon, label: label, onPressed: onPressed)
      : FilledButton.tonalIcon(
          icon: Icon(icon),
          label: Text(label),
          onPressed: onPressed,
        );
}
