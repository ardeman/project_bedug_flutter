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

/// Picks the day the prayer cards below show: an endless strip of dates (past
/// and future) and the picked date, with a button back to today. Lite glass
/// on Apple (it scrolls with the list), the theme's flat card elsewhere.
///
/// The strip builds only the chips on screen, so its length costs nothing.
/// Scrolling it picks the date that crosses the middle, with a selection
/// tick for each one (haptic, or a click sound on devices without haptics),
/// and it settles with that chip centered.
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

class _PrayerDayPickerState extends State<PrayerDayPicker> {
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

  void _pick(int offset) {
    if (offset == (_lastPicked ?? _selectedOffset)) return;
    _lastPicked = offset;
    SelectionFeedback.tick();
    widget.onSelected(addDays(widget.today, offset));
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
    // Name the year only when it isn't this one.
    final dateFormat = widget.selected.year == widget.today.year
        ? DateFormat.MMMMEEEEd(locale)
        : DateFormat.yMMMMEEEEd(locale);

    final content = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: _DateStrip(
              controller: _strip,
              today: widget.today,
              selected: offset,
              locale: locale,
              onSelected: _pick,
            ),
          ),
          // Fixed height, so the "Today" button appearing doesn't resize the
          // card.
          SizedBox(
            height: kMinInteractiveDimension,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.md, end: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dateFormat.format(widget.selected),
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (offset != 0 && PlatformCapabilities.isApple)
                    GlassPillButton(
                      icon: Icons.today,
                      label: l10n.today,
                      onPressed: () => _pick(0),
                    )
                  else if (offset != 0)
                    TextButton.icon(
                      onPressed: () => _pick(0),
                      icon: const Icon(Icons.today, size: 18),
                      label: Text(l10n.today),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.accentOf(ctx)),
                    ),
                ],
              ),
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
          showMonth: offset == 0 || date.day == 1,
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
    final theme = Theme.of(ctx);
    final accent = AppColors.accentOf(ctx);
    final onAccent = theme.colorScheme.onPrimary;
    final muted = theme.colorScheme.onSurfaceVariant;
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
              child: Column(
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
                          : (isToday ? accent : theme.colorScheme.onSurface),
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
              ),
            ),
          ),
        ),
      ),
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
