import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/time_format.dart';
import '../../generated/l10n/app_localizations.dart';
import 'fasting_log.dart';
import 'fasting_log_screen.dart';
import 'ramadan.dart';

/// In Ramadan, a countdown to the end of sahur (imsak) or to iftar
/// (Maghrib), from Maghrib the evening before each fast. Hidden when no
/// fast is ahead. Tapping it opens the fasting log.
class RamadanCard extends ConsumerStatefulWidget {
  /// Today's times, which give the place and calculation method.
  final PrayerTimes times;

  const RamadanCard({super.key, required this.times});

  @override
  ConsumerState<RamadanCard> createState() => _RamadanCardState();
}

class _RamadanCardState extends ConsumerState<RamadanCard> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final now = clock.now();
    final countdown = ramadanCountdownAt(
      widget.times,
      now,
      ref.watch(settingsProvider.select((s) => s.hijriReckoning)),
    );
    if (countdown == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final accent = AppColors.accentOf(ctx);
    final mq = MediaQuery.of(ctx);
    final status = ref.watch(fastingLogProvider).statusOn(countdown.fastDay);
    final isSahur = countdown.phase == RamadanPhase.sahur;
    final remaining = countdown.target.difference(now);
    final span = countdown.target.difference(countdown.since).inSeconds;
    final elapsed = span <= 0
        ? 1.0
        : (1 - remaining.inSeconds / span).clamp(0.0, 1.0);
    final detail = isSahur
        ? '${l10n.imsak} ${formatClock(countdown.target)} · '
              '${l10n.fajr} ${formatClock(countdown.fajr)}'
        : '${l10n.maghrib} ${formatClock(countdown.target)}';

    return Semantics(
      button: true,
      onTapHint: l10n.ramadanOpenLog,
      child: GlassCard(
        margin: EdgeInsets.fromLTRB(
          AppSpacing.md + mq.padding.left,
          AppSpacing.sm,
          AppSpacing.md + mq.padding.right,
          AppSpacing.xxs,
        ),
        onTap: () => Navigator.of(ctx).push(
          MaterialPageRoute<void>(builder: (_) => const FastingLogScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // Matches the title's line height.
                  Icon(
                    isSahur ? Icons.dark_mode_outlined : Icons.wb_twilight,
                    size: 18,
                    color: accent,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.ramadanTitle(countdown.ramadanDay),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (status != null)
                    Text(
                      fastStatusLabel(l10n, status),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSahur
                              ? l10n.ramadanUntilImsak
                              : l10n.ramadanUntilIftar,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: accent,
                          ),
                        ),
                        Text(
                          detail,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatCountdown(
                      remaining.isNegative ? Duration.zero : remaining,
                    ),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _ProgressTrack(value: elapsed, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// A thin bar that fills as the countdown nears its end. Drawn by hand, so
/// the Apple path has no Material progress indicator.
class _ProgressTrack extends StatelessWidget {
  final double value;
  final Color color;

  const _ProgressTrack({required this.value, required this.color});

  // Thick enough to read at a glance, thin enough to stay a hairline.
  static const _height = 4.0;

  @override
  Widget build(BuildContext ctx) => ClipRRect(
    borderRadius: BorderRadius.circular(_height / 2),
    child: SizedBox(
      height: _height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: color.withValues(alpha: 0.18)),
          FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: value,
            child: ColoredBox(color: color),
          ),
        ],
      ),
    ),
  );
}
