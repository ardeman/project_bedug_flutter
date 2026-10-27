import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/selection_feedback.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/recitation_card.dart';
import '../../generated/l10n/app_localizations.dart';
import 'dzikir.dart';

/// Dzikir from the collection picked in Settings, split into morning and
/// evening when the collection has sessions, or the after-prayer dzikir.
class DzikirScreen extends ConsumerStatefulWidget {
  const DzikirScreen({super.key}) : afterPrayer = false;

  const DzikirScreen.afterPrayer({super.key}) : afterPrayer = true;

  /// Shows [afterPrayerDzikirProvider] instead of the picked collection.
  final bool afterPrayer;

  @override
  ConsumerState<DzikirScreen> createState() => _DzikirScreenState();
}

class _DzikirScreenState extends ConsumerState<DzikirScreen> {
  late DzikirSession _session = _currentSession();

  /// Recitations counted on each item while the screen is open.
  final _counts = <DzikirItem, int>{};

  void _count(DzikirItem item) {
    final count = _counts[item] ?? 0;
    if (count >= item.repeat) return;
    SelectionFeedback.tick();
    setState(() => _counts[item] = count + 1);
  }

  void _reset(DzikirItem item) {
    if (!_counts.containsKey(item)) return;
    SelectionFeedback.tick();
    setState(() => _counts.remove(item));
  }

  String _badge(AppLocalizations l10n, DzikirItem item) {
    final count = _counts[item] ?? 0;
    return count == 0 || count >= item.repeat
        ? l10n.dzikirRepeat(item.repeat)
        : l10n.dzikirProgress(count, item.repeat);
  }

  /// Opens on the session for the time of day, using today's Subuh and Asar
  /// when the prayer times are loaded.
  DzikirSession _currentSession() {
    final now = clock.now();
    final times = ref.read(prayerProvider).times;
    final fajr = times?.fajr.toLocal();
    final isToday =
        fajr != null &&
        fajr.year == now.year &&
        fajr.month == now.month &&
        fajr.day == now.day;
    return dzikirSessionAt(
      now,
      fajr: isToday ? fajr : null,
      asr: isToday ? times!.asr.toLocal() : null,
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final collection = ref.watch(
      widget.afterPrayer
          ? afterPrayerDzikirProvider
          : selectedDzikirCollectionProvider,
    );
    final languageCode = Localizations.localeOf(ctx).languageCode;

    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(
        title: widget.afterPrayer ? l10n.afterPrayerDzikir : l10n.dzikir,
      ),
      body: collection.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(l10n.dzikirLoadError, textAlign: TextAlign.center),
          ),
        ),
        data: (collection) => Center(
          child: ConstrainedBox(
            // Keep lines readable on wide desktop windows.
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              children: [
                if (collection.hasSessions)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: PlatformSegmentedControl<DzikirSession>(
                      segments: {
                        DzikirSession.morning: l10n.dzikirMorning,
                        DzikirSession.evening: l10n.dzikirEvening,
                      },
                      value: _session,
                      onChanged: (s) => setState(() => _session = s),
                    ),
                  )
                else
                  const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.xs,
                  ),
                  child: Text(
                    l10n.dzikirCounterHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final item
                    in collection.hasSessions
                        ? collection.itemsFor(_session)
                        : collection.items)
                  RecitationCard(
                    badge: _badge(l10n, item),
                    completed: (_counts[item] ?? 0) >= item.repeat,
                    onTap: () => _count(item),
                    onLongPress: () => _reset(item),
                    tapHint: l10n.dzikirCountAction,
                    longPressHint: l10n.dzikirResetAction,
                    note: item.noteFor(languageCode),
                    arabic: item.arabic,
                    transliteration: item.transliteration,
                    translation: item.translationFor(languageCode),
                    reference: item.reference,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: Text(
                    l10n.dzikirSource(collection.sourceFor(languageCode)),
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
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
