import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/theme/app_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import 'quran.dart';
import 'quran_reader_screen.dart';

enum _QuranView { surahs, juz, bookmarks }

/// Quran tab: the surahs, the 30 juz and the bookmarked ayahs, with a way
/// back to where the reader left off.
class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  var _view = _QuranView.surahs;

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final index = ref.watch(quranIndexProvider);
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: l10n.quran),
      body: Center(
        child: ConstrainedBox(
          // Keep rows readable on wide desktop windows.
          constraints: const BoxConstraints(maxWidth: 640),
          child: index.when(
            loading: () => const Center(child: AdaptiveSpinner()),
            error: (_, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(l10n.quranLoadError, textAlign: TextAlign.center),
              ),
            ),
            data: (index) => _list(ctx, index),
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext ctx, QuranIndex index) {
    final l10n = AppLocalizations.of(ctx);
    final reading = ref.watch(quranReadingProvider);
    final lastRead = reading.lastRead;
    final rows = switch (_view) {
      _QuranView.surahs => [
        for (final surah in index.surahs) _SurahRow(surah: surah),
      ],
      _QuranView.juz => [
        for (final (i, start) in index.juzStarts.indexed)
          _AyahRow(
            index: index,
            ayah: start,
            number: i + 1,
            title: l10n.quranJuzNumber(i + 1),
          ),
      ],
      _QuranView.bookmarks => [
        for (final bookmark in reading.bookmarks.where(index.contains))
          _AyahRow(index: index, ayah: bookmark, icon: Icons.bookmark),
      ],
    };
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: PlatformSegmentedControl<_QuranView>(
            segments: {
              _QuranView.surahs: l10n.quranSurahs,
              _QuranView.juz: l10n.quranJuz,
              _QuranView.bookmarks: l10n.quranBookmarks,
            },
            value: _view,
            onChanged: (view) => setState(() => _view = view),
          ),
        ),
        if (lastRead != null && index.contains(lastRead))
          _AyahRow(
            index: index,
            ayah: lastRead,
            icon: Icons.auto_stories,
            title: l10n.quranContinueReading,
          ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              l10n.quranNoBookmarks,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium
                  ?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
            ),
          ),
        ...rows,
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

void _openReader(BuildContext ctx, AyahRef ayah) => Navigator.of(ctx).push(
  MaterialPageRoute<void>(
    builder: (_) =>
        QuranReaderScreen(surah: ayah.surah, initialAyah: ayah.ayah),
  ),
);

const _rowMargin = EdgeInsets.fromLTRB(
  AppSpacing.md,
  AppSpacing.xs,
  AppSpacing.md,
  AppSpacing.xs,
);

class _SurahRow extends StatelessWidget {
  final Surah surah;

  const _SurahRow({required this.surah});

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final languageCode = Localizations.localeOf(ctx).languageCode;
    final revelation = switch (surah.revelation) {
      Revelation.meccan => l10n.quranMeccan,
      Revelation.medinan => l10n.quranMedinan,
    };
    return GlassCard(
      margin: _rowMargin,
      child: PlatformListTile(
        leading: _NumberBadge(number: surah.number),
        title: Text(surah.nameFor(languageCode)),
        subtitle: Text('$revelation · ${l10n.quranAyahCount(surah.ayahCount)}'),
        trailing: languageCode == 'ar'
            ? null
            : Text(
                surah.arabic,
                textDirection: TextDirection.rtl,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: quranFontFamily,
                  color: AppColors.accentOf(ctx),
                ),
              ),
        onTap: () => _openReader(ctx, AyahRef(surah.number, 1)),
      ),
    );
  }
}

/// A row that opens the reader at [ayah]: a juz start, a bookmark or the
/// last-read position.
class _AyahRow extends StatelessWidget {
  final QuranIndex index;
  final AyahRef ayah;

  /// Shown as a badge in place of an [icon].
  final int? number;
  final IconData? icon;

  /// Defaults to the surah's name.
  final String? title;

  const _AyahRow({
    required this.index,
    required this.ayah,
    this.number,
    this.icon,
    this.title,
  });

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final languageCode = Localizations.localeOf(ctx).languageCode;
    final surahName = index.surah(ayah.surah).nameFor(languageCode);
    final location = '$surahName · ${l10n.quranAyah(ayah.ayah)}';
    return GlassCard(
      margin: _rowMargin,
      child: PlatformListTile(
        leading: number != null
            ? _NumberBadge(number: number!)
            : Icon(icon, color: AppColors.accentOf(ctx)),
        title: Text(title ?? surahName),
        subtitle: Text(title == null ? l10n.quranAyah(ayah.ayah) : location),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openReader(ctx, ayah),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int number;

  const _NumberBadge({required this.number});

  /// Fits three digits in the list's 24pt leading slot and a bit more.
  static const _size = 32.0;

  @override
  Widget build(BuildContext ctx) {
    final accent = AppColors.accentOf(ctx);
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: Theme.of(ctx).textTheme.labelMedium
            ?.copyWith(color: accent, fontWeight: FontWeight.bold),
      ),
    );
  }
}
