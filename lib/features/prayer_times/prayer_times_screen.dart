import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
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
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final next = ref.read(nextPrayerProvider);
    if (next.time != null && mounted) {
      setState(() => _remaining = next.time!.difference(DateTime.now()));
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final state = ref.watch(prayerProvider);
    final next = ref.watch(nextPrayerProvider);
    final nextName = _prayerLabel(l10n, next.key);
    final locationLabel = state.locationLabel ?? '--';
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

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
                    isDark: isDark,
                    onTune: () => _showMethodPicker(ctx),
                    onRefresh: () => ref.read(prayerProvider.notifier).load(),
                  ),
                )
              : SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: AppColors.emerald,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.emerald, AppColors.teal],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    locationLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(nextName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            _CountdownBadge(remaining: _remaining),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.tune, color: Colors.white),
                      onPressed: () => _showMethodPicker(ctx),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
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
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_off,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(state.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    if (state.showLocationGuide)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          l10n.locationGuide,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 4),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => ref.read(prayerProvider.notifier).load(),
                    ),
                  ]),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                SizedBox(height: _isApple ? 8 : 16),
                ..._buildPrayerCards(ctx, state.times!, next.key),
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

  void _showMethodPicker(BuildContext ctx) {
    showCalculationMethodPicker(
      ctx,
      ref,
      current: ref.read(settingsProvider).method,
    );
  }
}

// ── Liquid Glass App Bar ───────────────────────────────────────────────────────
class _LiquidGlassAppBar extends SliverPersistentHeaderDelegate {
  final String nextName;
  final String locationLabel;
  final Duration remaining;
  final bool isDark;
  final VoidCallback onTune;
  final VoidCallback onRefresh;

  const _LiquidGlassAppBar({
    required this.nextName,
    required this.locationLabel,
    required this.remaining,
    required this.isDark,
    required this.onTune,
    required this.onRefresh,
  });

  @override
  double get minExtent => kToolbarHeight + 44;
  @override
  double get maxExtent => 240;

  @override
  bool shouldRebuild(_LiquidGlassAppBar old) =>
      old.nextName != nextName ||
      old.locationLabel != locationLabel ||
      old.remaining != remaining ||
      old.isDark != isDark;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final collapsedProgress = (progress * 2 - 1).clamp(0.0, 1.0);
    final collapsedActionTop = (minExtent - kToolbarHeight) / 2;
    final actionTop = lerpDouble(0, collapsedActionTop, collapsedProgress)!;
    const actionAreaWidth = 116.0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20 * progress, sigmaY: 20 * progress),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.emerald.withValues(alpha: isDark ? 0.9 : 1),
                AppColors.teal.withValues(alpha: isDark ? 0.9 : 1),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: progress > 0.5
                    ? (isDark
                        ? Colors.white.withOpacity(0.1 * progress)
                        : Colors.black.withOpacity(0.08 * progress))
                    : Colors.transparent,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Actions
                Positioned(
                  top: actionTop,
                  right: 4,
                  child: SizedBox(
                    height: kToolbarHeight,
                    child: Center(
                      child: Row(children: [
                        _GlassIconButton(
                          icon: Icons.tune,
                          onTap: onTune,
                          frosted: progress > 0.35,
                          isDark: isDark,
                        ),
                        _GlassIconButton(
                          icon: Icons.refresh,
                          onTap: onRefresh,
                          frosted: progress > 0.35,
                          isDark: isDark,
                        ),
                      ]),
                    ),
                  ),
                ),
                // Expanded content
                Opacity(
                  opacity: (1 - progress * 2).clamp(0.0, 1.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: kToolbarHeight * 0.3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.white.withOpacity(0.75),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(nextName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _LiquidCountdownBadge(remaining: remaining),
                      ],
                    ),
                  ),
                ),
                // Collapsed title
                Opacity(
                  opacity: collapsedProgress,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: actionAreaWidth),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  locationLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.82),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  nextName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _LiquidCountdownBadge(
                              remaining: remaining, compact: true),
                        ],
                      ),
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
}

// ── Glass Icon Button ─────────────────────────────────────────────────────────
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool frosted;
  final bool isDark;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    required this.frosted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: frosted
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.12),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(icon,
                        size: 18,
                        color: isDark ? Colors.white : Colors.black87),
                  ),
                ),
              )
            : Icon(icon, size: 22, color: Colors.white),
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
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final t = entry.time;
    final timeStr = t == null
        ? '--:--'
        : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: isNext ? 28 : 18, sigmaY: isNext ? 28 : 18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isNext
                      ? [
                          AppColors.emerald.withOpacity(0.55),
                          AppColors.teal.withOpacity(0.45),
                        ]
                      : isDark
                          ? [
                              Colors.white.withOpacity(0.09),
                              Colors.white.withOpacity(0.05),
                            ]
                          : [
                              Colors.white.withOpacity(0.72),
                              Colors.white.withOpacity(0.55),
                            ],
                ),
                border: Border.all(
                  color: isNext
                      ? Colors.white.withOpacity(0.3)
                      : (isDark
                          ? Colors.white.withOpacity(0.12)
                          : Colors.white.withOpacity(0.8)),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isNext
                        ? AppColors.emerald.withOpacity(0.2)
                        : Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                    blurRadius: isNext ? 24 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isNext
                          ? Colors.white.withOpacity(0.2)
                          : AppColors.emerald.withOpacity(0.12),
                    ),
                    child: Icon(entry.icon,
                        size: 20,
                        color: isNext ? Colors.white : AppColors.emerald),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              color: isNext
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                            )),
                        if (isNext)
                          Text(l10n.upNext,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.75),
                              )),
                      ],
                    ),
                  ),
                  Text(timeStr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: isNext
                            ? Colors.white
                            : (isDark ? Colors.white : AppColors.emerald),
                      )),
                ],
              ),
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isNext ? AppColors.emerald : Theme.of(ctx).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(entry.icon,
            color: isNext ? Colors.white : AppColors.emerald, size: 28),
        title: Text(entry.label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: isNext ? Colors.white : null,
            )),
        trailing: Text(timeStr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isNext ? Colors.white : AppColors.emerald,
            )),
        subtitle: isNext
            ? Text(l10n.upNext,
                style: const TextStyle(color: Colors.white70, fontSize: 12))
            : null,
      ),
    );
  }
}

// ── Liquid Countdown Badge ────────────────────────────────────────────────────
class _LiquidCountdownBadge extends StatelessWidget {
  final Duration remaining;
  final bool compact;
  const _LiquidCountdownBadge({required this.remaining, this.compact = false});

  @override
  Widget build(BuildContext ctx) {
    if (remaining.isNegative) return const SizedBox();
    final h = remaining.inHours.toString().padLeft(2, '0');
    final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final radius = compact ? 16.0 : 22.0;
    final fontSize = compact ? 15.0 : 22.0;
    final horizontal = compact ? 12.0 : 22.0;
    final vertical = compact ? 6.0 : 10.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: compact ? 8 : 12,
          sigmaY: compact ? 8 : 12,
        ),
        child: Container(
          padding:
              EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(radius),
            border:
                Border.all(color: Colors.white.withOpacity(0.35), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text('$h:$m:$s',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
        ),
      ),
    );
  }
}

// ── Material Countdown Badge (non-Apple) ──────────────────────────────────────
class _CountdownBadge extends StatelessWidget {
  final Duration remaining;
  const _CountdownBadge({required this.remaining});

  @override
  Widget build(BuildContext ctx) {
    if (remaining.isNegative) return const SizedBox();
    final h = remaining.inHours.toString().padLeft(2, '0');
    final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$h:$m:$s',
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }
}

// ── Prayer Entry model ────────────────────────────────────────────────────────
class _PrayerEntry {
  final String key;
  final String label;
  final IconData icon;
  final DateTime? time;
  _PrayerEntry(this.key, this.label, this.icon, this.time);
}
