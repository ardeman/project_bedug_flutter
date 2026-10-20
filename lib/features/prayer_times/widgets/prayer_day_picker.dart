import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/design/glass_controls.dart';
import '../../../core/design/platform_capabilities.dart';
import '../../../core/services/selection_feedback.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'hijri_month_grid.dart';

/// Picks the day the prayer cards below show: an endless strip of dates (past
/// and future) and the picked date, with a button back to today. Lite glass
/// on Apple (it scrolls with the list), the theme's flat card elsewhere.
///
/// The strip builds only the chips on screen, so its length costs nothing.
/// Scrolling it picks the date that crosses the middle, with a selection
/// tick for each one (haptic, or a click sound on devices without haptics),
/// and it settles with that chip centered.
///
/// The picked date shows with its Hijri date. A calendar button, or pulling
/// the handle at the bottom down, turns the strip into a Hijri month grid,
/// which picks days too; pushing it back up turns it back.
class PrayerDayPicker extends StatefulWidget {
  /// Today's date; the strip starts with it centered.
  final DateTime today;

  /// The picked date (time of day ignored).
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  const PrayerDayPicker({
    super.key,
    required this.today,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<PrayerDayPicker> createState() => _PrayerDayPickerState();
}

class _PrayerDayPickerState extends State<PrayerDayPicker>
    with SingleTickerProviderStateMixin {
  late final _strip = ScrollController(
    initialScrollOffset: _DateStrip.scrollOffsetToCenter(_selectedOffset),
  );

  int get _selectedOffset => daysBetween(widget.today, widget.selected);

  /// True from the start of a user drag until the strip settles, including
  /// the fling and snap after it. Programmatic scrolls (centering a tapped
  /// chip) leave it false, so they don't pick the dates they pass.
  bool _isUserScrolling = false;

  /// The last day offset this picker reported, so a scroll that crosses the
  /// middle several times within a frame picks (and ticks) once.
  int? _lastPicked;

  /// How far the Hijri month grid is open, from 0 (closed) to 1. Follows the
  /// finger while the handle is dragged.
  late final _calendar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..addStatusListener((_) => setState(() {}));

  /// Where the grid is headed: open, or closed.
  bool _isCalendarOpen = false;
  bool _isDraggingCalendar = false;
  final _gridKey = GlobalKey<HijriMonthGridState>();

  /// Whether the open grid shows a month other than the picked day's.
  bool _isGridPagedAway = false;

  /// The grid's height before its first layout: the month header, weekday
  /// row and five weeks of day cells.
  static const _gridHeightEstimate = 320.0;

  /// A fling faster than this (logical px/s) opens or closes the grid
  /// whatever its position.
  static const _flingVelocity = 300.0;

  double get _gridHeight {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    return box != null && box.hasSize && box.size.height > 0
        ? box.size.height
        : _gridHeightEstimate;
  }

  void _setCalendarOpen(bool open) {
    // A reopened grid starts on the picked day's month.
    setState(() {
      _isCalendarOpen = open;
      _isGridPagedAway = false;
    });
    // animateBack, so a closed grid ends dismissed (and is dropped).
    open
        ? _calendar.animateTo(1, curve: Curves.easeOutCubic)
        : _calendar.animateBack(0, curve: Curves.easeOutCubic);
  }

  void _onCalendarDragStart(DragStartDetails _) {
    _calendar.stop();
    setState(() => _isDraggingCalendar = true);
  }

  /// The finger moves the card's bottom edge, which travels the difference
  /// between the grid's height and the strip's.
  void _onCalendarDragUpdate(DragUpdateDetails d) =>
      _calendar.value += d.primaryDelta! / (_gridHeight - _DateStrip._height);

  void _onCalendarDragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    setState(() => _isDraggingCalendar = false);
    _setCalendarOpen(
        velocity.abs() > _flingVelocity ? velocity > 0 : _calendar.value > 0.5);
  }

  /// Lets [child] pull the grid open (down) and push it closed (up).
  /// The calendar button opens it for screen readers.
  Widget _calendarDragArea({required Widget child}) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onVerticalDragStart: _onCalendarDragStart,
        onVerticalDragUpdate: _onCalendarDragUpdate,
        onVerticalDragEnd: _onCalendarDragEnd,
        onVerticalDragCancel: () => _onCalendarDragEnd(DragEndDetails()),
        child: child,
      );

  /// The strip's scroll offset, or where it starts before its first layout.
  double get _stripPixels => _strip.hasClients
      ? _strip.offset
      : _DateStrip.scrollOffsetToCenter(_selectedOffset);

  void _pick(int offset) {
    if (offset == (_lastPicked ?? _selectedOffset)) return;
    // A picked day brings its month into the grid.
    _isGridPagedAway = false;
    _lastPicked = offset;
    SelectionFeedback.tick();
    widget.onSelected(addDays(widget.today, offset));
  }

  /// Picks today, or, with today already picked, pages the grid back to
  /// its month.
  void _goToToday() {
    if (_selectedOffset == 0) {
      _gridKey.currentState?.showSelectedMonth();
    } else {
      _pick(0);
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    if (n is ScrollStartNotification) {
      _isUserScrolling = n.dragDetails != null;
    } else if (n is ScrollUpdateNotification && _isUserScrolling) {
      _pick(_DateStrip.offsetAt(n.metrics.pixels));
    } else if (n is ScrollEndNotification) {
      _isUserScrolling = false;
    }
    return false;
  }

  @override
  void didUpdateWidget(PrayerDayPicker old) {
    super.didUpdateWidget(old);
    _lastPicked = null;
    if (daysBetween(old.selected, widget.selected) != 0) {
      _isGridPagedAway = false;
    }
    // Center the picked chip, whether it was tapped or picked from outside
    // (the "Today" button, a reload on a new day). While the user scrolls,
    // the strip snaps to it by itself.
    final moved = daysBetween(old.today, old.selected) != _selectedOffset;
    if (moved && !_isUserScrolling && _strip.hasClients) {
      _strip.animateTo(
        _DateStrip.scrollOffsetToCenter(_selectedOffset),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _calendar.dispose();
    _strip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(ctx);
    final isLandscape = mq.orientation == Orientation.landscape;
    final sideInsetLeft = isLandscape ? mq.padding.left : 0.0;
    final sideInsetRight = isLandscape ? mq.padding.right : 0.0;
    final locale = Localizations.localeOf(ctx).toLanguageTag();
    final offset = _selectedOffset;
    final showToday = offset != 0 || (_isCalendarOpen && _isGridPagedAway);
    // Name the year only when it isn't this one.
    final dateFormat = widget.selected.year == widget.today.year
        ? DateFormat.MMMMEEEEd(locale)
        : DateFormat.yMMMMEEEEd(locale);
    final hijriDate = hijriDateLabel(l10n, widget.selected);

    final content = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StripToGrid(
            progress: _calendar,
            gridHeight: () => _gridHeight,
            strip: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: _DateStrip(
                controller: _strip,
                today: widget.today,
                selected: offset,
                locale: locale,
                onSelected: _pick,
              ),
            ),
            // The grid is built while it is open, opening or dragged, and
            // dropped once fully closed.
            grid: _isDraggingCalendar || !_calendar.isDismissed
                ? HijriMonthGrid(
                    key: _gridKey,
                    today: widget.today,
                    selected: widget.selected,
                    onSelected: (date) =>
                        _pick(daysBetween(widget.today, date)),
                    onPagedAway: (away) =>
                        setState(() => _isGridPagedAway = away),
                    morph: HijriGridMorph(
                      progress: _calendar,
                      stripDates: (width) => [
                        for (final o
                            in _DateStrip.offsetsOnScreen(width, _stripPixels))
                          addDays(widget.today, o),
                      ],
                      stripRectOf: (date, width) => _DateStrip.chipRect(
                          daysBetween(widget.today, date), width, _stripPixels),
                      stripLabelOf: (date) {
                        final o = daysBetween(widget.today, date);
                        return _DateChipLabel(
                          date: date,
                          locale: locale,
                          isSelected: o == offset,
                          isToday: o == 0,
                          showMonth: _DateStrip.showsMonth(o, date),
                        );
                      },
                      stripRadius: AppRadii.md,
                    ),
                  )
                : null,
          ),
          _calendarDragArea(
            // At least a button tall, so the "Today" button appearing
            // doesn't resize the card.
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(minHeight: kMinInteractiveDimension),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.md, end: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dateFormat.format(widget.selected),
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hijriDate != null)
                            Text(
                              hijriDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (showToday && PlatformCapabilities.isApple)
                      GlassPillButton(
                        icon: Icons.today,
                        label: l10n.today,
                        onPressed: _goToToday,
                      )
                    else if (showToday)
                      TextButton.icon(
                        onPressed: _goToToday,
                        icon: const Icon(Icons.today, size: 18),
                        label: Text(l10n.today),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.accentOf(ctx)),
                      ),
                    _CalendarToggle(
                      isOpen: _isCalendarOpen,
                      label: l10n.hijriCalendar,
                      onPressed: () => _setCalendarOpen(!_isCalendarOpen),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _calendarDragArea(
            child: _DragHandle(
              onTap: () => _setCalendarOpen(!_isCalendarOpen),
            ),
          ),
        ],
      ),
    );

    final card = PlatformCapabilities.isApple
        ? Material(
            color: Colors.transparent,
            child: LiquidGlassLite(
              shape: const LiquidGlassShape.continuousRoundedRectangle(
                  cornerRadius: AppRadii.lg),
              blur: 10,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.62),
              child: content,
            ),
          )
        : DecoratedBox(
            decoration: ShapeDecoration(
              color: theme.cardTheme.color ?? theme.cardColor,
              shape: theme.cardTheme.shape ??
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.lg)),
            ),
            child: Material(color: Colors.transparent, child: content),
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md + sideInsetLeft,
        0,
        AppSpacing.md + sideInsetRight,
        AppSpacing.xs,
      ),
      child: card,
    );
  }
}

/// Opens and closes the Hijri month grid: a press-highlighted icon on Apple,
/// an [IconButton] elsewhere.
class _CalendarToggle extends StatelessWidget {
  final bool isOpen;
  final String label;
  final VoidCallback onPressed;
  const _CalendarToggle({
    required this.isOpen,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext ctx) {
    final color = isOpen
        ? AppColors.accentOf(ctx)
        : Theme.of(ctx).colorScheme.onSurfaceVariant;
    final icon = Icon(
      isOpen ? Icons.calendar_month : Icons.calendar_month_outlined,
      color: color,
    );
    if (!PlatformCapabilities.isApple) {
      return IconButton(
        icon: icon,
        tooltip: label,
        isSelected: isOpen,
        onPressed: onPressed,
      );
    }
    return Semantics(
      button: true,
      expanded: isOpen,
      label: label,
      excludeSemantics: true,
      child: GlassPressable(
        borderRadius: BorderRadius.circular(kMinInteractiveDimension / 2),
        onTap: onPressed,
        child:
            SizedBox.square(dimension: kMinInteractiveDimension, child: icon),
      ),
    );
  }
}

/// The date strip turning into the Hijri month grid in the same place: the
/// slot's height moves from the strip's to the grid's with [progress], and
/// the grid draws the dates moving from their chips to their cells (see
/// [HijriGridMorph]), so the strip hides as soon as the grid starts to open.
/// Only the side more than half shown takes taps and is read by screen
/// readers.
class _StripToGrid extends StatelessWidget {
  final Animation<double> progress;
  final double Function() gridHeight;
  final Widget strip;
  final Widget? grid;
  const _StripToGrid({
    required this.progress,
    required this.gridHeight,
    required this.strip,
    required this.grid,
  });

  /// Lays [child] out at its own height, whatever the slot's height.
  static Widget _natural(Widget child) => OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: child,
      );

  @override
  Widget build(BuildContext ctx) => AnimatedBuilder(
        animation: progress,
        builder: (ctx, _) {
          final t = progress.value;
          final isGridShown = t >= 0.5;
          final isMorphing = grid != null && t > 0;
          return ClipRect(
            child: SizedBox(
              height: lerpDouble(_DateStrip._height, gridHeight(), t),
              child: Stack(
                children: [
                  // Kept (hidden) while the grid is open, so its scroll
                  // position survives.
                  _natural(IgnorePointer(
                    ignoring: isGridShown,
                    child: ExcludeSemantics(
                      excluding: isGridShown,
                      child: Opacity(opacity: isMorphing ? 0 : 1, child: strip),
                    ),
                  )),
                  if (grid case final grid?)
                    _natural(IgnorePointer(
                      ignoring: !isGridShown,
                      child: ExcludeSemantics(
                        excluding: !isGridShown,
                        child:
                            Opacity(opacity: isMorphing ? 1 : 0, child: grid),
                      ),
                    )),
                ],
              ),
            ),
          );
        },
      );
}

/// The grab bar under the date: pulled down it opens the Hijri month grid,
/// pushed up it closes it, and a tap toggles it. The calendar button carries
/// the same action for screen readers, so the bar is left out of semantics.
class _DragHandle extends StatelessWidget {
  final VoidCallback onTap;
  const _DragHandle({required this.onTap});

  // The usual sheet grab bar size.
  static const _barWidth = 36.0;
  static const _barHeight = 4.0;

  @override
  Widget build(BuildContext ctx) => ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(
                top: AppSpacing.xxs, bottom: AppSpacing.xs),
            child: Center(
              child: Container(
                width: _barWidth,
                height: _barHeight,
                decoration: BoxDecoration(
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(_barHeight / 2),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Whole calendar days from [from] to [to], ignoring the time of day and DST.
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
      to.year,
      to.month,
      to.day,
    ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// [date]'s calendar day moved by [days], at midnight. Calendar arithmetic,
/// so a DST change can't skip or repeat a date.
DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

// ── Date strip ────────────────────────────────────────────────────────────────
// An endless, lazily built row of day chips in both directions. The picked
// chip scrolls to the center, and the ends fade out instead of cutting a chip
// off at the card's edge.
class _DateStrip extends StatelessWidget {
  final ScrollController controller;
  final DateTime today;
  final int selected;
  final String locale;
  final ValueChanged<int> onSelected;
  const _DateStrip({
    required this.controller,
    required this.today,
    required this.selected,
    required this.locale,
    required this.onSelected,
  });

  static const _chipWidth = 56.0;
  static const _gap = AppSpacing.xs;
  static const _extent = _chipWidth + _gap;
  // Weekday, day number and month line, plus the chip's vertical padding.
  static const _height = 76.0;
  static const _centerKey = ValueKey('today');

  /// The scroll offset that centers the chip [offset] days from today. With
  /// the center sliver anchored mid-viewport, offset 0 puts today's chip's
  /// leading edge in the middle, so add half a chip.
  static double scrollOffsetToCenter(int offset) =>
      offset * _extent + _extent / 2;

  /// The day offset of the chip under the middle at scroll [pixels].
  static int offsetAt(double pixels) => (pixels / _extent).floor();

  /// Where the chip [offset] days from today sits in a strip [width] wide at
  /// scroll [pixels], on screen or not.
  static Rect chipRect(int offset, double width, double pixels) =>
      Rect.fromLTWH(width / 2 + offset * _extent - pixels + _gap / 2, 0,
          _chipWidth, _height);

  /// The day offsets with a chip at least partly on screen.
  static Iterable<int> offsetsOnScreen(double width, double pixels) sync* {
    final first = ((pixels - width / 2) / _extent).floor();
    final last = ((pixels + width / 2) / _extent).floor();
    for (var o = first; o <= last; o++) {
      yield o;
    }
  }

  /// Whether the chip names its month: today's, and each month's first day.
  static bool showsMonth(int offset, DateTime date) =>
      offset == 0 || date.day == 1;

  @override
  Widget build(BuildContext ctx) {
    Widget chip(int offset) {
      final date = addDays(today, offset);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _gap / 2),
        child: _DateChip(
          date: date,
          locale: locale,
          isSelected: offset == selected,
          isToday: offset == 0,
          showMonth: showsMonth(offset, date),
          onTap: () => onSelected(offset),
        ),
      );
    }

    return SizedBox(
      height: _height,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          // Fade the outer 6% on each side.
          stops: [0, 0.06, 0.94, 1],
        ).createShader(rect),
        child: CustomScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          center: _centerKey,
          anchor: 0.5,
          physics: const _CenterChipSnapPhysics(),
          slivers: [
            // Before the center sliver, items grow away from it: index 0 is
            // yesterday.
            SliverFixedExtentList(
              itemExtent: _extent,
              delegate: SliverChildBuilderDelegate((_, i) => chip(-(i + 1))),
            ),
            SliverFixedExtentList(
              key: _centerKey,
              itemExtent: _extent,
              delegate: SliverChildBuilderDelegate((_, i) => chip(i)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final String locale;
  final bool isSelected;
  final bool isToday;
  final bool showMonth;
  final VoidCallback onTap;
  const _DateChip({
    required this.date,
    required this.locale,
    required this.isSelected,
    required this.isToday,
    required this.showMonth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext ctx) {
    final accent = AppColors.accentOf(ctx);
    final radius = BorderRadius.circular(AppRadii.md);

    return Semantics(
      selected: isSelected,
      button: true,
      label: DateFormat.yMMMMEEEEd(locale).format(date),
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: radius,
          border: Border.all(
            color: isSelected || !isToday
                ? Colors.transparent
                : accent.withValues(alpha: 0.6),
          ),
        ),
        child: _ChipTapTarget(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            // Scale down rather than clip at large text sizes.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _DateChipLabel(
                date: date,
                locale: locale,
                isSelected: isSelected,
                isToday: isToday,
                showMonth: showMonth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A chip's weekday, day number and (on its first line) month.
class _DateChipLabel extends StatelessWidget {
  final DateTime date;
  final String locale;
  final bool isSelected;
  final bool isToday;
  final bool showMonth;
  const _DateChipLabel({
    required this.date,
    required this.locale,
    required this.isSelected,
    required this.isToday,
    required this.showMonth,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final onAccent = theme.colorScheme.onPrimary;
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat.E(locale).format(date),
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected ? onAccent : muted,
          ),
        ),
        Text(
          DateFormat.d(locale).format(date),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isSelected
                ? onAccent
                : (isToday
                    ? AppColors.accentOf(ctx)
                    : theme.colorScheme.onSurface),
          ),
        ),
        Text(
          // Keep the line so every chip has the same height.
          showMonth ? DateFormat.MMM(locale).format(date) : ' ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected ? onAccent : muted,
          ),
        ),
      ],
    );
  }
}

/// Ink ripple on Material, a press highlight on iOS and macOS.
class _ChipTapTarget extends StatelessWidget {
  final BorderRadius borderRadius;
  final VoidCallback onTap;
  final Widget child;
  const _ChipTapTarget({
    required this.borderRadius,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext ctx) => PlatformCapabilities.isApple
      ? GlassPressable(borderRadius: borderRadius, onTap: onTap, child: child)
      : InkWell(borderRadius: borderRadius, onTap: onTap, child: child);
}

/// Ends every drag and fling with a chip centered: the one the fling would
/// have stopped on. Keeps the platform's drag feel (bounce on Apple).
class _CenterChipSnapPhysics extends ScrollPhysics {
  const _CenterChipSnapPhysics({super.parent});

  @override
  _CenterChipSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _CenterChipSnapPhysics(parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final tolerance = toleranceFor(position);
    // Where a plain fling would come to rest (0.135 is Flutter's own
    // scroll friction drag).
    final rest = FrictionSimulation(0.135, position.pixels, velocity).finalX;
    final target = _DateStrip.scrollOffsetToCenter(_DateStrip.offsetAt(rest));
    if ((target - position.pixels).abs() < tolerance.distance &&
        velocity.abs() < tolerance.velocity) {
      return null;
    }
    return ScrollSpringSimulation(spring, position.pixels, target, velocity,
        tolerance: tolerance);
  }
}
