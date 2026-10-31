import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/design/platform_design.dart';
import '../../core/theme/app_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import 'khatam.dart';
import 'quran.dart';

/// The most of the screen's height the sheet takes before its content
/// scrolls, leaving the page above in view; the Expressive sheet also opens
/// at half the screen.
const _maxPanelHeight = 0.5;

/// A sheet for an ayah tapped on a mushaf page: the ayah itself and its
/// translation, then its bookmark and khatam mark. On Apple platforms a
/// glass panel that floats above the page and fits its content, so the page
/// stays in view; an Expressive sheet on Material paths.
Future<void> showAyahSheet(
  BuildContext ctx, {
  required QuranIndex index,
  required AyahRef ayah,
  required QuranText? translation,
  required QuranText arabic,
}) {
  final content = _AyahSheet(
    index: index,
    ayah: ayah,
    translation: translation,
    arabic: arabic,
  );
  if (PlatformCapabilities.isApple) {
    return Navigator.of(ctx).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, animation, _) =>
            _GlassAyahPanel(animation: animation, child: content),
      ),
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
      builder: (_) => content,
    );
  }
  return showModalBottomSheet<void>(
    context: ctx,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => SafeArea(child: content),
  );
}

/// Tall lines keep the harakat of adjacent lines apart, as on the page.
const _arabicLineHeight = 1.9;

class _AyahSheet extends ConsumerWidget {
  final QuranIndex index;
  final AyahRef ayah;
  final QuranText? translation;
  final QuranText arabic;

  const _AyahSheet({
    required this.index,
    required this.ayah,
    required this.translation,
    required this.arabic,
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
        const SizedBox(height: AppSpacing.sm),
        Text(
          ayahWithoutBasmala(arabic, ayah),
          textDirection: TextDirection.rtl,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontFamily: quranFontFamily, height: _arabicLineHeight)
              .apply(fontSizeFactor: scale),
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

/// The panel stays a comfortable reading width on wide windows.
const _maxPanelWidth = 600.0;

/// A downward fling faster than this dismisses the panel.
const _dismissVelocity = 300.0;

/// The Apple ayah panel: lite glass that slides up from the bottom and is
/// dismissed by a tap outside it or a downward fling.
class _GlassAyahPanel extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _GlassAyahPanel({required this.animation, required this.child});

  @override
  Widget build(BuildContext ctx) {
    final media = MediaQuery.of(ctx);
    final slide = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pop(ctx),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(slide),
          child: GestureDetector(
            // Taps inside the panel don't dismiss it.
            onTap: () {},
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > _dismissVelocity) {
                Navigator.pop(ctx);
              }
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.sm + media.padding.left,
                0,
                AppSpacing.sm + media.padding.right,
                AppSpacing.sm + media.padding.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _maxPanelWidth,
                  maxHeight: media.size.height * _maxPanelHeight,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: LiquidGlassLite(
                    shape: const LiquidGlassShape.continuousRoundedRectangle(
                      cornerRadius: AppRadii.xl,
                    ),
                    blur: 28,
                    color: glassSheetTintOf(ctx),
                    child: MediaQuery.removePadding(
                      context: ctx,
                      removeBottom: true,
                      child: child,
                    ),
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
