import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/theme/app_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import 'khatam.dart';
import 'quran.dart';
import 'quran_mushaf.dart';

/// One surah's ayahs, the Arabic with the translation for the app language,
/// opened at [initialAyah], or in page mode the mushaf's pages. Remembers the
/// ayah at the top of the screen, or the page's first ayah, as the last-read
/// position.
class QuranReaderScreen extends ConsumerStatefulWidget {
  final int surah;
  final int initialAyah;

  const QuranReaderScreen({
    super.key,
    required this.surah,
    this.initialAyah = 1,
  });

  @override
  ConsumerState<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends ConsumerState<QuranReaderScreen> {
  /// The forward list starts here, so the reader opens at [initialAyah]
  /// without laying out the ayahs above it; those build upwards.
  final _centerKey = UniqueKey();

  /// The ayah tiles on screen, to find the one at the top.
  final _tiles = <int, BuildContext>{};

  /// Where the list or the pages open; moves to the last-read ayah when the
  /// reader switches between them.
  late var _position = AyahRef(widget.surah, widget.initialAyah);

  /// The surah of the page in view, for the title in page mode.
  int? _pageSurah;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _saveLastRead(_position);
    });
  }

  void _setPageMode(bool pageMode) {
    final lastRead = ref.read(quranReadingProvider).lastRead;
    setState(() {
      if (lastRead != null) _position = lastRead;
      _pageSurah = null;
    });
    ref.read(quranReadingProvider.notifier).setPageMode(pageMode);
  }

  void _showPage(AyahRef first) {
    setState(() => _pageSurah = first.surah);
    _saveLastRead(first);
  }

  void _saveLastRead(AyahRef ayah) =>
      ref.read(quranReadingProvider.notifier).setLastRead(ayah);

  /// Saves the first ayah whose bottom is below [topInset], the part of the
  /// screen the top bar covers.
  void _saveTopAyah(double topInset) {
    int? top;
    for (final MapEntry(key: ayah, value: tile) in _tiles.entries) {
      final box = tile.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
      if (bottom > topInset && (top == null || ayah < top)) top = ayah;
    }
    if (top != null) _saveLastRead(AyahRef(widget.surah, top));
  }

  void _stepTextScale(int step) {
    final scale = ref.read(quranReadingProvider).textScale;
    final i = quranTextScales.indexOf(scale) + step;
    if (i < 0 || i >= quranTextScales.length) return;
    ref.read(quranReadingProvider.notifier).setTextScale(quranTextScales[i]);
  }

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final languageCode = Localizations.localeOf(ctx).languageCode;
    final index = ref.watch(quranIndexProvider).value;
    final text = ref.watch(quranTextProvider);
    final translation = ref.watch(quranTranslationProvider);
    final scale = ref.watch(quranReadingProvider.select((r) => r.textScale));
    final pageMode = ref.watch(quranReadingProvider.select((r) => r.pageMode));
    final titleSurah = pageMode
        ? _pageSurah ?? _position.surah
        : _position.surah;

    final failed = text.hasError || translation.hasError;
    final ready = index != null && text.hasValue && translation.hasValue;
    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(
        title: index?.surah(titleSurah).nameFor(languageCode) ?? l10n.quran,
        actions: [
          GlassTopBarAction(
            icon: pageMode ? Icons.view_agenda_outlined : Icons.auto_stories,
            tooltip: pageMode ? l10n.quranListView : l10n.quranPageView,
            onPressed: () => _setPageMode(!pageMode),
          ),
          // Pages fit their text to the page instead.
          if (!pageMode) ...[
            GlassTopBarAction(
              icon: Icons.text_decrease,
              tooltip: l10n.quranTextSmaller,
              onPressed: scale == quranTextScales.first
                  ? null
                  : () => _stepTextScale(-1),
            ),
            GlassTopBarAction(
              icon: Icons.text_increase,
              tooltip: l10n.quranTextLarger,
              onPressed: scale == quranTextScales.last
                  ? null
                  : () => _stepTextScale(1),
            ),
          ],
        ],
      ),
      body: failed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(l10n.quranLoadError, textAlign: TextAlign.center),
              ),
            )
          : !ready
          ? const Center(child: AdaptiveSpinner())
          : pageMode
          ? QuranMushafView(
              key: ValueKey(_position),
              index: index,
              text: text.requireValue,
              translation: translation.value,
              initial: _position,
              topInset: _topInset(ctx),
              onPageShown: _showPage,
            )
          : KeyedSubtree(
              key: ValueKey(_position),
              child: _reader(ctx, index, text.requireValue, translation.value),
            ),
    );
  }

  /// Content goes under the glass bar on Apple; elsewhere the app bar sits
  /// above the body.
  double _topInset(BuildContext ctx) => PlatformCapabilities.isApple
      ? MediaQuery.of(ctx).padding.top + kToolbarHeight
      : 0.0;

  Widget _reader(
    BuildContext ctx,
    QuranIndex index,
    QuranText text,
    QuranText? translation,
  ) {
    final surah = index.surah(_position.surah);
    final initial = _position.ayah.clamp(1, surah.ayahCount);
    final topInset = _topInset(ctx);

    Widget tile(int ayah) => _AyahTile(
      key: ValueKey(ayah),
      ayah: AyahRef(surah.number, ayah),
      arabic: ayahWithoutBasmala(text, AyahRef(surah.number, ayah)),
      translation: translation?.ayah(AyahRef(surah.number, ayah)),
      onAttach: (ctx) => _tiles[ayah] = ctx,
      onDetach: () => _tiles.remove(ayah),
    );

    final header = _SurahHeader(
      surah: surah,
      basmala: hasBasmalaHeading(surah.number)
          ? text.ayah(const AyahRef(1, 1))
          : null,
    );
    final startsAtHeader = initial == 1;
    final footer = _SurahFooter(
      next: surah.number < index.surahs.length
          ? index.surah(surah.number + 1)
          : null,
      source: [text.source, ?translation?.source].join(' · '),
    );

    return Center(
      child: ConstrainedBox(
        // Keep lines readable on wide desktop windows.
        constraints: const BoxConstraints(maxWidth: 720),
        child: LayoutBuilder(
          builder: (ctx, constraints) =>
              NotificationListener<ScrollEndNotification>(
                onNotification: (_) {
                  _saveTopAyah(topInset);
                  return false;
                },
                child: CustomScrollView(
                  center: _centerKey,
                  // Puts the initial ayah just below the top bar.
                  anchor: (topInset / constraints.maxHeight).clamp(0, 1),
                  slivers: [
                    // Ayahs above the initial one, built upwards, then the
                    // header, then room for the top bar, so the scroll
                    // view's top edge leaves the header clear of the bar.
                    SliverList.builder(
                      itemCount: startsAtHeader ? 0 : initial + 1,
                      itemBuilder: (_, i) => i == initial
                          ? SizedBox(height: topInset)
                          : i == initial - 1
                          ? header
                          : tile(initial - 1 - i),
                    ),
                    // Opening at the first ayah starts with the header.
                    SliverList.builder(
                      key: _centerKey,
                      itemCount:
                          surah.ayahCount -
                          initial +
                          2 +
                          (startsAtHeader ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (startsAtHeader && i == 0) return header;
                        final j = startsAtHeader ? i - 1 : i;
                        return j == surah.ayahCount - initial + 1
                            ? footer
                            : tile(initial + j);
                      },
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}

/// The surah's name, and the basmala for every surah but Al-Fatihah, where
/// it is the first ayah, and At-Taubah, which has none.
class _SurahHeader extends StatelessWidget {
  final Surah surah;
  final String? basmala;

  const _SurahHeader({required this.surah, required this.basmala});

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final arabic = theme.textTheme.headlineMedium?.copyWith(
      fontFamily: quranFontFamily,
      color: AppColors.accentOf(ctx),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Text(surah.arabic, textDirection: TextDirection.rtl, style: arabic),
          if (basmala case final basmala?) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              basmala,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: arabic?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ],
        ],
      ),
    );
  }
}

class _AyahTile extends ConsumerStatefulWidget {
  final AyahRef ayah;
  final String arabic;

  /// Null for Arabic readers, who read the text itself.
  final String? translation;

  /// Registers the tile's context while it is on screen.
  final ValueChanged<BuildContext> onAttach;
  final VoidCallback onDetach;

  const _AyahTile({
    super.key,
    required this.ayah,
    required this.arabic,
    required this.translation,
    required this.onAttach,
    required this.onDetach,
  });

  @override
  ConsumerState<_AyahTile> createState() => _AyahTileState();
}

class _AyahTileState extends ConsumerState<_AyahTile> {
  @override
  void initState() {
    super.initState();
    widget.onAttach(context);
  }

  @override
  void dispose() {
    widget.onDetach();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final accent = AppColors.accentOf(ctx);
    final reading = ref.watch(quranReadingProvider);
    final bookmarked = reading.isBookmarked(widget.ayah);
    final khatam = ref.watch(khatamProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '${widget.ayah}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (khatam != null)
                    _AyahAction(
                      icon: khatam.reached == widget.ayah
                          ? Icons.flag
                          : Icons.outlined_flag,
                      tooltip: l10n.khatamMarkRead,
                      onPressed: () => ref
                          .read(khatamProvider.notifier)
                          .markRead(widget.ayah),
                    ),
                  _AyahAction(
                    icon: bookmarked ? Icons.bookmark : Icons.bookmark_border,
                    tooltip: bookmarked
                        ? l10n.quranRemoveBookmark
                        : l10n.quranAddBookmark,
                    onPressed: () => ref
                        .read(quranReadingProvider.notifier)
                        .toggleBookmark(widget.ayah),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                child: Text(
                  widget.arabic,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  // Tall lines keep the harakat of adjacent lines apart.
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontFamily: quranFontFamily, height: 2.2)
                      .apply(fontSizeFactor: reading.textScale),
                ),
              ),
              if (widget.translation case final translation?) ...[
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: Text(
                    translation,
                    style: theme.textTheme.bodyLarge?.apply(
                      fontSizeFactor: reading.textScale,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Hairline(indent: AppSpacing.md),
      ],
    );
  }
}

/// An ayah's bookmark or khatam mark.
class _AyahAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _AyahAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext ctx) {
    final icon = Icon(this.icon, color: AppColors.accentOf(ctx));
    if (!PlatformCapabilities.isApple) {
      return IconButton(icon: icon, tooltip: tooltip, onPressed: onPressed);
    }
    return Semantics(
      button: true,
      label: tooltip,
      child: GlassPressable(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: icon,
        ),
      ),
    );
  }
}

/// The next surah, then the sources of the text and translation.
class _SurahFooter extends StatelessWidget {
  final Surah? next;
  final String source;

  const _SurahFooter({required this.next, required this.source});

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final languageCode = Localizations.localeOf(ctx).languageCode;
    final next = this.next;
    void openNext() => Navigator.of(ctx).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuranReaderScreen(surah: next!.number),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl + MediaQuery.of(ctx).padding.bottom,
      ),
      child: Column(
        children: [
          if (next != null) ...[
            if (PlatformCapabilities.isApple)
              GlassPillButton(
                icon: Icons.arrow_forward,
                label: l10n.quranNextSurah(next.nameFor(languageCode)),
                onPressed: openNext,
              )
            else
              FilledButton.tonalIcon(
                icon: const Icon(Icons.arrow_forward),
                label: Text(l10n.quranNextSurah(next.nameFor(languageCode))),
                onPressed: openNext,
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            l10n.dzikirSource(source),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
