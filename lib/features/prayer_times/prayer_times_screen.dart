import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:adhan/adhan.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/services/prayer_service.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/widgets/calculation_method_picker.dart';
import 'widgets/prayer_day_picker.dart';

bool get _isApple => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key});
  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen> {
  Timer? _tick;
  // Only the countdown badges listen, so a tick doesn't rebuild the screen.
  final _remaining = ValueNotifier<Duration>(Duration.zero);
  bool _isMethodPickerOpen = false;

  /// The day the cards show, or null for today. A date rather than an offset,
  /// so a reload after midnight doesn't shift it.
  DateTime? _pickedDay;

  @override
  void initState() {
    super.initState();
    _update();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final next = ref.read(nextPrayerProvider);
    if (next.time != null && mounted) {
      _remaining.value = next.time!.difference(clock.now());
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _remaining.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final state = ref.watch(prayerProvider);
    final next = ref.watch(nextPrayerProvider);
    final nextName = _prayerLabel(l10n, next.key);
    final locationLabel = state.locationLabel ?? '--';
    final theme = Theme.of(ctx);
    final isDark = theme.brightness == Brightness.dark;
    final onAccent = theme.colorScheme.onPrimary;
    final mq = MediaQuery.of(ctx);
    final isPortrait = mq.orientation == Orientation.portrait;
    final topInset = mq.padding.top;
    final isIosPortrait = !kIsWeb && Platform.isIOS && isPortrait;
    // On macOS the collapsed bar is one toolbar row, so its capsule and
    // buttons center on the traffic lights (see MainFlutterWindow.swift).
    final isMacOS = !kIsWeb && Platform.isMacOS;
    final minCollapsedExtent = kToolbarHeight +
        (isIosPortrait
            ? (topInset + 8).clamp(44.0, 62.0)
            : isMacOS
                ? 0.0
                : 44.0);

    return Scaffold(
      extendBodyBehindAppBar: _isApple,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          _isApple
              ? SliverPersistentHeader(
                  pinned: true,
                  delegate: _LiquidGlassAppBar(
                    nextLabel: l10n.nextPrayer,
                    nextName: nextName,
                    nextTime:
                        next.time == null ? null : _formatClock(next.time!),
                    locationLabel: locationLabel,
                    remaining: _remaining,
                    minCollapsedExtent: minCollapsedExtent,
                    isIosPortrait: isIosPortrait,
                    topInset: topInset,
                    isDark: isDark,
                    onTune: (anchor) => _showMethodMenu(ctx, anchor),
                    onRefresh: () => ref.read(prayerProvider.notifier).load(),
                  ),
                )
              : SliverAppBar(
                  expandedHeight: _materialExpandedHeight,
                  pinned: true,
                  backgroundColor: AppColors.accentOf(ctx),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accentOf(ctx),
                            AppColors.secondaryOf(ctx)
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: onAccent.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                Flexible(
                                  child: Text(
                                    locationLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: onAccent.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(nextName,
                                style: theme.textTheme.headlineMedium
                                    ?.copyWith(color: onAccent)),
                            const SizedBox(height: AppSpacing.xs),
                            _CountdownBadge(remaining: _remaining),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.tune, color: onAccent),
                      onPressed: () => _showMethodPicker(ctx),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: onAccent),
                      onPressed: () => ref.read(prayerProvider.notifier).load(),
                    ),
                  ],
                ),

          // ── Body ─────────────────────────────────────────────────────
          if (state.loading)
            const SliverFillRemaining(child: Center(child: AdaptiveSpinner()))
          else if (state.error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.location_off,
                        size: 48, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: AppSpacing.sm),
                    Text(state.error!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.xs),
                    if (state.showLocationGuide)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          _isApple
                              ? l10n.locationGuideApple
                              : l10n.locationGuideAndroid,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xxs),
                    if (_isApple)
                      LiquidGlassButton(
                        icon: Icons.refresh,
                        label: l10n.retry,
                        foregroundColor: AppColors.accentOf(ctx),
                        style: LiquidGlassButton.defaultStyle
                            .copyWith(color: glassTintOf(ctx)),
                        onPressed: () =>
                            ref.read(prayerProvider.notifier).load(),
                      )
                    else
                      FilledButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retry),
                        onPressed: () =>
                            ref.read(prayerProvider.notifier).load(),
                      ),
                  ]),
                ),
              ),
            )
          else ...[
            SliverList(
              delegate: SliverChildListDelegate([
                SizedBox(height: _isApple ? AppSpacing.xs : AppSpacing.md),
                ..._buildDay(ctx, state.times!, next),
                // Room to scroll the last card clear of the floating nav bar.
                const SizedBox(height: 100),
              ]),
            ),
            _CollapseRoom(
              collapseRange: _isApple
                  ? _LiquidGlassAppBar.expandedExtent - minCollapsedExtent
                  : _materialExpandedHeight - (kToolbarHeight + topInset),
            ),
          ],
        ],
      ),
    );
  }

  String _prayerLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      'fajr' => l10n.fajr,
      'sunrise' => l10n.sunrise,
      'dhuhr' => l10n.dhuhr,
      'asr' => l10n.asr,
      'maghrib' => l10n.maghrib,
      'isha' => l10n.isha,
      _ => '--',
    };
  }

  /// The day picker and the picked day's cards. Only today's (or, after
  /// Isha, tomorrow's) next prayer is highlighted.
  List<Widget> _buildDay(BuildContext ctx, PrayerTimes todayTimes,
      ({String key, DateTime? time}) next) {
    final d = todayTimes.dateComponents;
    final today = DateTime(d.year, d.month, d.day);
    final day = _pickedDay ?? today;
    final times = daysBetween(today, day) == 0
        ? todayTimes
        : prayerTimesOn(todayTimes, day);
    final nextTime = next.time;
    final nextKey =
        nextTime != null && daysBetween(day, nextTime) == 0 ? next.key : null;
    return [
      PrayerDayPicker(
        today: today,
        selected: day,
        onSelected: (picked) => setState(
            () => _pickedDay = daysBetween(today, picked) == 0 ? null : picked),
      ),
      ..._buildPrayerCards(ctx, times, nextKey),
    ];
  }

  List<Widget> _buildPrayerCards(
      BuildContext ctx, PrayerTimes times, String? nextKey) {
    final l10n = AppLocalizations.of(ctx);
    final prayers = [
      _PrayerEntry('fajr', l10n.fajr, Icons.bedtime_outlined, times.fajr),
      _PrayerEntry('sunrise', l10n.sunrise, Icons.wb_twilight, times.sunrise),
      _PrayerEntry('dhuhr', l10n.dhuhr, Icons.wb_sunny_outlined, times.dhuhr),
      _PrayerEntry('asr', l10n.asr, Icons.wb_cloudy_outlined, times.asr),
      _PrayerEntry(
          'maghrib', l10n.maghrib, Icons.nights_stay_outlined, times.maghrib),
      _PrayerEntry('isha', l10n.isha, Icons.dark_mode_outlined, times.isha),
    ];
    return prayers
        .map((p) => _isApple
            ? _LiquidGlassCard(entry: p, isNext: p.key == nextKey, l10n: l10n)
            : _MaterialCard(entry: p, isNext: p.key == nextKey, l10n: l10n))
        .toList();
  }

  Future<void> _showMethodMenu(BuildContext ctx, Rect anchor) async {
    if (_isMethodPickerOpen) return;
    _isMethodPickerOpen = true;
    try {
      await showCalculationMethodMenu(
        ctx,
        ref,
        current: ref.read(settingsProvider).method,
        anchor: anchor,
      );
    } finally {
      _isMethodPickerOpen = false;
    }
  }

  Future<void> _showMethodPicker(BuildContext ctx) async {
    if (_isMethodPickerOpen) return;
    _isMethodPickerOpen = true;
    try {
      await showCalculationMethodPicker(
        ctx,
        ref,
        current: ref.read(settingsProvider).method,
      );
    } finally {
      _isMethodPickerOpen = false;
    }
  }
}

// ── Liquid Glass App Bar ───────────────────────────────────────────────────────
// Expanded, an accent hero with a glass countdown lens. Collapsing fades the
// hero out, so the list scrolls under a scroll-edge band, and the title moves
// into a floating glass capsule. The action buttons are glass throughout.
/// Height of the expanded Material app bar.
const _materialExpandedHeight = 200.0;

/// Empty space after the cards, just enough that the page can always scroll
/// the header down to its compact bar. A short day doesn't fill the screen,
/// and without this the header couldn't collapse at all. Longer content gets
/// none.
class _CollapseRoom extends StatelessWidget {
  /// How far the header shrinks from expanded to compact.
  final double collapseRange;

  const _CollapseRoom({required this.collapseRange});

  @override
  Widget build(BuildContext ctx) => SliverLayoutBuilder(
        builder: (ctx, c) {
          final room = c.viewportMainAxisExtent +
              collapseRange -
              c.precedingScrollExtent;
          return SliverToBoxAdapter(
            child: SizedBox(height: room > 0 ? room : 0),
          );
        },
      );
}

class _LiquidGlassAppBar extends SliverPersistentHeaderDelegate {
  final String nextLabel;
  final String nextName;

  /// The next prayer's clock time, e.g. "12:01".
  final String? nextTime;
  final String locationLabel;
  final ValueListenable<Duration> remaining;
  final double minCollapsedExtent;
  final bool isIosPortrait;
  final double topInset;
  final bool isDark;

  /// Called with the tune button's global rect, to anchor the menu.
  final ValueChanged<Rect> onTune;
  final VoidCallback onRefresh;

  const _LiquidGlassAppBar({
    required this.nextLabel,
    required this.nextName,
    required this.nextTime,
    required this.locationLabel,
    required this.remaining,
    required this.minCollapsedExtent,
    required this.isIosPortrait,
    required this.topInset,
    required this.isDark,
    required this.onTune,
    required this.onRefresh,
  });

  /// Diameter of the round glass action buttons.
  static const _actionSize = 40.0;

  /// Height of the collapsed title capsule: two text lines plus padding.
  static const _capsuleHeight = 48.0;

  @override
  double get minExtent => minCollapsedExtent;
  @override
  double get maxExtent => expandedExtent;

  /// Height of the expanded hero, before any scrolling.
  static const expandedExtent = 260.0;

  /// Below this height the hero drops the label line and uses smaller type,
  /// so a landscape phone's short header never overflows.
  static const _compactHeroHeight = 130.0;

  /// The faint mosque behind the hero text: big enough to read as texture.
  static const _watermarkSize = 168.0;

  @override
  bool shouldRebuild(_LiquidGlassAppBar old) =>
      old.nextLabel != nextLabel ||
      old.nextName != nextName ||
      old.nextTime != nextTime ||
      old.locationLabel != locationLabel ||
      old.remaining != remaining ||
      old.minCollapsedExtent != minCollapsedExtent ||
      old.isIosPortrait != isIosPortrait ||
      old.topInset != topInset ||
      old.isDark != isDark;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(ctx);
    final onSurface = theme.colorScheme.onSurface;
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final collapsedProgress = (progress * 2 - 1).clamp(0.0, 1.0);
    final expandedFade = (1 - progress * 2).clamp(0.0, 1.0);
    final isLargeInsetIosPortrait = isIosPortrait && topInset >= 54;
    final collapsedActionTop = isIosPortrait
        ? (isLargeInsetIosPortrait ? 0.0 : 2.0)
        : ((minExtent - kToolbarHeight) / 2).clamp(0.0, 22.0);
    final iosPortraitLift =
        isLargeInsetIosPortrait ? ((topInset - 54) / 2).clamp(0.0, 3.0) : 0.0;
    final collapsedRowTop = collapsedActionTop - iosPortraitLift;
    final actionTop = lerpDouble(0, collapsedActionTop, collapsedProgress)!;
    // Decided at full height, not as the header shrinks, so the hero's type
    // doesn't jump mid-collapse; the shrinking hero slides under its clip.
    final heroCompact =
        maxExtent - topInset - kToolbarHeight < _compactHeroHeight;
    // Two buttons, the gap between them, the right inset and the gap to
    // the title capsule.
    const actionAreaWidth =
        _actionSize * 2 + AppSpacing.xs + AppSpacing.sm + AppSpacing.md;
    // White over the accent hero, the text color once it has faded.
    final actionColor = Color.lerp(Colors.white, onSurface, progress)!;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Hero background, fading out as the bar collapses. Rounded at the
        // bottom, so it reads as a card the list scrolls up under.
        IgnorePointer(
          child: Opacity(
            opacity: 1 - progress,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadii.xl)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accentOf(ctx)
                              .withValues(alpha: isDark ? 0.9 : 1),
                          AppColors.secondaryOf(ctx)
                              .withValues(alpha: isDark ? 0.9 : 1),
                        ],
                      ),
                    ),
                  ),
                  // A soft light from the top right, for depth.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.2,
                        colors: [
                          Colors.white.withValues(alpha: 0.16),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: -AppSpacing.lg,
                    bottom: -AppSpacing.lg,
                    child: Icon(
                      Icons.mosque_outlined,
                      size: _watermarkSize,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Scroll edge: keeps the floating glass legible over the list.
        IgnorePointer(
          child: Opacity(
            opacity: collapsedProgress,
            child: LiquidGlassScrollEdge(
              edge: LiquidGlassEdge.top,
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (_, area) => Stack(
              children: [
                // Expanded layout: the location on the buttons' row, then the
                // next prayer, left aligned under it. The location, the name
                // and the countdown pill are hidden copies that hold their
                // places; the moving layer below draws them.
                IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Lifted with the action buttons so the location stays
                      // centered on their row.
                      Transform.translate(
                        offset: Offset(0, -iosPortraitLift),
                        child: SizedBox(
                          height: kToolbarHeight,
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                                start: AppSpacing.md + windowControlsInset,
                                end: actionAreaWidth),
                            child: Row(children: [
                              Opacity(
                                opacity: expandedFade,
                                child: Icon(
                                  Icons.location_on,
                                  size: _locationIconSize,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Flexible(
                                child: Visibility.maintain(
                                  visible: false,
                                  child: Text(
                                    locationLabel,
                                    key: const ValueKey('location-hero'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _locationStyle(ctx, expanded: true),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      Expanded(
                        // Collapsing slides the block up under the location
                        // row instead of squeezing it.
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: AlignmentDirectional.bottomStart,
                            minHeight: 0,
                            maxHeight: double.infinity,
                            child: _heroBody(ctx,
                                compact: heroCompact, fade: expandedFade),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Collapsed layout: the title capsule on the same row as the
                // collapsed action buttons, so their centers line up. Also
                // hidden copies; the moving layer lands on them.
                Positioned(
                  top: collapsedRowTop,
                  left: 0,
                  right: 0,
                  height: kToolbarHeight,
                  child: IgnorePointer(
                    child: Visibility.maintain(
                      visible: false,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: AppSpacing.md + windowControlsInset,
                              right: actionAreaWidth),
                          child: SizedBox(
                            key: const ValueKey('pill-capsule'),
                            height: _capsuleHeight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          locationLabel,
                                          key: const ValueKey(
                                              'location-capsule'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: _locationStyle(ctx,
                                              expanded: false),
                                        ),
                                        Text(
                                          nextName,
                                          key: const ValueKey('name-capsule'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              _nameStyle(ctx, expanded: false),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  ValueListenableBuilder<Duration>(
                                    valueListenable: remaining,
                                    builder: (_, value, __) => value.isNegative
                                        ? const SizedBox()
                                        : Text(
                                            _formatCountdown(value),
                                            key: const ValueKey(
                                                'countdown-capsule'),
                                            style:
                                                _collapsedCountdownStyle(ctx),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: _movingLayer(
                    ctx,
                    area.biggest,
                    progress: progress,
                    collapsedProgress: collapsedProgress,
                    expandedFade: expandedFade,
                    compact: heroCompact,
                    collapsedRowTop: collapsedRowTop,
                    iosPortraitLift: iosPortraitLift,
                    actionAreaWidth: actionAreaWidth,
                  ),
                ),
                // Actions, last so they stay on top and tappable
                Positioned(
                  top: actionTop - iosPortraitLift,
                  right: AppSpacing.sm,
                  child: SizedBox(
                    height: kToolbarHeight,
                    child: Row(children: [
                      Builder(
                        builder: (buttonCtx) => _GlassIconButton(
                          icon: Icons.tune,
                          onTap: () {
                            final box =
                                buttonCtx.findRenderObject()! as RenderBox;
                            onTune(box.localToGlobal(Offset.zero) & box.size);
                          },
                          color: actionColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _GlassIconButton(
                        icon: Icons.refresh,
                        onTap: onRefresh,
                        color: actionColor,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Size of the location pin before the expanded location.
  static const _locationIconSize = 16.0;

  /// The location's style: white over the accent hero when [expanded],
  /// the capsule's muted first line otherwise.
  static TextStyle _locationStyle(BuildContext ctx, {required bool expanded}) {
    final textTheme = Theme.of(ctx).textTheme;
    return expanded
        ? (textTheme.labelLarge ?? const TextStyle())
            .copyWith(color: Colors.white.withValues(alpha: 0.85))
        : (textTheme.bodySmall ?? const TextStyle()).copyWith(
            color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7));
  }

  /// The next prayer's name: large and white in the hero when [expanded],
  /// the capsule's second line otherwise.
  static TextStyle _nameStyle(BuildContext ctx,
      {required bool expanded, bool compact = false}) {
    final textTheme = Theme.of(ctx).textTheme;
    if (!expanded) {
      return (textTheme.titleMedium ?? const TextStyle())
          .copyWith(color: Theme.of(ctx).colorScheme.onSurface);
    }
    return ((compact ? textTheme.headlineMedium : textTheme.displaySmall) ??
            const TextStyle())
        .copyWith(color: Colors.white, fontWeight: FontWeight.w700);
  }

  /// The location, the next prayer's name, the countdown and its glass pill,
  /// each moving from its place in the hero to its place in the collapsed
  /// capsule as the bar collapses, so the pill grows into the capsule and
  /// the text travels instead of two copies crossfading. The positions here
  /// mirror the hidden layouts in [build], in [area] (the header below the
  /// top safe area).
  Widget _movingLayer(
    BuildContext ctx,
    Size area, {
    required double progress,
    required double collapsedProgress,
    required double expandedFade,
    required bool compact,
    required double collapsedRowTop,
    required double iosPortraitLift,
    required double actionAreaWidth,
  }) {
    final isRtl = Directionality.of(ctx) == TextDirection.rtl;
    final textScaler = MediaQuery.textScalerOf(ctx);
    final t = Curves.easeInOut.transform(progress);

    Size measure(String text, TextStyle style, double maxWidth) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: math.max(0, maxWidth));
      final size = painter.size;
      painter.dispose();
      return size;
    }

    // A box [inset] in from the start edge, as a physical left.
    double fromStart(double inset, double width) =>
        isRtl ? area.width - inset - width : inset;

    // Text moving from [start] to [end], growing or shrinking from its
    // start edge. A label is laid out in the room it has ([startRoom] to
    // [endRoom]) rather than its measured width, which sub-pixel rounding
    // would ellipsize.
    Widget moving(String text, Key key, Rect start, Rect end,
        TextStyle startStyle, TextStyle endStyle,
        {double? startRoom, double? endRoom}) {
      final label = Text(
        text,
        key: key,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle.lerp(startStyle, endStyle, t),
      );
      final top = lerpDouble(start.top, end.top, t);
      if (startRoom == null || endRoom == null) {
        return Positioned(
            left: lerpDouble(start.left, end.left, t), top: top, child: label);
      }
      final room = math.max(0.0, lerpDouble(startRoom, endRoom, t)!);
      final aligned =
          Align(alignment: AlignmentDirectional.centerStart, child: label);
      return isRtl
          ? Positioned(
              right: area.width - lerpDouble(start.right, end.right, t)!,
              top: top,
              width: room,
              child: aligned)
          : Positioned(
              left: lerpDouble(start.left, end.left, t),
              top: top,
              width: room,
              child: aligned);
    }

    final locationStart = _locationStyle(ctx, expanded: true);
    final locationEnd = _locationStyle(ctx, expanded: false);
    final nameStart = _nameStyle(ctx, expanded: true, compact: compact);
    final nameEnd = _nameStyle(ctx, expanded: false);
    final digitsStart = _HeroBadge.textStyleOf(ctx, compact: compact);
    final digitsEnd = _collapsedCountdownStyle(ctx);
    final hPad = _HeroBadge.horizontalPadding(compact: compact);
    final vPad = _HeroBadge.verticalPadding(compact: compact);
    final iconSize = _HeroBadge.iconSize(compact: compact);

    // The capsule, inside its padding: the text column, then the countdown.
    final capsuleLeft = AppSpacing.md + windowControlsInset;
    final capsuleRight = area.width - actionAreaWidth;
    final capsuleTop = collapsedRowTop + (kToolbarHeight - _capsuleHeight) / 2;
    final capsule = Rect.fromLTRB(
        capsuleLeft, capsuleTop, capsuleRight, capsuleTop + _capsuleHeight);
    double capsuleTextLeft(double width) => isRtl
        ? capsuleRight - AppSpacing.md - width
        : capsuleLeft + AppSpacing.md;

    // The location, after the pin on the buttons' row.
    final locationInset = AppSpacing.md +
        windowControlsInset +
        _locationIconSize +
        AppSpacing.xxs;
    final locationStartRoom = area.width - locationInset - actionAreaWidth;
    final locationStartSize =
        measure(locationLabel, locationStart, locationStartRoom);

    return ValueListenableBuilder<Duration>(
      valueListenable: remaining,
      builder: (_, value, __) {
        final hasCountdown = !value.isNegative;
        final digits = hasCountdown ? _formatCountdown(value) : '';
        final digitsStartSize = measure(digits, digitsStart, double.infinity);
        final digitsEndSize = measure(digits, digitsEnd, double.infinity);

        // The hero, bottom up: its padding, the pill, the gap, the name.
        final badgeRow = math.max(iconSize, digitsStartSize.height);
        final badgeHeight = hasCountdown ? badgeRow + vPad * 2 : 0.0;
        final badgeWidth =
            hPad * 2 + iconSize + AppSpacing.xs + digitsStartSize.width;
        final badgeTop = area.height - AppSpacing.lg - badgeHeight;
        final badge = Rect.fromLTWH(fromStart(AppSpacing.md, badgeWidth),
            badgeTop, badgeWidth, badgeHeight);
        final nameStartRoom = area.width - AppSpacing.md * 2;
        final nameStartSize = measure(nextName, nameStart, nameStartRoom);
        final nameStartTop = badgeTop -
            (compact ? AppSpacing.xxs : AppSpacing.xs) -
            nameStartSize.height;

        // The capsule's text column, centered in it, beside the countdown.
        final capsuleTextWidth = capsule.width -
            AppSpacing.md * 2 -
            AppSpacing.xs -
            (hasCountdown ? digitsEndSize.width : 0);
        final locationEndSize =
            measure(locationLabel, locationEnd, capsuleTextWidth);
        final nameEndSize = measure(nextName, nameEnd, capsuleTextWidth);
        final locationEndTop = capsuleTop +
            (_capsuleHeight - locationEndSize.height - nameEndSize.height) / 2;

        // The pill grows into the capsule. Without a countdown there is no
        // pill, so the capsule fades in where it lands.
        final pill = hasCountdown ? Rect.lerp(badge, capsule, t)! : capsule;
        final pillTint = hasCountdown
            ? Color.lerp(
                Colors.white.withValues(alpha: 0.14), glassTintOf(ctx), t)!
            : _fadeColor(glassTintOf(ctx), collapsedProgress);
        final pillVisible = hasCountdown || collapsedProgress > 0;

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: pill,
                child: Transform.scale(
                  scale: hasCountdown ? 1 : _glassScale(collapsedProgress),
                  alignment: Alignment.centerLeft,
                  child: LiquidGlassLens(
                    key: const ValueKey('pill-moving'),
                    visibility: pillVisible,
                    style: LiquidGlassStyle(
                      shape: LiquidGlassShape.continuousRoundedRectangle(
                          cornerRadius: pill.height / 2),
                      color: pillTint,
                      blur: 6 * (hasCountdown ? t : collapsedProgress),
                    ),
                    // The timer icon stays at the pill's start, fading out.
                    child: hasCountdown
                        ? Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(start: hPad),
                              child: Opacity(
                                opacity: expandedFade,
                                child: Icon(Icons.timer_outlined,
                                    size: iconSize,
                                    color:
                                        Colors.white.withValues(alpha: 0.85)),
                              ),
                            ),
                          )
                        : const SizedBox.expand(),
                  ),
                ),
              ),
              moving(
                locationLabel,
                const ValueKey('location-moving'),
                Rect.fromLTWH(
                    fromStart(locationInset, locationStartSize.width),
                    (kToolbarHeight - locationStartSize.height) / 2 -
                        iosPortraitLift,
                    locationStartSize.width,
                    locationStartSize.height),
                Rect.fromLTWH(
                    capsuleTextLeft(locationEndSize.width),
                    locationEndTop,
                    locationEndSize.width,
                    locationEndSize.height),
                locationStart,
                locationEnd,
                startRoom: locationStartRoom,
                endRoom: capsuleTextWidth,
              ),
              moving(
                nextName,
                const ValueKey('name-moving'),
                Rect.fromLTWH(fromStart(AppSpacing.md, nameStartSize.width),
                    nameStartTop, nameStartSize.width, nameStartSize.height),
                Rect.fromLTWH(
                    capsuleTextLeft(nameEndSize.width),
                    locationEndTop + locationEndSize.height,
                    nameEndSize.width,
                    nameEndSize.height),
                nameStart,
                nameEnd,
                startRoom: nameStartRoom,
                endRoom: capsuleTextWidth,
              ),
              if (hasCountdown)
                moving(
                  digits,
                  const ValueKey('countdown-moving'),
                  Rect.fromLTWH(
                      fromStart(hPad + AppSpacing.md + iconSize + AppSpacing.xs,
                          digitsStartSize.width),
                      badgeTop + vPad + (badgeRow - digitsStartSize.height) / 2,
                      digitsStartSize.width,
                      digitsStartSize.height),
                  Rect.fromLTWH(
                      isRtl
                          ? capsuleLeft + AppSpacing.md
                          : capsuleRight - AppSpacing.md - digitsEndSize.width,
                      collapsedRowTop +
                          (kToolbarHeight - digitsEndSize.height) / 2,
                      digitsEndSize.width,
                      digitsEndSize.height),
                  digitsStart,
                  digitsEnd,
                ),
            ],
          ),
        );
      },
    );
  }

  /// The next prayer: a small label with its time, then hidden copies of
  /// the name and the countdown pill holding their places.
  Widget _heroBody(BuildContext ctx,
      {required bool compact, required double fade}) {
    final textTheme = Theme.of(ctx).textTheme;
    final muted = Colors.white.withValues(alpha: 0.75);
    final time = nextTime;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact)
            Opacity(
              opacity: fade,
              child: Text(
                time == null
                    ? nextLabel.toUpperCase()
                    : '${nextLabel.toUpperCase()}  ·  $time',
                style: textTheme.labelMedium?.copyWith(
                  color: muted,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Visibility.maintain(
            visible: false,
            child: Text(
              nextName,
              key: const ValueKey('name-hero'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _nameStyle(ctx, expanded: true, compact: compact),
            ),
          ),
          SizedBox(height: compact ? AppSpacing.xxs : AppSpacing.xs),
          ValueListenableBuilder<Duration>(
            valueListenable: remaining,
            builder: (_, value, __) => value.isNegative
                ? const SizedBox()
                : Visibility.maintain(
                    visible: false,
                    child: Padding(
                      key: const ValueKey('pill-hero'),
                      padding: EdgeInsets.symmetric(
                          horizontal:
                              _HeroBadge.horizontalPadding(compact: compact),
                          vertical:
                              _HeroBadge.verticalPadding(compact: compact)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox.square(
                            dimension: _HeroBadge.iconSize(compact: compact)),
                        const SizedBox(width: AppSpacing.xs),
                        Text(_formatCountdown(value),
                            key: const ValueKey('countdown-badge'),
                            style:
                                _HeroBadge.textStyleOf(ctx, compact: compact)),
                      ]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Glass Icon Button ─────────────────────────────────────────────────────────
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext ctx) => GlassIconButton(
        icon: icon,
        onPressed: onTap,
        color: color,
        size: _LiquidGlassAppBar._actionSize,
      );
}

// ── Liquid Glass Card (Apple) ─────────────────────────────────────────────────
class _LiquidGlassCard extends StatelessWidget {
  final _PrayerEntry entry;
  final bool isNext;
  final AppLocalizations l10n;
  const _LiquidGlassCard({
    required this.entry,
    required this.isNext,
    required this.l10n,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final mq = MediaQuery.of(ctx);
    final isLandscape = mq.orientation == Orientation.landscape;
    final sideInsetLeft = isLandscape ? mq.padding.left : 0.0;
    final sideInsetRight = isLandscape ? mq.padding.right : 0.0;
    final t = entry.time;
    final timeStr = t == null
        ? '--:--'
        : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md + sideInsetLeft,
        AppSpacing.xxs,
        AppSpacing.md + sideInsetRight,
        AppSpacing.xxs,
      ),
      child: Material(
        color: Colors.transparent,
        // Lite glass: frost, tint and the lit rim without the shader, since
        // lenses inside a scrolling list fight the package's design.
        child: LiquidGlassLite(
          shape: const LiquidGlassShape.continuousRoundedRectangle(
              cornerRadius: AppRadii.lg),
          blur: isNext ? 14 : 10,
          color: isNext
              ? Colors.transparent
              : (isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.62)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            // Same continuous corners as the glass, which doesn't clip
            // its child on every renderer.
            decoration: ShapeDecoration(
              shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg)),
              gradient: isNext
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      // Nearly opaque, so the white text keeps its contrast
                      // over a light background; a little glass shows through.
                      colors: [
                        AppColors.accentOf(ctx).withValues(alpha: 0.92),
                        AppColors.secondaryOf(ctx).withValues(alpha: 0.85),
                      ],
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isNext
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.accentOf(ctx).withValues(alpha: 0.12),
                  ),
                  child: Icon(entry.icon,
                      size: 20,
                      color: isNext ? Colors.white : AppColors.accentOf(ctx)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The "up next" label leads, so it reads as a heading
                      // for the prayer name below it.
                      if (isNext)
                        Text(l10n.upNext,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                            )),
                      Text(entry.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isNext ? Colors.white : onSurface,
                          )),
                    ],
                  ),
                ),
                Text(timeStr,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isNext
                          ? Colors.white
                          : (isDark ? onSurface : AppColors.accentOf(ctx)),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Material Card (Android / non-Apple) ───────────────────────────────────────
class _MaterialCard extends StatelessWidget {
  final _PrayerEntry entry;
  final bool isNext;
  final AppLocalizations l10n;
  const _MaterialCard({
    required this.entry,
    required this.isNext,
    required this.l10n,
  });

  @override
  Widget build(BuildContext ctx) {
    final t = entry.time;
    final timeStr = t == null
        ? '--:--'
        : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    final theme = Theme.of(ctx);
    final onAccent = theme.colorScheme.onPrimary;
    // Follow the theme's flat card (hairline, large radius; Adwaita/Breeze
    // cards on Linux) and fill it with the accent for the next prayer.
    final cardShape = theme.cardTheme.shape ??
        RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
      decoration: ShapeDecoration(
        color: isNext
            ? AppColors.accentOf(ctx)
            : (theme.cardTheme.color ?? theme.cardColor),
        shape: cardShape,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: Icon(entry.icon,
            color: isNext ? onAccent : AppColors.accentOf(ctx), size: 28),
        // The "up next" label leads, so it reads as a heading for the name.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isNext)
              Text(l10n.upNext,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: onAccent.withValues(alpha: 0.7))),
            Text(entry.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isNext ? onAccent : null,
                )),
          ],
        ),
        trailing: Text(timeStr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: isNext ? onAccent : AppColors.accentOf(ctx),
            )),
      ),
    );
  }
}

// ── Hero Countdown Pill ───────────────────────────────────────────────────────
// The metrics of the glass pill around the hero's countdown, shared by its
// hidden layout and the header's moving layer.
abstract final class _HeroBadge {
  static double horizontalPadding({required bool compact}) =>
      compact ? AppSpacing.sm : AppSpacing.md;
  static double verticalPadding({required bool compact}) =>
      compact ? AppSpacing.xxs : AppSpacing.xs;
  static double iconSize({required bool compact}) => compact ? 16 : 20;

  /// The digits' style, white over the accent hero.
  static TextStyle textStyleOf(BuildContext ctx, {required bool compact}) {
    final textTheme = Theme.of(ctx).textTheme;
    final base = compact
        ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : textTheme.titleLarge;
    return (base ?? const TextStyle()).copyWith(
      color: Colors.white,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

/// Glass that fades in or out grows from, or shrinks to, this share of its
/// size, since a lens under an Opacity layer loses its backdrop.
const _glassMinScale = 0.85;

double _glassScale(double fade) => lerpDouble(_glassMinScale, 1, fade)!;

/// The countdown's style in the collapsed capsule.
TextStyle _collapsedCountdownStyle(BuildContext ctx) =>
    (Theme.of(ctx).textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.accentOf(ctx),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

/// [color] with its alpha scaled by [fade].
Color _fadeColor(Color color, double fade) =>
    color.withValues(alpha: color.a * fade);

// ── Material Countdown Badge (non-Apple) ──────────────────────────────────────
class _CountdownBadge extends StatelessWidget {
  final ValueListenable<Duration> remaining;
  const _CountdownBadge({required this.remaining});

  @override
  Widget build(BuildContext ctx) {
    return ValueListenableBuilder<Duration>(
      valueListenable: remaining,
      builder: (_, value, __) => _buildBadge(ctx, value),
    );
  }

  Widget _buildBadge(BuildContext ctx, Duration value) {
    if (value.isNegative) return const SizedBox();
    final theme = Theme.of(ctx);
    final onAccent = theme.colorScheme.onPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      decoration: ShapeDecoration(
        color: onAccent.withValues(alpha: 0.24),
        shape: const StadiumBorder(),
      ),
      child: Text(_formatCountdown(value),
          style: theme.textTheme.titleLarge?.copyWith(
            color: onAccent,
            fontFeatures: const [FontFeature.tabularFigures()],
          )),
    );
  }
}

String _formatClock(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _formatCountdown(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

// ── Prayer Entry model ────────────────────────────────────────────────────────
class _PrayerEntry {
  final String key;
  final String label;
  final IconData icon;
  final DateTime? time;
  _PrayerEntry(this.key, this.label, this.icon, this.time);
}
