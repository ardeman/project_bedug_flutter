import 'dart:ui' show lerpDouble;

import 'package:flutter/physics.dart' show FrictionSimulation;
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

/// The Hijri calendar as one continuous run of weeks, scrolled up and down,
/// with each day's Gregorian date under its Hijri day. The header names the
/// month in the middle of the weeks on screen, and days of other months are
/// dimmed. Opens on the month of [selected], follows it when it changes,
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

  /// Called with true when scrolling leaves the picked day's month, and with
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

class HijriMonthGridState extends State<HijriMonthGrid> {
  /// The month the header names: the one under the middle of the days.
  late var _view = _monthOf(widget.selected);

  ({int year, int month}) _monthOf(DateTime date) =>
      hijriMonthOf(date, widget.hijriReckoning);

  static bool _hasPrevOf(({int year, int month}) m) =>
      m.year > _firstYear || m.month > 1;
  static bool _hasNextOf(({int year, int month}) m) =>
      m.year < _lastYear || m.month < 12;

  static ({int year, int month}) _prevOf(({int year, int month}) m) =>
      m.month == 1
      ? (year: m.year - 1, month: 12)
      : (year: m.year, month: m.month - 1);

  static ({int year, int month}) _nextOf(({int year, int month}) m) =>
      m.month == 12
      ? (year: m.year + 1, month: 1)
      : (year: m.year, month: m.month + 1);

  /// Weeks shown at once: enough for the longest month.
  static const _visibleWeeks = 6;
  static const _daysHeight = _visibleWeeks * _DayCell.height;

  /// The Sunday starting the calendar's first week, and how many weeks run
  /// from it to the end of the supported range.
  late DateTime _start;
  late int _weekTotal;

  /// Each day's Hijri date by its day from [_start], or null outside the
  /// supported range.
  final _hijriDays = <int, HijriCalendar?>{};

  /// Where the weeks were last scrolled to, kept while the grid morphs so
  /// it reopens and closes where it was; null to start on [_view].
  double? _scrolledTo;

  /// The month a running page animation scrolls to, or null when none runs.
  ({int year, int month})? _pagingTo;

  late final _scroll = _WeekScrollController(
    () => _scrolledTo ?? _offsetOf(_view),
  )..addListener(_onScroll);

  /// The scroll position of the weeks on screen. Briefly two while the
  /// grid finishes morphing; the newest is the one shown.
  ScrollPosition? get _position =>
      _scroll.hasClients ? _scroll.positions.last : null;

  /// The paging duration of the chevrons.
  static const _pageDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _measureRange();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _measureRange() {
    final first = _firstDayOf((year: _firstYear, month: 1));
    _start = DateTime(first.year, first.month, first.day - first.weekday % 7);
    final last = _monthDays((year: _lastYear, month: 12)).dates.last;
    _weekTotal = _daysBetween(_start, last) ~/ 7 + 1;
    _hijriDays.clear();
  }

  DateTime _dateAt(int day) =>
      DateTime(_start.year, _start.month, _start.day + day);

  HijriCalendar? _hijriAt(int day) => _hijriDays.putIfAbsent(day, () {
    try {
      final h = hijriOf(_dateAt(day), widget.hijriReckoning);
      return h.hYear < _firstYear || h.hYear > _lastYear ? null : h;
    } on ArgumentError {
      return null;
    }
  });

  DateTime _firstDayOf(({int year, int month}) m) => hijriToGregorian(
    buildHijriMonth(m.year, m.month, widget.hijriReckoning.source).first,
    widget.hijriReckoning,
  );

  /// The scroll offset that puts [m]'s first week at the top.
  double _offsetOf(({int year, int month}) m) =>
      (_daysBetween(_start, _firstDayOf(m)) ~/ 7) * _DayCell.height;

  /// The month of the middle week's Wednesday at scroll offset [pixels].
  ({int year, int month}) _monthAt(double pixels) {
    final week = ((pixels + _daysHeight / 2) / _DayCell.height).floor();
    return _monthOf(_dateAt(week * 7 + 3));
  }

  void _onScroll() {
    final position = _position;
    if (position == null) return;
    _scrolledTo = position.pixels;
    final month = _monthAt(position.pixels);
    if (month != _view) _show(month);
  }

  /// Scrolls the next or previous month's first week to the top.
  void _pageBy({required bool forward}) {
    final from = _pagingTo ?? _view;
    if (!(forward ? _hasNextOf(from) : _hasPrevOf(from))) return;
    _scrollTo(forward ? _nextOf(from) : _prevOf(from), animate: true);
  }

  /// Scrolls [month]'s first week to the top, from a screen away at most so
  /// a far month doesn't run every week between past.
  Future<void> _scrollTo(
    ({int year, int month}) month, {
    required bool animate,
  }) async {
    final position = _position;
    if (position == null) {
      _scrolledTo = null;
      if (month != _view) _show(month);
      return;
    }
    final target = _offsetOf(month)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (!animate || MediaQuery.of(context).disableAnimations) {
      position.jumpTo(target);
      return;
    }
    final distance = target - position.pixels;
    if (distance.abs() > _daysHeight) {
      position.jumpTo(target - distance.sign * _daysHeight);
    }
    _pagingTo = month;
    await position.animateTo(
      target,
      duration: _pageDuration,
      curve: Curves.easeOutCubic,
    );
    if (_pagingTo == month) _pagingTo = null;
  }

  /// Scrolls back to the picked day's month.
  void showSelectedMonth() =>
      _scrollTo(_monthOf(widget.selected), animate: true);

  void _show(({int year, int month}) month) {
    setState(() => _view = month);
    widget.onPagedAway?.call(month != _monthOf(widget.selected));
  }

  @override
  void didUpdateWidget(HijriMonthGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Any newly picked day (the grid, the strip, "Today") brings its month
    // into view, scrolling to it while the grid is fully open.
    // Scrolling alone leaves the picked day where it is.
    final reckoned = widget.hijriReckoning != oldWidget.hijriReckoning;
    if (reckoned) _measureRange();
    if (!_sameDay(widget.selected, oldWidget.selected) || reckoned) {
      final month = _monthOf(widget.selected);
      _pagingTo = null;
      if (month == _view && !reckoned) return;
      final slides =
          !reckoned &&
          (widget.morph?.progress.value ?? 1) >= 1 &&
          !MediaQuery.of(context).disableAnimations;
      if (!slides) {
        _view = month;
        _scrolledTo = null;
      }
      // Scrolling notifies the picker, which can't rebuild mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollTo(month, animate: slides);
      });
    }
  }

  ({List<HijriCalendar> days, List<DateTime> dates}) _monthDays(
    ({int year, int month}) view,
  ) {
    final days = buildHijriMonth(
      view.year,
      view.month,
      widget.hijriReckoning.source,
    );
    return (
      days: days,
      dates: [
        for (final day in days) hijriToGregorian(day, widget.hijriReckoning),
      ],
    );
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
    final morph = widget.morph;
    if (morph == null) return _grid(ctx, showDays: true);
    return AnimatedBuilder(
      animation: morph.progress,
      builder: (ctx, _) {
        final t = morph.progress.value;
        if (t >= 1) return _grid(ctx, showDays: true);
        return LayoutBuilder(
          builder: (ctx, constraints) => Stack(
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: const Interval(0.3, 1).transform(t),
                child: _grid(ctx, showDays: false),
              ),
              Positioned.fill(
                child: _morphingDays(ctx, morph, t, constraints.maxWidth),
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
  ) {
    final accent = AppColors.accentOf(ctx);
    final cellWidth = (width - 2 * AppSpacing.xs) / 7;
    final offset = _scrolledTo ?? _offsetOf(_view);

    // The cell [date] has, or would have, in the weeks as scrolled.
    Rect cellRect(DateTime date) {
      final slot = _daysBetween(_start, date);
      final row = (slot / 7).floor();
      return Rect.fromLTWH(
        AppSpacing.xs + (slot - row * 7) * cellWidth,
        _daysTop + row * _DayCell.height - offset,
        cellWidth,
        _DayCell.height,
      ).deflate(_cellInset);
    }

    // Weeks unfold from the row the strip's picked chip lands on.
    final pickedRect = morph.stripRectOf(widget.selected, width);
    final unfold = pickedRect.center.dy - cellRect(widget.selected).center.dy;

    final firstWeek = (offset / _DayCell.height).floor();
    final lastWeek = ((offset + _daysHeight) / _DayCell.height).ceil();
    final gridDays = <int, HijriCalendar>{
      for (var day = firstWeek * 7; day < lastWeek * 7; day++)
        day: ?_hijriAt(day),
    };
    final stripDays = {
      for (final d in morph.stripDates(width)) _daysBetween(_start, d): d,
    };
    final keys = {...gridDays.keys, ...stripDays.keys};

    final cells = <Widget>[];
    for (final key in keys) {
      final date = stripDays[key] ?? _dateAt(key);
      final inStrip = stripDays.containsKey(key);
      final hijri = gridDays[key];
      final inGrid = hijri != null;
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
                          hijriDay: hijri.hDay,
                          date: date,
                          isSelected: isSelected,
                          isToday: isToday,
                          isDimmed: !_isInView(hijri),
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

  bool _isInView(HijriCalendar h) =>
      h.hYear == _view.year && h.hMonth == _view.month;

  Widget _grid(BuildContext ctx, {required bool showDays}) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final locale = Localizations.localeOf(ctx).toLanguageTag();
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
                  icon: Icons.keyboard_arrow_up,
                  tooltip: l10n.previousMonth,
                  onPressed: _hasPrevOf(_view)
                      ? () => _pageBy(forward: false)
                      : null,
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
                  icon: Icons.keyboard_arrow_down,
                  tooltip: l10n.nextMonth,
                  onPressed: _hasNextOf(_view)
                      ? () => _pageBy(forward: true)
                      : null,
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
          SizedBox(
            height: _daysHeight,
            child: showDays
                ? ScrollConfiguration(
                    // No scrollbar: the header names the month scrolled to,
                    // and Apple paths take no Material scrollbar.
                    behavior: ScrollConfiguration.of(ctx)
                        .copyWith(scrollbars: false),
                    child: ListView.builder(
                      controller: _scroll,
                      physics: const _WeekSnapPhysics(),
                      padding: EdgeInsets.zero,
                      itemExtent: _DayCell.height,
                      itemCount: _weekTotal,
                      itemBuilder: _week,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  /// The [week]th week from [_start], Sunday first. Days of the months
  /// before and after the one in the header are dimmed.
  Widget _week(BuildContext ctx, int week) {
    final l10n = AppLocalizations.of(ctx);
    final locale = Localizations.localeOf(ctx).toLanguageTag();
    final languageCode = Localizations.localeOf(ctx).languageCode;
    return Row(
      children: [
        for (var col = 0; col < 7; col++)
          Expanded(
            child: () {
              final day = week * 7 + col;
              final hijri = _hijriAt(day);
              if (hijri == null) return const SizedBox(height: _DayCell.height);
              final date = _dateAt(day);
              final events = [
                for (final e in widget.events?.events ?? const [])
                  if (e.fallsOn(hijri)) e.nameFor(languageCode),
              ];
              return _DayCell(
                hijriDay: hijri.hDay,
                date: date,
                hasEvent: events.isNotEmpty,
                label: [
                  '${hijri.hDay} '
                      '${hijriMonthName(l10n, hijri.hMonth)} '
                      '${hijri.hYear} H',
                  DateFormat.yMMMMEEEEd(locale).format(date),
                  ...events,
                ].join(', '),
                isSelected: _sameDay(date, widget.selected),
                isToday: _sameDay(date, widget.today),
                isDimmed: !_isInView(hijri),
                onTap: () => widget.onSelected(date),
              );
            }(),
          ),
      ],
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

/// Starts on the offset [initialOffset] gives when the weeks are built, so
/// the grid opens on its month or where it was scrolled to.
class _WeekScrollController extends ScrollController {
  final double Function() initialOffset;

  _WeekScrollController(this.initialOffset) : super(keepScrollOffset: false);

  @override
  double get initialScrollOffset => initialOffset();
}

/// Scrolls freely, then settles with a whole week at the top, so the rows
/// stay lined up under the weekday names.
class _WeekSnapPhysics extends ScrollPhysics {
  const _WeekSnapPhysics({super.parent});

  /// How quickly a fling slows down, as in iOS scrolling.
  static const _flingDrag = 0.135;

  @override
  _WeekSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _WeekSnapPhysics(parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    // Where the fling would come to rest, to the nearest week.
    final rest = velocity.abs() < tolerance.velocity
        ? position.pixels
        : FrictionSimulation(_flingDrag, position.pixels, velocity).finalX;
    final target = ((rest / _DayCell.height).round() * _DayCell.height).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
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

  /// Whether the day is outside the month in the header.
  final bool isDimmed;
  final VoidCallback onTap;

  const _DayCell({
    required this.hijriDay,
    required this.date,
    required this.label,
    this.hasEvent = false,
    required this.isSelected,
    required this.isToday,
    this.isDimmed = false,
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
              isDimmed: isDimmed,
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
  final bool isDimmed;

  /// Faint enough to set other months apart, still legible.
  static const _dimmedOpacity = 0.4;

  const _DayCellLabel({
    required this.hijriDay,
    required this.date,
    required this.isSelected,
    required this.isToday,
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final onAccent = theme.colorScheme.onPrimary;
    final label = Column(
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
    return isDimmed && !isSelected
        ? Opacity(opacity: _dimmedOpacity, child: label)
        : label;
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
