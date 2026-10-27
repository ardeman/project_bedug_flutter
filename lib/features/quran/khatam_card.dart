import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/material_controls.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/theme/app_tokens.dart';
import '../../generated/l10n/app_localizations.dart';
import 'khatam.dart';
import 'quran.dart';
import 'quran_reader_screen.dart';

/// The khatam planner at the top of the Quran tab: picking a plan length,
/// then today's portion and the progress so far, with a way to continue.
class KhatamCard extends ConsumerStatefulWidget {
  final QuranIndex index;
  final EdgeInsetsGeometry margin;

  const KhatamCard({super.key, required this.index, required this.margin});

  @override
  ConsumerState<KhatamCard> createState() => _KhatamCardState();
}

class _KhatamCardState extends ConsumerState<KhatamCard> {
  /// Whether a running plan is being changed.
  var _changing = false;

  /// A juz a day by default.
  var _days = 30;

  KhatamNotifier get _notifier => ref.read(khatamProvider.notifier);

  @override
  Widget build(BuildContext ctx) {
    final plan = ref.watch(khatamProvider);
    final today = DateTime.now();
    return GlassCard(
      margin: widget.margin,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: plan == null || _changing
              ? _setup(ctx, today, plan)
              : plan.isComplete(widget.index)
              ? _complete(ctx)
              : _running(ctx, today, plan),
        ),
      ),
    );
  }

  List<Widget> _setup(BuildContext ctx, DateTime today, KhatamPlan? plan) {
    final l10n = AppLocalizations.of(ctx);
    final finish = DateTime(today.year, today.month, today.day + _days - 1);
    return [
      _Heading(icon: Icons.flag_outlined, title: l10n.khatamPlanner),
      const SizedBox(height: AppSpacing.xs),
      _Muted(l10n.khatamSetupHint),
      const SizedBox(height: AppSpacing.sm),
      PlatformSegmentedControl<int>(
        segments: {for (final d in khatamDurations) d: l10n.khatamDays(d)},
        value: _days,
        onChanged: (days) => setState(() => _days = days),
      ),
      const SizedBox(height: AppSpacing.sm),
      _Muted(l10n.khatamFinishBy(_formatDate(ctx, finish))),
      const SizedBox(height: AppSpacing.sm),
      _Actions([
        if (plan != null)
          _Action(
            icon: Icons.close,
            label: l10n.cancel,
            onPressed: () => setState(() => _changing = false),
          ),
        _Action(
          icon: Icons.play_arrow,
          label: l10n.khatamStart,
          primary: true,
          onPressed: () {
            _notifier.start(today: today, days: _days);
            setState(() => _changing = false);
          },
        ),
      ]),
    ];
  }

  List<Widget> _running(BuildContext ctx, DateTime today, KhatamPlan plan) {
    final l10n = AppLocalizations.of(ctx);
    final languageCode = Localizations.localeOf(ctx).languageCode;
    final index = widget.index;
    final target = plan.targetFor(index, today);
    final reached = plan.reached;
    final todayDone = reached != null && reached.compareTo(target) >= 0;
    final progress = juzProgress(index, reached) / index.juzStarts.length;
    return [
      _Heading(
        icon: Icons.flag,
        title: l10n.khatamFinishBy(_formatDate(ctx, plan.finish)),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        todayDone
            ? l10n.khatamTodayDone
            : l10n.khatamTodayTarget(
                index.surah(target.surah).nameFor(languageCode),
                target.ayah,
              ),
        style: Theme.of(ctx).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpacing.sm),
      _ProgressBar(value: progress),
      const SizedBox(height: AppSpacing.xs),
      _Muted(
        '${l10n.khatamPercentRead((progress * 100).floor())} · '
        '${l10n.khatamDaysLeft(plan.daysLeft(today))}',
      ),
      const SizedBox(height: AppSpacing.sm),
      _Actions([
        _Action(
          icon: Icons.stop,
          label: l10n.khatamEnd,
          onPressed: _notifier.end,
        ),
        _Action(
          icon: Icons.edit_calendar,
          label: l10n.khatamChange,
          onPressed: () => setState(() {
            if (khatamDurations.contains(plan.days)) _days = plan.days;
            _changing = true;
          }),
        ),
        _Action(
          icon: Icons.auto_stories,
          label: l10n.quranContinueReading,
          primary: true,
          onPressed: () {
            final next = plan.next(index);
            Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                builder: (_) => QuranReaderScreen(
                  surah: next.surah,
                  initialAyah: next.ayah,
                ),
              ),
            );
          },
        ),
      ]),
    ];
  }

  List<Widget> _complete(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    return [
      _Heading(icon: Icons.celebration, title: l10n.khatamComplete),
      const SizedBox(height: AppSpacing.sm),
      const _ProgressBar(value: 1),
      const SizedBox(height: AppSpacing.sm),
      _Actions([
        _Action(
          icon: Icons.add,
          label: l10n.khatamNewPlan,
          primary: true,
          onPressed: _notifier.end,
        ),
      ]),
    ];
  }

  String _formatDate(BuildContext ctx, DateTime date) =>
      DateFormat.MMMMd(Localizations.localeOf(ctx).languageCode).format(date);
}

class _Heading extends StatelessWidget {
  final IconData icon;
  final String title;

  const _Heading({required this.icon, required this.title});

  @override
  Widget build(BuildContext ctx) => Row(
    children: [
      Icon(icon, color: AppColors.accentOf(ctx)),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(title, style: Theme.of(ctx).textTheme.titleMedium)),
    ],
  );
}

class _Muted extends StatelessWidget {
  final String text;

  const _Muted(this.text);

  @override
  Widget build(BuildContext ctx) => Text(
    text,
    style: Theme.of(ctx).textTheme.bodyMedium
        ?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
  );
}

/// A plain bar rather than Material's indicator, which has no place on the
/// Apple path.
class _ProgressBar extends StatelessWidget {
  final double value;

  const _ProgressBar({required this.value});

  static const _height = 6.0;

  @override
  Widget build(BuildContext ctx) {
    final accent = AppColors.accentOf(ctx);
    return ClipRRect(
      borderRadius: BorderRadius.circular(_height / 2),
      child: Container(
        height: _height,
        color: accent.withValues(alpha: 0.15),
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1),
          heightFactor: 1,
          child: ColoredBox(color: accent),
        ),
      ),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  const _Action({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });
}

/// The card's buttons, wrapping onto a second line when they don't fit.
class _Actions extends StatelessWidget {
  final List<_Action> actions;

  const _Actions(this.actions);

  @override
  Widget build(BuildContext ctx) => Wrap(
    alignment: WrapAlignment.end,
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xs,
    children: [
      for (final action in actions)
        PlatformCapabilities.isApple
            ? GlassPillButton(
                icon: action.icon,
                label: action.label,
                onPressed: action.onPressed,
              )
            : MaterialLabelButton(
                icon: Icon(action.icon),
                label: Text(action.label),
                filled: action.primary,
                onPressed: action.onPressed,
              ),
    ],
  );
}
