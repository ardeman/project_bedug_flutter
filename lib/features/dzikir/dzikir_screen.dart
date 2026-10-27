import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/design/platform_design.dart';
import '../../core/services/prayer_service.dart';
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
                    child: _SessionSwitch(
                      value: _session,
                      onChanged: (s) => setState(() => _session = s),
                    ),
                  )
                else
                  const SizedBox(height: AppSpacing.sm),
                for (final item
                    in collection.hasSessions
                        ? collection.itemsFor(_session)
                        : collection.items)
                  RecitationCard(
                    badge: l10n.dzikirRepeat(item.repeat),
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

/// Morning / evening switch: a glass segmented control on Apple, an
/// Expressive segmented button on Material paths, a segmented button
/// elsewhere.
class _SessionSwitch extends StatelessWidget {
  final DzikirSession value;
  final ValueChanged<DzikirSession> onChanged;

  const _SessionSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final labels = {
      DzikirSession.morning: l10n.dzikirMorning,
      DzikirSession.evening: l10n.dzikirEvening,
    };

    if (PlatformDesign.usesExpressive) {
      return M3ESegmentedButton<DzikirSession>(
        segments: [
          for (final s in DzikirSession.values)
            M3ESegment(value: s, label: labels[s]!),
        ],
        selected: {value},
        onSelectionChanged: (values) => onChanged(values.single),
      );
    }
    if (!PlatformCapabilities.isApple) {
      return SegmentedButton<DzikirSession>(
        segments: [
          for (final s in DzikirSession.values)
            ButtonSegment(value: s, label: Text(labels[s]!)),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (values) => onChanged(values.single),
      );
    }

    final theme = Theme.of(ctx);
    final accent = AppColors.accentOf(ctx);
    const height = AppControlSizes.toolbarButton;
    final radius = BorderRadius.circular(height / 2);
    return LiquidGlassLite(
      shape: const LiquidGlassShape.continuousRoundedRectangle(
        cornerRadius: height / 2,
      ),
      color: glassCardTintOf(ctx),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (final s in DzikirSession.values)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: s == value,
                  child: GlassPressable(
                    onTap: () => onChanged(s),
                    borderRadius: radius,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: s == value ? accent : Colors.transparent,
                        borderRadius: radius,
                      ),
                      child: Text(
                        labels[s]!,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: s == value
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
