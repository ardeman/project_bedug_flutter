import 'dart:math' show cos, max, min, pi, sin, sqrt;
import 'dart:ui' as ui;

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
/// the book: dragging folds the leaf back along a line that follows the
/// finger, diagonally when it is held near a corner. Windows wider than they
/// are tall show two facing pages, the odd one on the right.
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

  /// How far up the leaf's height the corner lifts mid-turn when it is held
  /// right at it, which slants the fold.
  static const _cornerLift = 0.15;

  /// Where the turn was taken hold of, over the leaf's height: the corner
  /// nearer to it is the one that folds back.
  var _grab = 1.0;

  /// How far the finger has moved up or down since, in pixels.
  var _lift = 0.0;

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

  void _onDragStart(DragStartDetails details, double height) {
    _turn.stop();
    _dragTurn = _turn.value;
    _grab = (details.localPosition.dy / height).clamp(0.0, 1.0);
    _lift = 0;
  }

  void _onDragUpdate(DragUpdateDetails details, double leafWidth) {
    // The leaf turns over the spine on the right, so dragging right turns
    // forward. The fold keeps up with the finger.
    _dragTurn = _clampTurn(_dragTurn + details.primaryDelta! / leafWidth);
    _lift += details.delta.dy;
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
    _grab = 1;
    _lift = 0;
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
          final size = constraints.biggest;
          _spread = QuranMushafView.showsSpread(size);
          final leafWidth = _spread ? size.width / 2 : size.width;
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
                onHorizontalDragStart: (d) => _onDragStart(d, size.height),
                onHorizontalDragUpdate: (d) => _onDragUpdate(d, leafWidth),
                onHorizontalDragEnd: _onDragEnd,
                child: AnimatedBuilder(
                  animation: _turn,
                  // A lifted corner stays below the top bar.
                  builder: (ctx, _) => ClipRect(
                    child: Stack(
                      children: _spread
                          ? _spreadLeaves(ctx, size)
                          : _singleLeaves(ctx, size),
                    ),
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

  /// [page] laid out in [rect] of the view, on the view's background so the
  /// page under it doesn't show through around the frame. [clip] and
  /// [transform] are in the view's coordinates; [veil] is laid over the
  /// page.
  Widget _layer(
    BuildContext ctx,
    int page,
    Rect rect, {
    required Key key,
    required EdgeInsets padding,
    List<Offset>? clip,
    Matrix4? transform,
    double shade = 0,
    Color? veil,
    bool back = false,
  }) => Positioned.fill(
    key: key,
    // The same structure whether or not the leaf is folded, so a page
    // keeps its laid-out text as a turn starts and ends.
    child: ExcludeSemantics(
      // The back of a leaf is read out as its own page once it lands.
      excluding: back,
      child: Transform(
        transform: transform ?? Matrix4.identity(),
        child: ClipPath(
          clipper: _PolygonClipper(clip),
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: rect,
                child: ColoredBox(
                  color: Theme.of(ctx).scaffoldBackgroundColor,
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
              ),
              if (veil != null)
                Positioned.fromRect(
                  rect: rect,
                  child: ColoredBox(color: veil),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  /// The fold of [leaf], whose spine is its right edge, a turn [t] of the
  /// way: the free corner nearer where it was taken hold of travels over the
  /// spine to its mirror image, lifting on the way when held near it.
  _Fold? _foldOf(Rect leaf, double t) {
    if (t <= 0) return null;
    final bottom = _grab >= 0.5;
    final corner = bottom ? leaf.bottomLeft : leaf.topLeft;
    final held = (_grab - 0.5).abs() * 2;
    final lift = (bottom ? -1 : 1) * held * _cornerLift * leaf.height + _lift;
    // The corner comes back level as it lands, so the leaf lies square.
    final rise = sin(pi * t) * lift.clamp(-leaf.height / 2, leaf.height / 2);
    return _Fold(corner, corner + Offset(2 * t * leaf.width, rise));
  }

  /// The fold's shadows: one on the page it uncovers, darkest at the fold,
  /// and one under the folded flap, both fading as the turn ends.
  Widget _foldShadows(
    BuildContext ctx,
    _Fold fold,
    double t, {
    required List<Offset> uncovered,
    required List<Offset> flap,
    required double reach,
  }) => Positioned.fill(
    child: IgnorePointer(
      child: CustomPaint(
        painter: _FoldShadowPainter(
          fold: fold,
          uncovered: uncovered,
          flap: flap,
          reach: reach,
          strength: sin(pi * t),
          shadow: Theme.of(ctx).colorScheme.shadow,
        ),
      ),
    ),
  );

  /// The flap darkens towards the fold, where it bends away from the light.
  Widget _flapShading(
    BuildContext ctx,
    _Fold fold,
    double t, {
    required List<Offset> flap,
    required double reach,
  }) => Positioned.fill(
    child: IgnorePointer(
      child: CustomPaint(
        painter: _FlapShadingPainter(
          fold: fold,
          flap: flap,
          reach: reach,
          strength: sin(pi * t),
          shadow: Theme.of(ctx).colorScheme.shadow,
        ),
      ),
    ),
  );

  /// One page folds back towards its right edge, the spine of a
  /// right-to-left book, and uncovers the next one. Its back shows the page
  /// faintly mirrored, as through paper.
  List<Widget> _singleLeaves(BuildContext ctx, Size size) {
    final (item, t) = _turnFrom;
    final page = _firstPageOf(item);
    final leaf = Offset.zero & size;
    const padding = EdgeInsets.symmetric(horizontal: AppSpacing.sm);
    final fold = _foldOf(leaf, t);
    if (fold == null) {
      return [_layer(ctx, page, leaf, key: ValueKey(page), padding: padding)];
    }
    final corners = _cornersOf(leaf);
    final folded = fold.clip(corners, flat: false);
    final flap = folded.map(fold.reflect).toList();
    final reach = size.width * _shadowReach;
    return [
      _layer(
        ctx,
        page + 1,
        leaf,
        key: ValueKey(page + 1),
        padding: padding,
        shade: (1 - t) * 0.5,
      ),
      _layer(
        ctx,
        page,
        leaf,
        key: ValueKey(page),
        padding: padding,
        clip: fold.clip(corners, flat: true),
      ),
      _foldShadows(ctx, fold, t, uncovered: folded, flap: flap, reach: reach),
      _layer(
        ctx,
        page,
        leaf,
        key: ValueKey(('back', page)),
        padding: padding,
        clip: folded,
        transform: fold.reflection,
        veil: Theme.of(ctx).scaffoldBackgroundColor
            .withValues(alpha: _backFade),
        back: true,
      ),
      _flapShading(ctx, fold, t, flap: flap, reach: reach),
    ];
  }

  /// The left page folds back towards the spine in the middle, its back
  /// becoming the next spread's right-hand page as it lands there.
  List<Widget> _spreadLeaves(BuildContext ctx, Size size) {
    final (item, t) = _turnFrom;
    final right = _firstPageOf(item);
    final half = size.width / 2;
    final leftLeaf = Rect.fromLTWH(0, 0, half, size.height);
    final rightLeaf = Rect.fromLTWH(half, 0, half, size.height);
    // A gap either side of the spine, like the gutter between facing pages.
    const leftPad = EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.xs);
    const rightPad = EdgeInsets.only(left: AppSpacing.xs, right: AppSpacing.sm);
    final fold = _foldOf(leftLeaf, t);
    final rightPage = _layer(
      ctx,
      right,
      rightLeaf,
      key: ValueKey(right),
      padding: rightPad,
    );
    if (fold == null) {
      return [
        rightPage,
        _layer(
          ctx,
          right + 1,
          leftLeaf,
          key: ValueKey(right + 1),
          padding: leftPad,
        ),
      ];
    }
    final corners = _cornersOf(leftLeaf);
    final folded = fold.clip(corners, flat: false);
    final flap = folded.map(fold.reflect).toList();
    // The back of the leaf is the page that lands on the right, so it is
    // drawn there, mirrored over the spine onto the leaf and then folded.
    Offset overSpine(Offset p) => Offset(2 * half - p.dx, p.dy);
    final spineMirror = Matrix4.diagonal3Values(-1, 1, 1)
      ..setTranslationRaw(2 * half, 0, 0);
    final reach = half * _shadowReach;
    return [
      // Underneath: the next spread's left page.
      _layer(
        ctx,
        right + 3,
        leftLeaf,
        key: ValueKey(right + 3),
        padding: leftPad,
        shade: (1 - t) * 0.5,
      ),
      rightPage,
      _layer(
        ctx,
        right + 1,
        leftLeaf,
        key: ValueKey(right + 1),
        padding: leftPad,
        clip: fold.clip(corners, flat: true),
      ),
      _foldShadows(ctx, fold, t, uncovered: folded, flap: flap, reach: reach),
      _layer(
        ctx,
        right + 2,
        rightLeaf,
        key: ValueKey(right + 2),
        padding: rightPad,
        clip: folded.map(overSpine).toList(),
        transform: fold.reflection.multiplied(spineMirror),
        back: true,
      ),
      _flapShading(ctx, fold, t, flap: flap, reach: reach),
    ];
  }
}

List<Offset> _cornersOf(Rect r) => [
  r.topLeft,
  r.topRight,
  r.bottomRight,
  r.bottomLeft,
];

/// How faintly the page shows through its own back.
const _backFade = 0.82;

/// How far the fold's shadows spread, over the leaf's width.
const _shadowReach = 0.12;

/// How high the folded flap seems to lift off the page, for its shadow.
const _flapElevation = 8.0;

/// A leaf folded flat along a straight line, as when its corner is pulled
/// across to another point: the fold runs halfway between the two, square
/// to the pull, and the part beyond it lies mirrored over the rest.
class _Fold {
  /// A point on the fold.
  final Offset mid;

  /// Points from the fold towards the part of the leaf that stays flat.
  final Offset normal;

  _Fold(Offset corner, Offset to)
    : mid = (corner + to) / 2,
      normal = (to - corner) / (to - corner).distance;

  /// How far [p] is from the fold, positive on the flat side.
  double sideOf(Offset p) =>
      (p.dx - mid.dx) * normal.dx + (p.dy - mid.dy) * normal.dy;

  Offset reflect(Offset p) => p - normal * (2 * sideOf(p));

  /// [reflect] as a transform.
  Matrix4 get reflection {
    final (nx, ny) = (normal.dx, normal.dy);
    final d = 2 * (mid.dx * nx + mid.dy * ny);
    return Matrix4.identity()
      ..setEntry(0, 0, 1 - 2 * nx * nx)
      ..setEntry(0, 1, -2 * nx * ny)
      ..setEntry(1, 0, -2 * nx * ny)
      ..setEntry(1, 1, 1 - 2 * ny * ny)
      ..setTranslationRaw(d * nx, d * ny, 0);
  }

  /// The part of the convex [polygon] that stays [flat], or else the part
  /// that folds over.
  List<Offset> clip(List<Offset> polygon, {required bool flat}) {
    double side(Offset p) => flat ? sideOf(p) : -sideOf(p);
    final kept = <Offset>[];
    for (var i = 0; i < polygon.length; i++) {
      final a = polygon[i];
      final b = polygon[(i + 1) % polygon.length];
      final (sa, sb) = (side(a), side(b));
      if (sa >= 0) kept.add(a);
      if ((sa >= 0) != (sb >= 0)) kept.add(Offset.lerp(a, b, sa / (sa - sb))!);
    }
    return kept;
  }
}

Path _pathOf(List<Offset> polygon) => Path()..addPolygon(polygon, true);

/// Clips to a polygon, or to the whole box when there is none.
class _PolygonClipper extends CustomClipper<Path> {
  final List<Offset>? polygon;

  const _PolygonClipper(this.polygon);

  @override
  Path getClip(Size size) {
    final polygon = this.polygon;
    return polygon == null
        ? (Path()..addRect(Offset.zero & size))
        : _pathOf(polygon);
  }

  @override
  bool shouldReclip(_PolygonClipper old) => old.polygon != polygon;
}

class _FoldShadowPainter extends CustomPainter {
  final _Fold fold;
  final List<Offset> uncovered;
  final List<Offset> flap;
  final double reach;

  /// 0 to 1, how much of the shadows to draw.
  final double strength;
  final Color shadow;

  const _FoldShadowPainter({
    required this.fold,
    required this.uncovered,
    required this.flap,
    required this.reach,
    required this.strength,
    required this.shadow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (uncovered.length > 2) {
      canvas
        ..save()
        ..clipPath(_pathOf(uncovered))
        ..drawRect(
          Offset.zero & size,
          Paint()
            ..shader = ui.Gradient.linear(
              fold.mid,
              fold.mid - fold.normal * reach,
              [
                shadow.withValues(alpha: 0.3 * strength),
                shadow.withValues(alpha: 0),
              ],
            ),
        )
        ..restore();
    }
    if (flap.length > 2) {
      canvas.drawShadow(
        _pathOf(flap),
        shadow,
        _flapElevation * strength,
        false,
      );
    }
  }

  @override
  bool shouldRepaint(_FoldShadowPainter old) => true;
}

class _FlapShadingPainter extends CustomPainter {
  final _Fold fold;
  final List<Offset> flap;
  final double reach;

  /// 0 to 1, how much of the shading to draw.
  final double strength;
  final Color shadow;

  const _FlapShadingPainter({
    required this.fold,
    required this.flap,
    required this.reach,
    required this.strength,
    required this.shadow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (flap.length < 3) return;
    canvas
      ..save()
      ..clipPath(_pathOf(flap))
      ..drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.linear(
            fold.mid,
            fold.mid + fold.normal * reach,
            [
              shadow.withValues(alpha: 0.2 * strength),
              shadow.withValues(alpha: 0),
            ],
          ),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_FlapShadingPainter old) => true;
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
    () =>
        TapGestureRecognizer()
          ..onTapUp = (details) => _openAyah(ayah, details.globalPosition),
  );

  /// Opens the sheet for [ayah], tapped at [position] on the screen.
  Future<void> _openAyah(AyahRef ayah, Offset position) async {
    // A second tap while the sheet opens would stack another one.
    if (_selected != null) return;
    setState(() => _selected = ayah);
    try {
      await showAyahSheet(
        context,
        index: widget.index,
        ayah: ayah,
        translation: widget.translation,
        arabic: ayahSheetCovers(context, position) ? widget.text : null,
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
              child: widget.number <= _openingPages
                  ? _opening(
                      ctx,
                      ayahs,
                      accent: accent,
                      gold: gold,
                      paper: paper,
                    )
                  : Padding(
                      // The inner rule of the double frame.
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(
                            color: gold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: LayoutBuilder(
                            builder: (ctx, box) => _text(
                              ctx,
                              ayahs,
                              box,
                              accent: accent,
                              gold: gold,
                            ),
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

  /// An opening page as printed mushafs illuminate it: a patterned border
  /// and field around the surah's title and a medallion holding the text.
  Widget _opening(
    BuildContext ctx,
    List<AyahRef> ayahs, {
    required Color accent,
    required Color gold,
    required Color paper,
  }) {
    final theme = Theme.of(ctx);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: CustomPaint(
        painter: _IlluminationPainter(gold: gold, accent: accent, paper: paper),
        child: Padding(
          padding: const EdgeInsets.all(_illuminationBorder + AppSpacing.sm),
          child: Column(
            children: [
              _SurahBand(
                surah: widget.index.surah(ayahs.first.surah),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: quranFontFamily,
                  height: _lineHeight,
                ),
                background: paper,
              ),
              if (hasBasmalaHeading(ayahs.first.surah)) ...[
                Text(
                  widget.text.ayah(const AyahRef(1, 1)),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: quranFontFamily,
                    height: _lineHeight,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                // Clear of the medallion's scallops.
                const SizedBox(height: AppSpacing.xs),
              ] else
                const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: CustomPaint(
                  painter: _MedallionPainter(gold: gold, paper: paper),
                  child: Padding(
                    padding: const EdgeInsets.all(_medallionRing),
                    child: LayoutBuilder(
                      builder: (ctx, box) => _shapedText(
                        ctx,
                        ayahs,
                        box.biggest,
                        accent: accent,
                        gold: gold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The page's ayahs in lines that follow the medallion's rounded
  /// rectangle, narrowing at its corners, at the largest size that fits.
  Widget _shapedText(
    BuildContext ctx,
    List<AyahRef> ayahs,
    Size size, {
    required Color accent,
    required Color gold,
  }) {
    final theme = Theme.of(ctx);
    final reading = ref.watch(quranReadingProvider);
    final base = theme.textTheme.bodyLarge!.copyWith(
      fontFamily: quranFontFamily,
      height: _lineHeight,
      color: theme.colorScheme.onSurface,
    );

    final words = <_Word>[];
    final breakAfter = <int>{};
    for (final ayah in ayahs) {
      final mark = '۝${_arabicNumber(ayah.ayah)}';
      if (ayah == const AyahRef(1, 1)) {
        // Al-Fatihah's first ayah, the basmala, has the first line to
        // itself, as in the mushaf.
        words.add(_Word(widget.text.ayah(ayah), ayah: ayah, mark: mark));
        breakAfter.add(words.length - 1);
        continue;
      }
      for (final word in _splitWords(ayahWithoutBasmala(widget.text, ayah))) {
        if (_isWaqf(word) && words.isNotEmpty && words.last.ayah == ayah) {
          // A pause mark stays on the line of the word it follows.
          words.last = words.last.withWaqf(word);
        } else {
          words.add(_Word(word, ayah: ayah));
        }
      }
      words.add(_Word('', ayah: ayah, mark: mark));
    }

    // Widths scale with the text size, so the words are measured once.
    double widthOf(String text) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: base.copyWith(fontSize: _measureSize),
        ),
        textDirection: TextDirection.rtl,
        textScaler: TextScaler.noScaling,
      )..layout();
      final width = painter.width / _measureSize;
      painter.dispose();
      return width;
    }

    final widths = [for (final w in words) widthOf(w.measured)];
    final space = widthOf(' ');
    final shaped = fitTextToRoundedRect(
      widths: widths,
      breakAfter: breakAfter,
      space: space,
      lineHeight: _lineHeight,
      size: size,
      // The text's corners follow the rim's, inside its ring.
      radius: _medallionCorner - _medallionRing / 2,
    );
    if (shaped == null) return const SizedBox.shrink();
    final style = base.copyWith(fontSize: shaped.fontSize);
    final lineHeight = shaped.fontSize * _lineHeight;

    Widget word(_Word w) {
      final ayah = w.ayah;
      final mark = w.mark;
      final text = Text.rich(
        TextSpan(
          children: [
            if (w.text.isNotEmpty)
              TextSpan(
                text: w.text,
                style: ayah == _selected
                    ? TextStyle(backgroundColor: accent.withValues(alpha: 0.16))
                    : null,
              ),
            if (w.waqf case final waqf?) ...[
              const TextSpan(text: ' '),
              _waqfSpan(waqf, style),
            ],
            if (w.text.isNotEmpty && mark != null) const TextSpan(text: ' '),
            if (mark != null)
              TextSpan(
                text: mark,
                style: TextStyle(
                  color: reading.isBookmarked(ayah) ? accent : gold,
                ),
              ),
          ],
        ),
        maxLines: 1,
        softWrap: false,
        textDirection: TextDirection.rtl,
        textScaler: TextScaler.noScaling,
        style: style,
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _openAyah(ayah, details.globalPosition),
        child: text,
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in shaped.lines)
            SizedBox(
              height: lineHeight,
              width: row.width,
              child: row.start == row.end
                  ? null
                  : Row(
                      textDirection: TextDirection.rtl,
                      mainAxisAlignment: row.justified
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.center,
                      spacing: row.justified ? 0 : space * shaped.fontSize,
                      children: [
                        for (final w in words.sublist(row.start, row.end))
                          word(w),
                      ],
                    ),
            ),
        ],
      ),
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
      // Runs of words between pause marks, each taking taps itself, since a
      // span's recognizer doesn't reach its children.
      final parts = <InlineSpan>[];
      var run = StringBuffer();
      void endRun() {
        if (run.isEmpty) return;
        parts.add(TextSpan(text: '$run', recognizer: recognizer));
        run = StringBuffer();
      }

      for (final word in _splitWords(ayahWithoutBasmala(widget.text, ayah))) {
        if (_isWaqf(word)) {
          endRun();
          parts.add(_waqfSpan(word, style!));
          run.write(' ');
        } else {
          run.write('$word ');
        }
      }
      endRun();
      spans
        ..add(
          TextSpan(
            children: parts,
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

  /// What the band covers, so a patterned page doesn't show through it.
  final Color? background;

  const _SurahBand({required this.surah, required this.style, this.background});

  @override
  Widget build(BuildContext ctx) {
    final gold = Theme.of(ctx).colorScheme.tertiary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: background == null
            ? gold.withValues(alpha: 0.12)
            : Color.alphaBlend(gold.withValues(alpha: 0.12), background!),
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

/// The pages printed mushafs illuminate: Al-Fatihah and the start of
/// Al-Baqarah.
const _openingPages = 2;

/// Width of the opening pages' patterned border.
const _illuminationBorder = 14.0;

/// Corner radius of the opening pages' border: an arc around each corner's
/// star, so the star sits inside the rule.
const _illuminationCorner = _illuminationBorder / 2;

/// Room around the medallion's text for its scalloped rim.
const _medallionRing = 18.0;

/// Corner radius of the medallion's rim, measured along the scallops'
/// centers.
const _medallionCorner = AppRadii.xl + _medallionRing;

/// Spacing of the star pattern on the opening pages' field.
const _starTile = 28.0;

/// The size words are measured at; their widths scale from it.
const _measureSize = 100.0;

/// How full a line has to be before its words spread across it.
const _justifyFill = 0.75;

/// Below this the opening text would be unreadable.
const _minOpeningFontSize = 6.0;

/// Lines fill a little less than the medallion's width, so rounding in the
/// measured widths never overflows them.
const _fitSlack = 0.97;

/// A word on an opening page, or words kept on one line, followed by
/// [mark], an ayah-end sign, if the ayah ends there.
class _Word {
  final String text;

  /// The ayah tapping the word opens.
  final AyahRef ayah;

  final String? mark;

  /// A pause mark after the word.
  final String? waqf;

  const _Word(this.text, {required this.ayah, this.mark, this.waqf});

  _Word withWaqf(String waqf) =>
      _Word(text, ayah: ayah, mark: mark, waqf: waqf);

  /// What takes up the word's room on its line.
  String get measured => [
    text,
    if (waqf != null) '$_waqfBase$waqf',
    ?mark,
  ].where((t) => t.isNotEmpty).join(' ');
}

/// Whether [word] is only a pause mark (waqf sign), which Tanzil's text
/// sets apart between spaces.
bool _isWaqf(String word) =>
    word.isNotEmpty && word.runes.every((c) => c >= 0x06D6 && c <= 0x06DC);

/// What a pause mark sits on: alone, the font would draw nothing.
const _waqfBase = '\u00A0';

/// How far a pause mark is lowered, in text heights. Over a space the font
/// raises it to clear the tallest letters, about a line above the words; in
/// a mushaf it sits just above them.
const _waqfDrop = 0.55;

/// A pause mark [waqf] lowered to sit just above the words around it.
InlineSpan _waqfSpan(String waqf, TextStyle style) => WidgetSpan(
  alignment: PlaceholderAlignment.baseline,
  baseline: TextBaseline.alphabetic,
  child: Transform.translate(
    offset: Offset(0, style.fontSize! * _waqfDrop),
    child: Text(
      '$_waqfBase$waqf',
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.noScaling,
      style: style.copyWith(backgroundColor: Colors.transparent),
    ),
  ),
);

Iterable<String> _splitWords(String text) =>
    text.split(' ').where((w) => w.isNotEmpty);

/// A line of an opening page: the words from [start] up to [end], centered in
/// [width] or, when it nearly fills it, spread across it.
typedef ShapedLine = ({int start, int end, double width, bool justified});

/// Lays out words of [widths] (at a text size of 1, separated by [space])
/// in lines whose length follows a rectangle filling [size] with corners
/// rounded by [radius], at the largest text size where they all fit. A word
/// whose index is in [breakAfter] ends its line.
/// Lines too short for the next word, in the top corners, stay empty.
/// Null when not even the smallest size fits.
({double fontSize, List<ShapedLine> lines})? fitTextToRoundedRect({
  required List<double> widths,
  Set<int> breakAfter = const {},
  required double space,
  required double lineHeight,
  required Size size,
  required double radius,
}) {
  final r = min(radius, min(size.width, size.height) / 2);
  List<ShapedLine>? fill(double fontSize) {
    final height = fontSize * lineHeight;
    final count = (size.height / height).floor();
    final top = (size.height - count * height) / 2;
    final b = size.height / 2;
    final lines = <ShapedLine>[];
    var next = 0;
    for (var i = 0; i < count; i++) {
      // The line's narrower edge, the one further from the middle, has to
      // stay inside the rounded corners.
      final above = top + i * height - b;
      final dy = max(above.abs(), (above + height).abs());
      final into = dy - (b - r);
      final chord = into <= 0
          ? size.width
          : into >= r
          ? 0.0
          : size.width - 2 * (r - sqrt(r * r - into * into));
      final start = next;
      var used = 0.0;
      var words = 0;
      var broken = false;
      while (next < widths.length) {
        final width = widths[next] * fontSize;
        final total = words == 0 ? width : used + space * fontSize + width;
        if (total > chord * _fitSlack) break;
        used = total;
        words++;
        next++;
        if (breakAfter.contains(next - 1)) {
          broken = true;
          break;
        }
      }
      lines.add((
        start: start,
        end: next,
        width: chord,
        // The last line, and any too short to spread without gaps, stay
        // centered.
        justified:
            !broken &&
            next < widths.length &&
            words > 1 &&
            used >= chord * _justifyFill,
      ));
    }
    return next == widths.length ? lines : null;
  }

  var low = _minOpeningFontSize;
  var high = size.height / lineHeight;
  if (fill(low) == null) return null;
  for (var i = 0; i < 16; i++) {
    final mid = (low + high) / 2;
    if (fill(mid) != null) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return (fontSize: low, lines: fill(low)!);
}

/// An eight-pointed star of radius [r] around [c].
Path _star(Offset c, double r) {
  final path = Path();
  for (var i = 0; i < 16; i++) {
    final radius = i.isEven ? r : r * 0.55;
    final angle = i * pi / 8 - pi / 2;
    final point = c + Offset(cos(angle), sin(angle)) * radius;
    i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
  }
  return path..close();
}

Path _diamond(Offset c, double r) => Path()
  ..moveTo(c.dx, c.dy - r)
  ..lineTo(c.dx + r, c.dy)
  ..lineTo(c.dx, c.dy + r)
  ..lineTo(c.dx - r, c.dy)
  ..close();

/// The opening pages' border of gold lozenges on the accent, with stars at
/// the corners, around a field patterned with stars.
class _IlluminationPainter extends CustomPainter {
  final Color gold;
  final Color accent;
  final Color paper;

  const _IlluminationPainter({
    required this.gold,
    required this.accent,
    required this.paper,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final field = rect.deflate(_illuminationBorder);
    canvas
      ..save()
      ..clipRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(_illuminationCorner),
        ),
      )
      ..drawRect(
        rect,
        Paint()
          ..color = Color.alphaBlend(accent.withValues(alpha: 0.06), paper),
      );

    // Stars on a grid centered on the field, with a dot between each four.
    final starPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = gold.withValues(alpha: 0.35);
    final dotPaint = Paint()..color = gold.withValues(alpha: 0.35);
    final x0 =
        field.center.dx - (field.width / 2 / _starTile).ceil() * _starTile;
    final y0 =
        field.center.dy - (field.height / 2 / _starTile).ceil() * _starTile;
    canvas
      ..save()
      ..clipRect(field);
    for (var y = y0; y <= field.bottom; y += _starTile) {
      for (var x = x0; x <= field.right; x += _starTile) {
        canvas
          ..drawPath(_star(Offset(x, y), _starTile * 0.4), starPaint)
          ..drawCircle(
            Offset(x + _starTile / 2, y + _starTile / 2),
            _starTile / 18,
            dotPaint,
          );
      }
    }
    canvas
      ..restore()
      ..drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(rect)
          ..addRect(field),
        Paint()
          ..color = Color.alphaBlend(accent.withValues(alpha: 0.22), paper),
      );

    // Lozenges along the middle of the border, stars at its corners.
    const half = _illuminationBorder / 2;
    final middle = rect.deflate(half);
    final goldPaint = Paint()..color = gold.withValues(alpha: 0.75);
    final corners = [
      middle.topLeft,
      middle.topRight,
      middle.bottomRight,
      middle.bottomLeft,
    ];
    for (var i = 0; i < 4; i++) {
      final from = corners[i];
      final to = corners[(i + 1) % 4];
      final count = max(
        1,
        ((to - from).distance / _illuminationBorder).round(),
      );
      for (var j = 1; j < count; j++) {
        canvas.drawPath(
          _diamond(Offset.lerp(from, to, j / count)!, half * 0.55),
          goldPaint,
        );
      }
      canvas.drawPath(_star(from, half * 0.75), goldPaint);
    }

    final rule = Paint()
      ..style = PaintingStyle.stroke
      ..color = gold.withValues(alpha: 0.8);
    canvas
      ..drawRect(field, rule)
      ..drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(1),
          const Radius.circular(_illuminationCorner - 1),
        ),
        rule..strokeWidth = 1.5,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_IlluminationPainter old) =>
      old.gold != gold || old.accent != accent || old.paper != paper;
}

/// The plain rounded rectangle holding an opening page's text, with a
/// scalloped gold rim.
class _MedallionPainter extends CustomPainter {
  final Color gold;
  final Color paper;

  const _MedallionPainter({required this.gold, required this.paper});

  @override
  void paint(Canvas canvas, Size size) {
    final panel = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(_medallionRing / 2),
      const Radius.circular(_medallionCorner),
    );
    final outline = (Path()..addRRect(panel)).computeMetrics().single;
    final count = (outline.length / (_medallionRing * 0.9)).floor();
    const radius = _medallionRing * 0.45;
    final fill = Paint()
      ..color = Color.alphaBlend(gold.withValues(alpha: 0.3), paper);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..color = gold.withValues(alpha: 0.8);
    for (var i = 0; i < count; i++) {
      final c = outline
          .getTangentForOffset(outline.length * i / count)!
          .position;
      canvas
        ..drawCircle(c, radius, fill)
        ..drawCircle(c, radius, rim);
    }
    canvas
      ..drawRRect(panel, Paint()..color = paper)
      ..drawRRect(panel, rim..strokeWidth = 1.5)
      ..drawRRect(
        panel.deflate(AppSpacing.xs),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = gold.withValues(alpha: 0.5),
      );
  }

  @override
  bool shouldRepaint(_MedallionPainter old) =>
      old.gold != gold || old.paper != paper;
}
