import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

import '../../../core/design/material_controls.dart';

import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/constants/app_colors.dart';
import '../../../core/design/glass_controls.dart';
import '../../../core/design/platform_capabilities.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/hijri_utils.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../hijri_events/hijri_events.dart';

/// A Hijri month, a week to a row, with each day's Gregorian date under its
/// Hijri day. Opens on the month of [selected], follows it when it changes,
/// and tapping a day picks its Gregorian date.
///
/// With a [morph], the grid grows out of the date strip as it opens: each
/// strip chip slides to its cell, the other weeks unfold from the strip's
/// row, and the month header fades in.
class HijriMonthGrid extends StatefulWidget {
  final DateTime today;
  final DateTime selected;

  /// Event days get a dot and the events' names in their label.
  final HijriEvents? events;
  final ValueChanged<DateTime> onSelected;
  final HijriGridMorph? morph;

  /// How the Hijri dates are reckoned.
  final HijriReckoning hijriReckoning;

  /// Called with true when paging leaves the picked day's month, and with
  /// false when [HijriMonthGridState.showSelectedMonth] brings it back. A
  /// newly picked day brings its month back without a call.
  final ValueChanged<bool>? onPagedAway;

  const HijriMonthGrid({
    super.key,
    required this.today,
    required this.selected,
    this.events,
    required this.onSelected,
    this.morph,
    this.onPagedAway,
    this.hijriReckoning = const HijriReckoning(),
  });

  @override
  State<HijriMonthGrid> createState() => HijriMonthGridState();
}

/// Where the date strip the grid grows out of shows its chips. The grid
/// shares the strip's top-left corner and width.
class HijriGridMorph {
  /// From 0 (the strip) to 1 (the grid).
  final Animation<double> progress;

  /// The dates with a chip on screen in a strip [width] wide.
  final Iterable<DateTime> Function(double width) stripDates;

  /// Where [date]'s chip sits in a strip [width] wide, on screen or not.
  final Rect Function(DateTime date, double width) stripRectOf;

  /// What [date]'s chip shows on top of its background.
  final Widget Function(DateTime date) stripLabelOf;

  /// The strip chips' corner radius.
  final double stripRadius;

  const HijriGridMorph({
    required this.progress,
    required this.stripDates,
    required this.stripRectOf,
    required this.stripLabelOf,
    required this.stripRadius,
  });
}

/// The Umm al-Qura table in the `hijri` package covers 1356 AH (1937) to
/// 1500 AH (2077); dates outside it throw. 1500's last month is left out
/// because the table ends partway through it.
const _firstYear = 1356;
const _lastYear = 1499;

/// The Hijri (year, month) holding [date], clamped to the supported range.
({int year, int month}) hijriMonthOf(
  DateTime date, [
  HijriReckoning reckoning = const HijriReckoning(),
]) {
  try {
    final h = hijriOf(date, reckoning);
    if (h.hYear > _lastYear) return (year: _lastYear, month: 12);
    return (year: h.hYear, month: h.hMonth);
  } on ArgumentError {
    return date.year < 2000
        ? (year: _firstYear, month: 1)
        : (year: _lastYear, month: 12);
  }
}

/// [date] as a Hijri date ("8 Jumada al-Ula 1448 H") under [reckoning], or
/// null outside the Umm al-Qura table.
String? hijriDateLabel(
  AppLocalizations l10n,
  DateTime date, [
  HijriReckoning reckoning = const HijriReckoning(),
]) {
  try {
    final h = hijriOf(date, reckoning);
    return '${h.hDay} ${hijriMonthName(l10n, h.hMonth)} ${h.hYear} H';
  } on ArgumentError {
    return null;
  }
}

class HijriMonthGridState extends State<HijriMonthGrid>
    with SingleTickerProviderStateMixin {
  late var _view = _monthOf(widget.selected);

  ({int year, int month}) _monthOf(DateTime date) =>
      hijriMonthOf(date, widget.hijriReckoning);

  bool get _hasPrev => _view.year > _firstYear || _view.month > 1;
  bool get _hasNext => _view.year < _lastYear || _view.month < 12;

  void _prev() => _show(
    _view.month == 1
        ? (year: _view.year - 1, month: 12)
        : (year: _view.year, month: _view.month - 1),
  );

  void _next() => _show(
    _view.month == 12
        ? (year: _view.year + 1, month: 1)
        : (year: _view.year, month: _view.month + 1),
  );

  /// How far the days are dragged sideways, in logical pixels.
  late final _swipe = AnimationController.unbounded(vsync: this);

  /// Width of the days, measured while they are laid out.
  double _swipeWidth = 1;

  /// A fling faster than this pages, however short the drag, in logical
  /// pixels per second.
  static const _flingVelocity = 700.0;

  /// The paging duration of a swipe.
  static const _swipeDuration = Duration(milliseconds: 260);

  @override
  void dispose() {
    _swipe.dispose();
    super.dispose();
  }

  /// Whether dragging by [dx] heads for the next month. Months run with the
  /// reading direction: dragging the days leftward reveals the next month
  /// in left-to-right languages and the previous one in Arabic.
  bool _isForward(double dx) =>
      (Directionality.of(context) == TextDirection.rtl) == (dx > 0);

  void _onSwipeUpdate(DragUpdateDetails details) {
    _swipe.stop();
    final delta = details.primaryDelta ?? 0;
    final dx = _swipe.value + delta;
    final canPage = dx == 0 || (_isForward(dx) ? _hasNext : _hasPrev);
    // Past the first or last month the days only give a little.
    _swipe.value = canPage ? dx : _swipe.value + delta / 4;
  }

  Future<void> _onSwipeEnd(DragEndDetails details) async {
    final dx = _swipe.value;
    final velocity = details.primaryVelocity ?? 0;
    final forward = _isForward(dx);
    final flung = velocity.abs() > _flingVelocity && (velocity > 0) == (dx > 0);
    final pages =
        dx != 0 &&
        (dx.abs() > _swipeWidth / 4 || flung) &&
        (forward ? _hasNext : _hasPrev);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!pages) {
      if (reduceMotion) {
        _swipe.value = 0;
      } else {
        await _swipe.animateTo(
          0,
          duration: _swipeDuration,
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }
    forward ? _next() : _prev();
    if (reduceMotion) {
      _swipe.value = 0;
      return;
    }
    // The new month comes in from the side the drag came from.
    _swipe.value = -dx.sign * _swipeWidth / 3;
    await _swipe.animateTo(
      0,
      duration: _swipeDuration,
      curve: Curves.easeOutCubic,
    );
  }

  /// [days] following a sideways drag, fading as they leave.
  Widget _swipeable(Widget days) => LayoutBuilder(
    builder: (ctx, constraints) {
      _swipeWidth = constraints.maxWidth;
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: _onSwipeUpdate,
        onHorizontalDragEnd: _onSwipeEnd,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _swipe,
            builder: (ctx, child) => Opacity(
              opacity: (1 - _swipe.value.abs() / _swipeWidth).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(_swipe.value, 0),
                child: child,
              ),
            ),
            child: days,
          ),
        ),
      );
    },
  );

  /// Pages back to the picked day's month.
  void showSelectedMonth() => _show(_monthOf(widget.selected));

  void _show(({int year, int month}) month) {
    setState(() => _view = month);
    widget.onPagedAway?.call(month != _monthOf(widget.selected));
  }

  @override
  void didUpdateWidget(HijriMonthGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Any newly picked day (the grid, the strip, "Today") brings its month
    // into view.
    // Paging months alone leaves the picked day where it is.
    if (!_sameDay(widget.selected, oldWidget.selected) ||
        widget.hijriReckoning != oldWidget.hijriReckoning) {
      _view = _monthOf(widget.selected);
    }
  }

  // Fixed heights, so the morph knows where each cell lands before layout.
  static const _headerHeight = kMinInteractiveDimension;
  // A labelSmall line.
  static const _weekdayRowHeight = 16.0;
  static const _daysTop =
      _headerHeight + AppSpacing.xs + _weekdayRowHeight + AppSpacing.xs;
  // Inset of a day's background inside its cell.
  static const _cellInset = 1.0;

  @override
  Widget build(BuildContext ctx) {
    final days = buildHijriMonth(
      _view.year,
      _view.month,
      widget.hijriReckoning.source,
    );
    final dates = [
      for (final day in days) hijriToGregorian(day, widget.hijriReckoning),
    ];
    final morph = widget.morph;
    if (morph == null) return _grid(ctx, days, dates, showDays: true);
    return AnimatedBuilder(
      animation: morph.progress,
      builder: (ctx, _) {
        final t = morph.progress.value;
        if (t >= 1) return _grid(ctx, days, dates, showDays: true);
        return LayoutBuilder(
          builder: (ctx, constraints) => Stack(
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: const Interval(0.3, 1).transform(t),
                child: _grid(ctx, days, dates, showDays: false),
              ),
              Positioned.fill(
                child: _morphingDays(
                  ctx,
                  morph,
                  t,
                  constraints.maxWidth,
                  days,
                  dates,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The days on their way between their strip chips and their cells. A day
  /// in both moves and turns from one into the other; a day only in the
  /// strip fades out on its way to where its cell would be, and a day only
  /// in the grid fades in while its week unfolds from the strip's row.
  Widget _morphingDays(
    BuildContext ctx,
    HijriGridMorph morph,
    double t,
    double width,
    List<HijriCalendar> days,
    List<DateTime> dates,
  ) {
    final accent = AppColors.accentOf(ctx);
    final first = dates.first;
    final lead = first.weekday % 7;
    final cellWidth = (width - 2 * AppSpacing.xs) / 7;

    // The cell [date] has, or would have, in this month's weeks.
    int rowOf(DateTime date) =>
        ((lead + _daysBetween(first, date)) / 7).floor();
    Rect cellRect(DateTime date) {
      final slot = lead + _daysBetween(first, date);
      final row = (slot / 7).floor();
      return Rect.fromLTWH(
        AppSpacing.xs + (slot - row * 7) * cellWidth,
        _daysTop + row * _DayCell.height,
        cellWidth,
        _DayCell.height,
      ).deflate(_cellInset);
    }

    // Weeks unfold from the row the strip's picked chip lands on.
    final pickedRect = morph.stripRectOf(widget.selected, width);
    final unfold =
        pickedRect.center.dy -
        (_daysTop + (rowOf(widget.selected) + 0.5) * _DayCell.height);

    final hijriDayOf = <int, int>{
      for (var i = 0; i < days.length; i++)
        _daysBetween(first, dates[i]): days[i].hDay,
    };
    final stripDays = {
      for (final d in morph.stripDates(width)) _daysBetween(first, d): d,
    };
    final keys = {...hijriDayOf.keys, ...stripDays.keys};

    final cells = <Widget>[];
    for (final key in keys) {
      final date = stripDays[key] ?? dates[key];
      final inStrip = stripDays.containsKey(key);
      final hijriDay = hijriDayOf[key];
      final inGrid = hijriDay != null;
      final end = cellRect(date);
      final start = inStrip
          ? morph.stripRectOf(date, width)
          : end.translate(0, unfold);
      final isSelected = _sameDay(date, widget.selected);
      final isToday = _sameDay(date, widget.today);
      final radius = lerpDouble(morph.stripRadius, AppRadii.sm, t)!;

      // A day in both keeps its look at full strength and swaps its label
      // midway; one in only one side fades with it.
      final cellOpacity = inStrip && inGrid ? 1.0 : (inStrip ? 1 - t : t);
      final stripLabelOpacity = inGrid
          ? 1 - const Interval(0, 0.6).transform(t)
          : 1.0;
      final gridLabelOpacity = inStrip
          ? const Interval(0.4, 1).transform(t)
          : 1.0;

      cells.add(
        Positioned.fromRect(
          rect: Rect.lerp(start, end, t)!,
          child: Opacity(
            opacity: cellOpacity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isSelected ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: isSelected || !isToday
                      ? Colors.transparent
                      : accent.withValues(alpha: 0.6),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (inStrip && stripLabelOpacity > 0)
                    Opacity(
                      opacity: stripLabelOpacity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: morph.stripLabelOf(date),
                        ),
                      ),
                    ),
                  if (inGrid && gridLabelOpacity > 0)
                    Opacity(
                      opacity: gridLabelOpacity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _DayCellLabel(
                          hijriDay: hijriDay,
                          date: date,
                          isSelected: isSelected,
                          isToday: isToday,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // The strip's faded ends, fading away as the grid opens.
    final edge = Colors.black.withValues(alpha: t);
    return IgnorePointer(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => LinearGradient(
          colors: [edge, Colors.black, Colors.black, edge],
          stops: const [0, 0.06, 0.94, 1],
        ).createShader(rect),
        child: Stack(clipBehavior: Clip.none, children: cells),
      ),
    );
  }

  Widget _grid(
    BuildContext ctx,
    List<HijriCalendar> days,
    List<DateTime> dates, {
    required bool showDays,
  }) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final locale = Localizations.localeOf(ctx).toLanguageTag();
    final languageCode = Localizations.localeOf(ctx).languageCode;
    // Weeks start on Sunday: DateTime.weekday is 7 for Sunday.
    final lead = dates.first.weekday % 7;
    final weekCount = ((lead + days.length) / 7).ceil();
    // Sunday to Saturday, from a week known to start on a Sunday.
    final weekdayNames = [
      for (var i = 0; i < 7; i++)
        DateFormat.E(locale).format(DateTime(2026, 1, 4 + i)),
    ];
    const fridayColumn = 5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        0,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _headerHeight,
            child: Row(
              children: [
                _MonthButton(
                  icon: Icons.chevron_left,
                  tooltip: l10n.previousMonth,
                  onPressed: _hasPrev ? _prev : null,
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${hijriMonthName(l10n, _view.month)} ${_view.year} H',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _MonthButton(
                  icon: Icons.chevron_right,
                  tooltip: l10n.nextMonth,
                  onPressed: _hasNext ? _next : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: _weekdayRowHeight,
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    // Scale down rather than clip at large text sizes.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        weekdayNames[i],
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: i == fridayColumn
                              ? AppColors.accentOf(ctx)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          () {
            final grid = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var week = 0; week < weekCount; week++)
                  Row(
                    children: [
                      for (var col = 0; col < 7; col++)
                        Expanded(
                          child: () {
                            final i = week * 7 + col - lead;
                            if (!showDays || i < 0 || i >= days.length) {
                              return const SizedBox(height: _DayCell.height);
                            }
                            final events = [
                              for (final e in widget.events?.events ?? const [])
                                if (e.fallsOn(days[i])) e.nameFor(languageCode),
                            ];
                            return _DayCell(
                              hijriDay: days[i].hDay,
                              date: dates[i],
                              hasEvent: events.isNotEmpty,
                              label: [
                                '${days[i].hDay} '
                                    '${hijriMonthName(l10n, _view.month)} '
                                    '${_view.year} H',
                                DateFormat.yMMMMEEEEd(locale).format(dates[i]),
                                ...events,
                              ].join(', '),
                              isSelected: _sameDay(dates[i], widget.selected),
                              isToday: _sameDay(dates[i], widget.today),
                              onTap: () => widget.onSelected(dates[i]),
                            );
                          }(),
                        ),
                    ],
                  ),
              ],
            );
            // Swiping pages months once the grid is fully open.
            return showDays ? _swipeable(grid) : grid;
          }(),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Whole calendar days from [from] to [to], ignoring DST.
  static int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}

class _DayCell extends StatelessWidget {
  /// Hijri day number, Gregorian day number and the cell's padding, with room
  /// for a 2 px gap between rows.
  static const height = 44.0;

  /// Small enough to sit in a corner clear of the day numbers.
  static const _eventDot = 5.0;

  final int hijriDay;
  final DateTime date;
  final String label;

  /// Marks the day with a dot; its events are named in [label].
  final bool hasEvent;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.hijriDay,
    required this.date,
    required this.label,
    this.hasEvent = false,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext ctx) {
    final accent = AppColors.accentOf(ctx);
    final radius = BorderRadius.circular(AppRadii.sm);

    final content = SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Scale down rather than clip at large text sizes.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: _DayCellLabel(
              hijriDay: hijriDay,
              date: date,
              isSelected: isSelected,
              isToday: isToday,
            ),
          ),
          if (hasEvent)
            PositionedDirectional(
              top: AppSpacing.xs,
              end: AppSpacing.xs,
              child: Container(
                width: _eventDot,
                height: _eventDot,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(ctx).colorScheme.onPrimary
                      : Theme.of(ctx).colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(HijriMonthGridState._cellInset),
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
          child: PlatformCapabilities.isApple
              ? GlassPressable(
                  borderRadius: radius,
                  onTap: onTap,
                  child: content,
                )
              : InkWell(borderRadius: radius, onTap: onTap, child: content),
        ),
      ),
    );
  }
}

/// A day's Hijri day number over its Gregorian one.
class _DayCellLabel extends StatelessWidget {
  final int hijriDay;
  final DateTime date;
  final bool isSelected;
  final bool isToday;

  const _DayCellLabel({
    required this.hijriDay,
    required this.date,
    required this.isSelected,
    required this.isToday,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final onAccent = theme.colorScheme.onPrimary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$hijriDay',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: isSelected
                ? onAccent
                : (isToday
                      ? AppColors.accentOf(ctx)
                      : theme.colorScheme.onSurface),
          ),
        ),
        Text(
          '${date.day}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? onAccent.withValues(alpha: 0.8)
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Previous / next month: a press-highlighted icon on Apple (Material
/// buttons aren't used there), an [IconButton] elsewhere.
class _MonthButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _MonthButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext ctx) {
    if (!PlatformCapabilities.isApple) {
      return MaterialIconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      );
    }
    final color = Theme.of(ctx).colorScheme.onSurface;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: tooltip,
      excludeSemantics: true,
      child: GlassPressable(
        borderRadius: BorderRadius.circular(kMinInteractiveDimension / 2),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: kMinInteractiveDimension,
          child: Icon(
            icon,
            color: onPressed == null ? color.withValues(alpha: 0.3) : color,
          ),
        ),
      ),
    );
  }
}
