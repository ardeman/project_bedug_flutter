import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/hijri_utils.dart';
import '../../generated/l10n/app_localizations.dart';
import '../prayer_times/widgets/hijri_month_grid.dart' show hijriDateLabel;
import '../prayer_times/widgets/prayer_day_picker.dart' show daysBetween;
import 'hijri_events.dart';

/// The events on the Hijri calendar in the year ahead, each with its
/// Gregorian and Hijri date and how far off it is.
class HijriEventsScreen extends ConsumerWidget {
  const HijriEventsScreen({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final l10n = AppLocalizations.of(ctx);
    final events = ref.watch(hijriEventsProvider);
    final reckoning = ref.watch(
      settingsProvider.select((s) => s.hijriReckoning),
    );
    final now = clock.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: l10n.hijriEvents),
      body: events.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(l10n.hijriEventsLoadError, textAlign: TextAlign.center),
          ),
        ),
        data: (events) {
          final upcoming = events.upcoming(today, reckoning: reckoning);
          return Center(
            child: ConstrainedBox(
              // Keep lines readable on wide desktop windows.
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView.builder(
                // A gap, the event days, then the note on the dates.
                itemCount: upcoming.length + 2,
                itemBuilder: (ctx, i) => i == 0
                    ? const SizedBox(height: AppSpacing.sm)
                    : i <= upcoming.length
                    ? _EventCard(
                        day: upcoming[i - 1].day,
                        events: upcoming[i - 1].events,
                        daysAway: daysBetween(today, upcoming[i - 1].day),
                        hijriReckoning: reckoning,
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        child: Text(
                          l10n.hijriEventsNote(
                            hijriSourceLabel(l10n, reckoning.source),
                          ),
                          textAlign: TextAlign.center,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final DateTime day;
  final List<HijriEvent> events;
  final int daysAway;
  final HijriReckoning hijriReckoning;

  const _EventCard({
    required this.day,
    required this.events,
    required this.daysAway,
    required this.hijriReckoning,
  });

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);
    final locale = Localizations.localeOf(ctx);
    final languageCode = locale.languageCode;
    final hijriDate = hijriDateLabel(l10n, day, hijriReckoning);
    final date = DateFormat.yMMMMEEEEd(locale.toLanguageTag()).format(day);

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    events.map((e) => e.nameFor(languageCode)).join(' · '),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    hijriDate == null ? date : '$hijriDate · $date',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.hijriEventsWhen(daysAway),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.accentOf(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
