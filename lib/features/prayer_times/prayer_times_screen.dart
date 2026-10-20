import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:adhan/adhan.dart';
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
      _remaining.value = next.time!.difference(DateTime.now());
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
    final minCollapsedExtent = kToolbarHeight +
        (isIosPortrait ? (topInset + 8).clamp(44.0, 62.0) : 44.0);

    return Scaffold(
      extendBodyBehindAppBar: _isApple,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          _isApple
              ? SliverPersistentHeader(
                  pinned: true,
                  delegate: _LiquidGlassAppBar(
                    nextName: nextName,
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
  final String nextName;
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
    required this.nextName,
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
  static const expandedExtent = 240.0;

  @override
  bool shouldRebuild(_LiquidGlassAppBar old) =>
      old.nextName != nextName ||
      old.locationLabel != locationLabel ||
      old.remaining != remaining ||
      old.minCollapsedExtent != minCollapsedExtent ||
      old.isIosPortrait != isIosPortrait ||
      old.topInset != topInset ||
      old.isDark != isDark;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(ctx);
    final textTheme = theme.textTheme;
    final onSurface = theme.colorScheme.onSurface;
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final collapsedProgress = (progress * 2 - 1).clamp(0.0, 1.0);
    final isLargeInsetIosPortrait = isIosPortrait && topInset >= 54;
    final collapsedActionTop = isIosPortrait
        ? (isLargeInsetIosPortrait ? 0.0 : 2.0)
        : ((minExtent - kToolbarHeight) / 2).clamp(0.0, 22.0);
    final iosPortraitLift =
        isLargeInsetIosPortrait ? ((topInset - 54) / 2).clamp(0.0, 3.0) : 0.0;
    final actionTop = lerpDouble(0, collapsedActionTop, collapsedProgress)!;
    // Two buttons, the gap between them, the right inset and the gap to
    // the title capsule.
    const actionAreaWidth =
        _actionSize * 2 + AppSpacing.xs + AppSpacing.sm + AppSpacing.md;
    // White over the accent hero, the text color once it has faded.
    final actionColor = Color.lerp(Colors.white, onSurface, progress)!;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Hero background, fading out as the bar collapses.
        IgnorePointer(
          child: Opacity(
            opacity: 1 - progress,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accentOf(ctx).withValues(alpha: isDark ? 0.9 : 1),
                    AppColors.secondaryOf(ctx)
                        .withValues(alpha: isDark ? 0.9 : 1),
                  ],
                ),
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
          child: Stack(
            children: [
              // Expanded content
              IgnorePointer(
                child: Opacity(
                  opacity: (1 - progress * 2).clamp(0.0, 1.0),
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxHeight < 150;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                height: compact
                                    ? AppSpacing.xs
                                    : kToolbarHeight * 0.3),
                            if (!compact)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                  const SizedBox(width: AppSpacing.xxs),
                                  Flexible(
                                    child: Text(
                                      locationLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (!compact)
                              const SizedBox(height: AppSpacing.xxs),
                            Text(
                              nextName,
                              style: (compact
                                      ? textTheme.headlineSmall
                                      : textTheme.headlineMedium)
                                  ?.copyWith(color: Colors.white),
                            ),
                            SizedBox(
                                height:
                                    compact ? AppSpacing.xs : AppSpacing.sm),
                            _LiquidCountdownBadge(
                              remaining: remaining,
                              compact: compact,
                              visible: progress < 0.5,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Collapsed title, in a floating glass capsule
              IgnorePointer(
                child: Opacity(
                  opacity: collapsedProgress,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: AppSpacing.md, right: actionAreaWidth),
                      child: SizedBox(
                        height: _capsuleHeight,
                        child: LiquidGlassLens(
                          visibility: collapsedProgress > 0,
                          style: LiquidGlassStyle(
                            shape: const LiquidGlassShape
                                .continuousRoundedRectangle(
                                cornerRadius: _capsuleHeight / 2),
                            color: glassTintOf(ctx),
                            blur: 6,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        locationLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodySmall?.copyWith(
                                          color:
                                              onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      Text(
                                        nextName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.titleMedium
                                            ?.copyWith(color: onSurface),
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
                                          style:
                                              textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accentOf(ctx),
                                            fontFeatures: const [
                                              FontFeature.tabularFigures()
                                            ],
                                          ),
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
      ],
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
                      colors: [
                        AppColors.accentOf(ctx).withValues(alpha: 0.55),
                        AppColors.secondaryOf(ctx).withValues(alpha: 0.45),
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

// ── Liquid Countdown Badge ────────────────────────────────────────────────────
// A glass capsule that refracts the accent hero behind it.
class _LiquidCountdownBadge extends StatelessWidget {
  final ValueListenable<Duration> remaining;
  final bool compact;

  /// False once the hero has faded, so the lens stops reading the backdrop.
  final bool visible;
  const _LiquidCountdownBadge({
    required this.remaining,
    this.compact = false,
    this.visible = true,
  });

  @override
  Widget build(BuildContext ctx) {
    return ValueListenableBuilder<Duration>(
      valueListenable: remaining,
      builder: (_, value, __) => _buildBadge(ctx, value),
    );
  }

  Widget _buildBadge(BuildContext ctx, Duration value) {
    if (value.isNegative) return const SizedBox();
    final textTheme = Theme.of(ctx).textTheme;
    final style = compact
        ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : textTheme.titleLarge;
    final horizontal = compact ? AppSpacing.sm : AppSpacing.lg;
    final vertical = compact ? AppSpacing.xxs : AppSpacing.xs;

    return LiquidGlassLens(
      visibility: visible,
      style: LiquidGlassStyle(
        // Taller than the badge, so the corners form a pill.
        shape: const LiquidGlassShape.continuousRoundedRectangle(
            cornerRadius: AppRadii.xl),
        color: Colors.white.withValues(alpha: 0.14),
      ),
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
        child: Text(_formatCountdown(value),
            style: style?.copyWith(
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
      ),
    );
  }
}

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
