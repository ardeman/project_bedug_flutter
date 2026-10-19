import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/services/prayer_service.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/widgets/calculation_method_picker.dart';

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
                  expandedHeight: 200,
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
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
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
                    FilledButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                      onPressed: () => ref.read(prayerProvider.notifier).load(),
                    ),
                  ]),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                SizedBox(height: _isApple ? AppSpacing.xs : AppSpacing.md),
                ..._buildPrayerCards(ctx, state.times!, next.key),
                if (state.schedule.isNotEmpty)
                  _ScheduleSection(schedule: state.schedule, l10n: l10n),
                // Room to scroll the last card clear of the floating nav bar.
                const SizedBox(height: 100),
              ]),
            ),
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

  List<Widget> _buildPrayerCards(
      BuildContext ctx, dynamic times, String nextKey) {
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
  double get maxExtent => 240;

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
  Widget build(BuildContext ctx) {
    const size = _LiquidGlassAppBar._actionSize;
    return LiquidGlassButton(
      icon: icon,
      onPressed: onTap,
      width: size,
      height: size,
      padding: EdgeInsets.zero,
      iconSize: 20,
      foregroundColor: color,
      style: LiquidGlassStyle(
        shape: const LiquidGlassShape.continuousRoundedRectangle(
            cornerRadius: size / 2),
        color: glassTintOf(ctx),
      ),
    );
  }
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
                      Text(entry.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isNext ? Colors.white : onSurface,
                          )),
                      if (isNext)
                        Text(l10n.upNext,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
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
        title: Text(entry.label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isNext ? onAccent : null,
            )),
        trailing: Text(timeStr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: isNext ? onAccent : AppColors.accentOf(ctx),
            )),
        subtitle: isNext
            ? Text(l10n.upNext,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: onAccent.withValues(alpha: 0.7)))
            : null,
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
// ── 30-day schedule ───────────────────────────────────────────────────────────
// A compact table, one row per day, below today's cards. Lite glass on Apple
// (it scrolls with the list), the theme's flat card elsewhere.
class _ScheduleSection extends StatelessWidget {
  final List<PrayerTimes> schedule;
  final AppLocalizations l10n;
  const _ScheduleSection({required this.schedule, required this.l10n});

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(ctx);
    final isLandscape = mq.orientation == Orientation.landscape;
    final sideInsetLeft = isLandscape ? mq.padding.left : 0.0;
    final sideInsetRight = isLandscape ? mq.padding.right : 0.0;
    final dateFormat =
        DateFormat.MMMEd(Localizations.localeOf(ctx).toLanguageTag());
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final timeStyle = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final todayStyle = timeStyle?.copyWith(
      color: AppColors.accentOf(ctx),
      fontWeight: FontWeight.w700,
    );

    final table = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Column(
        children: [
          _ScheduleRow(
            date: const SizedBox.shrink(),
            cells: [
              for (final name in [
                l10n.fajr,
                l10n.sunrise,
                l10n.dhuhr,
                l10n.asr,
                l10n.maghrib,
                l10n.isha,
              ])
                Text(name, style: headerStyle),
            ],
          ),
          for (final (i, day) in schedule.indexed) ...[
            Divider(
                height: 1, color: theme.dividerColor.withValues(alpha: 0.4)),
            _ScheduleRow(
              date: Text(
                dateFormat.format(_dateOf(day)),
                style: i == 0 ? todayStyle : timeStyle,
              ),
              cells: [
                for (final t in [
                  day.fajr,
                  day.sunrise,
                  day.dhuhr,
                  day.asr,
                  day.maghrib,
                  day.isha,
                ])
                  Text(_hhmm(t), style: i == 0 ? todayStyle : timeStyle),
              ],
            ),
          ],
        ],
      ),
    );

    final card = _isApple
        ? Material(
            color: Colors.transparent,
            child: LiquidGlassLite(
              shape: const LiquidGlassShape.continuousRoundedRectangle(
                  cornerRadius: AppRadii.lg),
              blur: 10,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.62),
              child: table,
            ),
          )
        : DecoratedBox(
            decoration: ShapeDecoration(
              color: theme.cardTheme.color ?? theme.cardColor,
              shape: theme.cardTheme.shape ??
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.lg)),
            ),
            child: table,
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md + sideInsetLeft,
        AppSpacing.lg,
        AppSpacing.md + sideInsetRight,
        AppSpacing.xxs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.xxs, bottom: AppSpacing.xs),
            child: Text(l10n.nextDaysSchedule(schedule.length),
                style: theme.textTheme.titleMedium),
          ),
          card,
        ],
      ),
    );
  }

  static DateTime _dateOf(PrayerTimes day) {
    final d = day.dateComponents;
    return DateTime(d.year, d.month, d.day);
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _ScheduleRow extends StatelessWidget {
  final Widget date;
  final List<Widget> cells;
  const _ScheduleRow({required this.date, required this.cells});

  @override
  Widget build(BuildContext ctx) {
    // Scale down rather than clip, so long names and dates fit narrow phones.
    Widget fit(Widget child, AlignmentGeometry alignment) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: child,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          // The date column is wider than a time column.
          Expanded(flex: 3, child: fit(date, AlignmentDirectional.centerStart)),
          for (final c in cells)
            Expanded(flex: 2, child: fit(c, Alignment.center)),
        ],
      ),
    );
  }
}

class _PrayerEntry {
  final String key;
  final String label;
  final IconData icon;
  final DateTime? time;
  _PrayerEntry(this.key, this.label, this.icon, this.time);
}
