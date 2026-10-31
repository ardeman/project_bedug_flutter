import 'dart:math' show pi;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import 'quran.dart';
import 'quran_ayah_sheet.dart';

/// The Quran as the pages of the Madinah mushaf, turned right to left like
/// the book: dragging lifts the leaf over the spine. Windows wider than they are tall show two facing pages, the odd
/// one on the right.
class QuranMushafView extends StatefulWidget {
  final QuranIndex index;
  final QuranText text;

  /// The app language's translation, shown when an ayah is tapped; null for
  /// Arabic.
  final QuranText? translation;

  /// The page opened first is the one this ayah is on.
  final AyahRef initial;

  /// Space covered by the top bar, which the pages keep clear of.
  final double topInset;

  /// Called with the first ayah of the page (or the right-hand page of a
  /// spread) that comes into view.
  final ValueChanged<AyahRef> onPageShown;

  const QuranMushafView({
    super.key,
    required this.index,
    required this.text,
    required this.translation,
    required this.initial,
    required this.topInset,
    required this.onPageShown,
  });

  /// Below this width two pages would be too small to read.
  static const spreadMinWidth = 600.0;

  /// Whether a window of [size] shows two facing pages.
  static bool showsSpread(Size size) =>
      size.width > size.height && size.width >= spreadMinWidth;

  @override
  State<QuranMushafView> createState() => _QuranMushafViewState();
}

class _QuranMushafViewState extends State<QuranMushafView>
    with SingleTickerProviderStateMixin {
  /// The page in view, or the right-hand page of the spread in view.
  late int _page = widget.index.pageOf(widget.initial);

  /// How far the leaf has turned from [_page]'s item: up to 1 towards the
  /// next, down to -1 towards the previous.
  late final _turn = AnimationController.unbounded(vsync: this);

  /// The drag so far while Reduce Motion keeps the leaf still.
  var _dragTurn = 0.0;

  var _spread = false;

  /// A full turn of the leaf.
  static const _turnDuration = Duration(milliseconds: 520);

  /// A fling faster than this turns the page whatever the distance dragged.
  static const _flingVelocity = 300.0;

  /// How strongly the leaf foreshortens as it lifts off the page, over the
  /// leaf's width: its edge, held upright, looks a third larger.
  static const _perspective = 0.25;

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  int get _itemCount =>
      _spread ? (widget.index.pageCount + 1) ~/ 2 : widget.index.pageCount;

  /// The page or spread [page] is shown in.
  int _itemOf(int page) => _spread ? (page - 1) ~/ 2 : page - 1;

  /// The page shown, or the spread's right-hand page.
  int _firstPageOf(int item) => _spread ? item * 2 + 1 : item + 1;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  /// The turn stays within one page either way, and stops at the covers.
  double _clampTurn(double turn) {
    final item = _itemOf(_page);
    return turn.clamp(item > 0 ? -1.0 : 0.0, item < _itemCount - 1 ? 1.0 : 0.0);
  }

  void _onDragStart(DragStartDetails _) {
    _turn.stop();
    _dragTurn = _turn.value;
  }

  void _onDragUpdate(DragUpdateDetails details, double leafWidth) {
    // The leaf turns over the spine on the right, so dragging right turns
    // forward.
    _dragTurn = _clampTurn(_dragTurn + details.primaryDelta! / leafWidth);
    if (!_reduceMotion) _turn.value = _dragTurn;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    _settle(
      velocity > _flingVelocity
          ? 1
          : velocity < -_flingVelocity
          ? -1
          : _dragTurn.roundToDouble(),
    );
  }

  /// Finishes the turn at [target]: -1, 0 or 1.
  Future<void> _settle(double target) async {
    target = _clampTurn(target);
    if (_reduceMotion) {
      _turn.value = target;
    } else {
      final distance = (target - _turn.value).abs();
      await _turn.animateTo(
        target,
        duration: _turnDuration * distance.clamp(0.3, 1.0),
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted || target == 0) return;
    final item = _itemOf(_page) + target.toInt();
    setState(() => _page = _firstPageOf(item));
    _turn.value = 0;
    _dragTurn = 0;
    widget.onPageShown(widget.index.pageStarts[_page - 1]);
  }

  void _turnBy(int step) {
    if (_turn.isAnimating) return;
    _settle(step.toDouble());
  }

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final media = MediaQuery.of(ctx);
    return Padding(
      padding: EdgeInsets.only(
        top: widget.topInset,
        bottom: media.padding.bottom,
        left: media.padding.left,
        right: media.padding.right,
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          _spread = QuranMushafView.showsSpread(constraints.biggest);
          final width = constraints.maxWidth;
          final leafWidth = _spread ? width / 2 : width;
          return Focus(
            autofocus: true,
            // The next page lies to the left, as in the book.
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _turnBy(1);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _turnBy(-1);
              } else {
                return KeyEventResult.ignored;
              }
              return KeyEventResult.handled;
            },
            child: Semantics(
              container: true,
              label: l10n.quranPageNumber(_page),
              onScrollRight: () => _turnBy(1),
              onScrollLeft: () => _turnBy(-1),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: _onDragStart,
                onHorizontalDragUpdate: (d) => _onDragUpdate(d, leafWidth),
                onHorizontalDragEnd: _onDragEnd,
                child: AnimatedBuilder(
                  animation: _turn,
                  builder: (ctx, _) => Stack(
                    children: _spread
                        ? _spreadLeaves(ctx, width)
                        : _singleLeaves(ctx, width),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// The pages to draw for a turn of [_turn]: the item the turn starts from
  /// and how far it has gone towards the next one, 0 to 1.
  (int, double) get _turnFrom {
    final item = _itemOf(_page);
    final turn = _turn.value;
    return turn >= 0 ? (item, turn) : (item - 1, 1 + turn);
  }

  Widget _leaf(
    BuildContext ctx,
    int page, {
    required double left,
    required double width,
    double angle = 0,
    Alignment spine = Alignment.centerRight,
    double shade = 0,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
  }) => Positioned(
    key: ValueKey(page),
    left: left,
    width: width,
    top: 0,
    bottom: 0,
    child: Transform(
      alignment: spine,
      transform: Matrix4.identity()
        ..setEntry(3, 2, _perspective / width)
        ..rotateY(angle),
      child: Padding(
        padding: padding,
        child: page > widget.index.pageCount
            ? const SizedBox.shrink()
            : _MushafPage(
                index: widget.index,
                text: widget.text,
                translation: widget.translation,
                number: page,
                uiDirection: Directionality.of(ctx),
                shade: shade,
              ),
      ),
    ),
  );

  /// One page folds over its right edge, the spine of a right-to-left book,
  /// and uncovers the next one.
  List<Widget> _singleLeaves(BuildContext ctx, double width) {
    final (item, t) = _turnFrom;
    final page = _firstPageOf(item);
    return [
      if (t > 0)
        _leaf(ctx, page + 1, left: 0, width: width, shade: (1 - t) * 0.5),
      // Past a quarter turn the leaf is edge on and gone.
      if (t < 1)
        _leaf(ctx, page, left: 0, width: width, angle: -t * pi / 2, shade: t),
    ];
  }

  /// The left page lifts over the spine in the middle and comes down on the
  /// right as the next spread's right-hand page.
  List<Widget> _spreadLeaves(BuildContext ctx, double width) {
    final (item, t) = _turnFrom;
    final right = _firstPageOf(item);
    final half = width / 2;
    // A gap either side of the spine, like the gutter between facing pages.
    const leftPad = EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.xs);
    const rightPad = EdgeInsets.only(left: AppSpacing.xs, right: AppSpacing.sm);
    final landing = t >= 0.5;
    return [
      // Underneath: the next spread's left page, and the right page the
      // leaf lands on.
      if (t > 0)
        _leaf(
          ctx,
          right + 3,
          left: 0,
          width: half,
          padding: leftPad,
          shade: (1 - 2 * t).clamp(0, 1) * 0.5,
        ),
      _leaf(
        ctx,
        right,
        left: half,
        width: half,
        padding: rightPad,
        shade: (2 * t - 1).clamp(0, 1) * 0.5,
      ),
      if (!landing)
        _leaf(
          ctx,
          right + 1,
          left: 0,
          width: half,
          padding: leftPad,
          angle: -t * pi,
          shade: t * 2,
        )
      else
        _leaf(
          ctx,
          right + 2,
          left: half,
          width: half,
          padding: rightPad,
          spine: Alignment.centerLeft,
          angle: (1 - t) * pi,
          shade: (1 - t) * 2,
        ),
    ];
  }
}

/// Lines on a page of the Madinah mushaf, which the text size is fitted to.
const _linesPerPage = 15;

/// Tall lines keep the harakat of adjacent lines apart.
const _lineHeight = 1.9;

/// Roughly the letters on a mushaf line, so the text size also fits the
/// page's width.
const _lettersPerLine = 14;

/// The darkest a page gets as a turning leaf shadows it.
const _maxShade = 0.35;

const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';

/// [n] in Arabic-Indic digits, which the ayah-end sign encloses.
String _arabicNumber(int n) =>
    '$n'.split('').map((d) => _arabicDigits[int.parse(d)]).join();

/// One mushaf page: the surah and juz above a framed page of text, and the
/// page number below. Tapping an ayah shows its translation, bookmark and khatam mark.
class _MushafPage extends ConsumerStatefulWidget {
  final QuranIndex index;
  final QuranText text;

  /// The app language's translation, shown when an ayah is tapped; null for
  /// Arabic.
  final QuranText? translation;
  final int number;

  /// The app language's direction, for the labels around the page.
  final TextDirection uiDirection;

  /// How far the page is in shadow while a leaf turns, 0 to 1.
  final double shade;

  const _MushafPage({
    required this.index,
    required this.text,
    required this.translation,
    required this.number,
    required this.uiDirection,
    this.shade = 0,
  });

  @override
  ConsumerState<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends ConsumerState<_MushafPage> {
  final _recognizers = <AyahRef, TapGestureRecognizer>{};

  /// The ayah whose menu is open, shown highlighted.
  AyahRef? _selected;

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _recognizerFor(AyahRef ayah) => _recognizers.putIfAbsent(
    ayah,
    () => TapGestureRecognizer()..onTap = () => _openAyah(ayah),
  );

  Future<void> _openAyah(AyahRef ayah) async {
    // A second tap while the sheet opens would stack another one.
    if (_selected != null) return;
    setState(() => _selected = ayah);
    try {
      await showAyahSheet(
        context,
        index: widget.index,
        ayah: ayah,
        translation: widget.translation,
      );
    } finally {
      if (mounted) setState(() => _selected = null);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final scheme = theme.colorScheme;
    final accent = AppColors.accentOf(ctx);
    final gold = scheme.tertiary;
    final index = widget.index;
    final ayahs = index.ayahsOnPage(widget.number);
    final first = ayahs.first;
    final label = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    // A warm paper tone that follows the theme and dark mode.
    final paper = Color.alphaBlend(
      gold.withValues(alpha: 0.06),
      scheme.surface,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Text(
                index.surah(first.surah).arabic,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: quranFontFamily,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                l10n.quranJuzNumber(index.juzOf(first)),
                textDirection: widget.uiDirection,
                style: label,
              ),
            ],
          ),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: paper,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: gold.withValues(alpha: 0.7), width: 2),
            ),
            position: DecorationPosition.background,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.shadow.withValues(
                  alpha: widget.shade.clamp(0, 1) * _maxShade,
                ),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              position: DecorationPosition.foreground,
              child: Padding(
                // The inner rule of the double frame.
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: gold.withValues(alpha: 0.4)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: LayoutBuilder(
                      builder: (ctx, box) =>
                          _text(ctx, ayahs, box, accent: accent, gold: gold),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Semantics(
            label: l10n.quranPageNumber(widget.number),
            excludeSemantics: true,
            child: Text('${widget.number}', style: label),
          ),
        ),
      ],
    );
  }

  /// The page's ayahs as justified paragraphs, broken by a title band and
  /// the basmala where a surah begins, sized for a mushaf's 15 lines and
  /// shrunk further if the page still overflows.
  Widget _text(
    BuildContext ctx,
    List<AyahRef> ayahs,
    BoxConstraints box, {
    required Color accent,
    required Color gold,
  }) {
    final theme = Theme.of(ctx);
    final reading = ref.watch(quranReadingProvider);
    final fontSize = [
      box.maxHeight / (_linesPerPage * _lineHeight),
      box.maxWidth / _lettersPerLine,
    ].reduce((a, b) => a < b ? a : b);
    final style = theme.textTheme.bodyLarge?.copyWith(
      fontFamily: quranFontFamily,
      fontSize: fontSize,
      height: _lineHeight,
      color: theme.colorScheme.onSurface,
    );

    final blocks = <Widget>[];
    var spans = <InlineSpan>[];
    void endParagraph() {
      if (spans.isEmpty) return;
      blocks.add(
        Text.rich(
          TextSpan(children: spans),
          style: style,
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
        ),
      );
      spans = [];
    }

    for (final ayah in ayahs) {
      if (ayah.ayah == 1) {
        endParagraph();
        blocks.add(
          _SurahBand(surah: widget.index.surah(ayah.surah), style: style),
        );
        if (hasBasmalaHeading(ayah.surah)) {
          blocks.add(
            Text(
              widget.text.ayah(const AyahRef(1, 1)),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: style,
            ),
          );
        }
      }
      final recognizer = _recognizerFor(ayah);
      final selected = ayah == _selected;
      spans
        ..add(
          TextSpan(
            text: '${ayahWithoutBasmala(widget.text, ayah)} ',
            recognizer: recognizer,
            style: selected
                ? TextStyle(backgroundColor: accent.withValues(alpha: 0.16))
                : null,
          ),
        )
        ..add(
          TextSpan(
            // The ayah-end sign, which encloses the digits after it.
            text: '۝${_arabicNumber(ayah.ayah)}',
            recognizer: recognizer,
            style: TextStyle(color: reading.isBookmarked(ayah) ? accent : gold),
          ),
        )
        ..add(const TextSpan(text: ' '));
    }
    endParagraph();

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: box.maxWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: blocks,
          ),
        ),
      ),
    );
  }
}

/// The framed band with a surah's name where it begins on a page.
class _SurahBand extends StatelessWidget {
  final Surah surah;
  final TextStyle? style;

  const _SurahBand({required this.surah, required this.style});

  @override
  Widget build(BuildContext ctx) {
    final gold = Theme.of(ctx).colorScheme.tertiary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: gold.withValues(alpha: 0.6)),
      ),
      child: Text(
        // "Surah …", in Arabic as on every mushaf whatever the app language.
        'سُورَةُ ${surah.arabic}',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: style?.copyWith(color: AppColors.accentOf(ctx)),
      ),
    );
  }
}
