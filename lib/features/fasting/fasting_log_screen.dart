import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/material_controls.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/hijri_utils.dart';
import '../../core/widgets/glass_menu.dart';
import '../../generated/l10n/app_localizations.dart';
import 'fasting_log.dart';
import 'ramadan.dart';

String fastStatusLabel(AppLocalizations l10n, FastStatus status) =>
    switch (status) {
      FastStatus.fasted => l10n.fastStatusFasted,
      FastStatus.missed => l10n.fastStatusMissed,
      FastStatus.excused => l10n.fastStatusExcused,
      FastStatus.qada => l10n.fastStatusQada,
    };

/// The Ramadan fasts, day by day, and the make-up fasts still owed for the
/// missed and excused ones. Earlier Ramadans stay one tap back.
class FastingLogScreen extends ConsumerStatefulWidget {
  const FastingLogScreen({super.key});

  @override
  ConsumerState<FastingLogScreen> createState() => _FastingLogScreenState();
}

class _FastingLogScreenState extends ConsumerState<FastingLogScreen> {
  /// The Hijri year shown, or null for the latest Ramadan that has begun.
  int? _year;

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final reckoning = ref.watch(
      settingsProvider.select((s) => s.hijriReckoning),
    );
    final log = ref.watch(fastingLogProvider);
    final now = clock.now();
    final today = DateTime(now.year, now.month, now.day);
    final latest = currentOrLastRamadan(today, reckoning);
    final shown = _year == null || latest == null || _year! >= latest.hijriYear
        ? latest
        : ramadanOf(_year!, reckoning);
    final upcoming = currentOrNextRamadan(today, reckoning);

    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: l10n.fastingLog),
      body: Center(
        child: ConstrainedBox(
          // Keep the grid compact on wide desktop windows.
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            // The system's padding too: on Apple the list runs under the
            // glass top bar and the floating nav bar. This context is above
            // the Scaffold, so its padding lacks the top bar's height.
            padding:
                MediaQuery.paddingOf(ctx) +
                EdgeInsets.only(
                  top: PlatformCapabilities.isApple ? kToolbarHeight : 0,
                ) +
                const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.sm,
                ),
            children: [
              if (shown != null)
                _RamadanLogCard(
                  month: shown,
                  today: today,
                  log: log,
                  canGoBack: ramadanOf(shown.hijriYear - 1, reckoning) != null,
                  canGoForward:
                      latest != null && shown.hijriYear < latest.hijriYear,
                  onYear: (year) => setState(() => _year = year),
                  onStatus: (day, status) =>
                      ref.read(fastingLogProvider.notifier).set(day, status),
                ),
              if (upcoming != null && !upcoming.contains(today))
                _Note(
                  l10n.fastingLogBegins(
                    DateFormat.yMMMMd(
                      Localizations.localeOf(ctx).toLanguageTag(),
                    ).format(upcoming.start),
                    upcoming.hijriYear,
                  ),
                ),
              _QadaCard(
                log: log,
                today: today,
                canLogToday: qadaAllowedOn(today, reckoning),
              ),
              _Note(l10n.fastingLogHint),
              _Note(
                l10n.hijriEventsNote(hijriSourceLabel(l10n, reckoning.source)),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _Note(this.text, {this.style});

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: (style ?? theme.textTheme.bodyMedium)?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _RamadanLogCard extends StatelessWidget {
  final RamadanMonth month;
  final DateTime today;
  final FastingLog log;
  final bool canGoBack;
  final bool canGoForward;
  final ValueChanged<int> onYear;
  final void Function(DateTime day, FastStatus? status) onStatus;

  const _RamadanLogCard({
    required this.month,
    required this.today,
    required this.log,
    required this.canGoBack,
    required this.canGoForward,
    required this.onYear,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final fasted = month.days
        .where((day) => log.statusOn(day) == FastStatus.fasted)
        .length;
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _ArrowButton(
                  icon: Icons.chevron_left,
                  onTap: canGoBack ? () => onYear(month.hijriYear - 1) : null,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.fastingLogRamadan(month.hijriYear),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.fastingLogFasted(fasted, month.length),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _ArrowButton(
                  icon: Icons.chevron_right,
                  onTap: canGoForward
                      ? () => onYear(month.hijriYear + 1)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (var n = 1; n <= month.length; n++)
                  _DayCell(
                    number: n,
                    status: log.statusOn(month.day(n)),
                    isToday: month.day(n) == today,
                    // A day can be logged once it has begun.
                    onPick: month.day(n).isAfter(today)
                        ? null
                        : (status) => onStatus(month.day(n), status),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  // A comfortable touch target around the 24-point icon.
  static const _size = 40.0;

  @override
  Widget build(BuildContext ctx) {
    final color = onTap == null
        ? Theme.of(ctx).disabledColor
        : AppColors.accentOf(ctx);
    // Mirrored for right-to-left text, so back still points to the start.
    final arrow = Icon(icon, color: color);
    if (!PlatformCapabilities.isApple) {
      return IconButton(onPressed: onTap, icon: arrow);
    }
    return GlassPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_size / 2),
      child: SizedBox.square(dimension: _size, child: arrow),
    );
  }
}

/// The choices a Ramadan day offers, with clearing it as [none].
enum _DayChoice { fasted, missed, excused, none }

class _DayCell extends StatefulWidget {
  final int number;
  final FastStatus? status;
  final bool isToday;

  /// Null for a day still ahead.
  final ValueChanged<FastStatus?>? onPick;

  const _DayCell({
    required this.number,
    required this.status,
    required this.isToday,
    required this.onPick,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  /// Guards against a second menu stacking on repeated taps.
  bool _isMenuOpen = false;

  // Seven to a row fit a phone's card; large enough to tap.
  static const _size = 40.0;

  FastStatus? _statusOf(_DayChoice choice) => switch (choice) {
    _DayChoice.fasted => FastStatus.fasted,
    _DayChoice.missed => FastStatus.missed,
    _DayChoice.excused => FastStatus.excused,
    _DayChoice.none => null,
  };

  _DayChoice get _current => switch (widget.status) {
    FastStatus.fasted => _DayChoice.fasted,
    FastStatus.missed => _DayChoice.missed,
    FastStatus.excused => _DayChoice.excused,
    FastStatus.qada || null => _DayChoice.none,
  };

  Future<void> _open() async {
    final onPick = widget.onPick;
    if (_isMenuOpen || onPick == null) return;
    _isMenuOpen = true;
    final l10n = AppLocalizations.of(context);
    final labels = {
      _DayChoice.fasted: l10n.fastStatusFasted,
      _DayChoice.missed: l10n.fastStatusMissed,
      _DayChoice.excused: l10n.fastStatusExcused,
      _DayChoice.none: l10n.fastStatusNone,
    };
    final title = l10n.ramadanTitle(widget.number);
    final anchor = globalRectOf(context);
    try {
      if (PlatformCapabilities.isApple) {
        await showGlassMenu<_DayChoice>(
          context,
          anchor: anchor,
          title: title,
          options: [
            for (final MapEntry(:key, :value) in labels.entries)
              GlassMenuOption(
                value: key,
                label: value,
                note: key == _DayChoice.excused
                    ? l10n.fastStatusExcusedNote
                    : null,
              ),
          ],
          selected: _current,
          onSelected: (choice) => onPick(_statusOf(choice)),
        );
      } else {
        final overlay =
            Overlay.of(context).context.findRenderObject()! as RenderBox;
        final choice = await showMenu<_DayChoice>(
          context: context,
          position: RelativeRect.fromRect(anchor, Offset.zero & overlay.size),
          items: [
            for (final MapEntry(:key, :value) in labels.entries)
              CheckedPopupMenuItem(
                value: key,
                checked: key == _current,
                child: key == _DayChoice.excused
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(value),
                          Text(
                            l10n.fastStatusExcusedNote,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      )
                    : Text(value),
              ),
          ],
        );
        if (choice != null) onPick(_statusOf(choice));
      }
    } finally {
      _isMenuOpen = false;
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final scheme = theme.colorScheme;
    final accent = AppColors.accentOf(ctx);
    final (Color? fill, Color text, Color border) = switch (widget.status) {
      FastStatus.fasted => (accent, scheme.onPrimary, accent),
      FastStatus.excused => (
        scheme.tertiary,
        scheme.onTertiary,
        scheme.tertiary,
      ),
      FastStatus.missed => (null, scheme.error, scheme.error),
      FastStatus.qada || null => (
        null,
        widget.onPick == null ? theme.disabledColor : scheme.onSurface,
        widget.isToday ? accent : scheme.outlineVariant,
      ),
    };
    final label = widget.status == null
        ? l10n.fastStatusNone
        : fastStatusLabel(l10n, widget.status!);
    final cell = Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: widget.isToday ? 2 : 1),
      ),
      child: Text(
        '${widget.number}',
        style: theme.textTheme.labelLarge?.copyWith(
          color: text,
          fontWeight: widget.isToday ? FontWeight.bold : null,
        ),
      ),
    );
    return Semantics(
      button: widget.onPick != null,
      label: '${l10n.ramadanTitle(widget.number)}, $label',
      excludeSemantics: true,
      child: PlatformCapabilities.isApple
          ? GlassPressable(
              onTap: widget.onPick == null ? null : _open,
              borderRadius: BorderRadius.circular(_size / 2),
              child: cell,
            )
          : InkWell(
              onTap: widget.onPick == null ? null : _open,
              customBorder: const CircleBorder(),
              child: cell,
            ),
    );
  }
}

class _QadaCard extends ConsumerWidget {
  final FastingLog log;
  final DateTime today;

  /// False on days a make-up fast can't be kept ([qadaAllowedOn]).
  final bool canLogToday;

  const _QadaCard({
    required this.log,
    required this.today,
    required this.canLogToday,
  });

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final loggedToday = log.statusOn(today) == FastStatus.qada;
    final locale = Localizations.localeOf(ctx).toLanguageTag();
    final made = log.qadaDays;
    void toggle() => ref
        .read(fastingLogProvider.notifier)
        .set(today, loggedToday ? null : FastStatus.qada);
    final icon = loggedToday ? Icons.undo : Icons.add;
    final label = loggedToday ? l10n.qadaUndoToday : l10n.qadaLogToday;

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.qadaTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              l10n.qadaOwed(log.qadaOwed),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.accentOf(ctx),
              ),
            ),
            if (made.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                made.map(DateFormat.yMMMd(locale).format).join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (canLogToday || loggedToday) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: PlatformCapabilities.isApple
                    ? GlassPillButton(
                        icon: icon,
                        label: label,
                        onPressed: toggle,
                      )
                    : MaterialLabelButton(
                        icon: Icon(icon),
                        label: Text(label),
                        onPressed: toggle,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
