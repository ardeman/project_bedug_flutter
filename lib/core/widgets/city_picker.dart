import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/city_catalog.dart';
import '../design/glass_controls.dart';
import '../design/liquid_glass.dart';
import '../design/platform_capabilities.dart';
import '../providers/locale_provider.dart';
import '../theme/app_tokens.dart';

String countryLabel(AppLocalizations l10n, CityCountry country) =>
    switch (country) {
      CityCountry.indonesia => l10n.countryIndonesia,
      CityCountry.malaysia => l10n.countryMalaysia,
      CityCountry.singapore => l10n.countrySingapore,
      CityCountry.brunei => l10n.countryBrunei,
      CityCountry.thailand => l10n.countryThailand,
      CityCountry.philippines => l10n.countryPhilippines,
      CityCountry.saudiArabia => l10n.countrySaudiArabia,
      CityCountry.unitedArabEmirates => l10n.countryUnitedArabEmirates,
      CityCountry.qatar => l10n.countryQatar,
      CityCountry.kuwait => l10n.countryKuwait,
      CityCountry.bahrain => l10n.countryBahrain,
      CityCountry.oman => l10n.countryOman,
      CityCountry.jordan => l10n.countryJordan,
      CityCountry.palestine => l10n.countryPalestine,
      CityCountry.egypt => l10n.countryEgypt,
      CityCountry.morocco => l10n.countryMorocco,
      CityCountry.turkey => l10n.countryTurkey,
      CityCountry.pakistan => l10n.countryPakistan,
      CityCountry.india => l10n.countryIndia,
      CityCountry.bangladesh => l10n.countryBangladesh,
      CityCountry.unitedKingdom => l10n.countryUnitedKingdom,
      CityCountry.france => l10n.countryFrance,
      CityCountry.germany => l10n.countryGermany,
      CityCountry.netherlands => l10n.countryNetherlands,
      CityCountry.unitedStates => l10n.countryUnitedStates,
      CityCountry.canada => l10n.countryCanada,
      CityCountry.australia => l10n.countryAustralia,
      CityCountry.japan => l10n.countryJapan,
      CityCountry.southKorea => l10n.countrySouthKorea,
      CityCountry.nigeria => l10n.countryNigeria,
      CityCountry.southAfrica => l10n.countrySouthAfrica,
    };

/// The cities whose name or localized country contains [query], grouped by
/// country in catalog order. An empty query matches every city.
List<(CityCountry, List<CityOption>)> filterCities(
    AppLocalizations l10n, String query) {
  final q = query.trim().toLowerCase();
  final groups = <CityCountry, List<CityOption>>{};
  for (final city in supportedCities) {
    final matches = q.isEmpty ||
        city.name.toLowerCase().contains(q) ||
        countryLabel(l10n, city.country).toLowerCase().contains(q);
    if (matches) (groups[city.country] ??= []).add(city);
  }
  return [for (final e in groups.entries) (e.key, e.value)];
}

/// Opens the city picker: a full page with a search field, since the
/// catalog is too long for a pop-up menu.
Future<void> showCityPicker(BuildContext ctx) => Navigator.of(ctx).push(
      MaterialPageRoute<void>(builder: (_) => const CityPickerScreen()),
    );

class CityPickerScreen extends ConsumerStatefulWidget {
  const CityPickerScreen({super.key});

  @override
  ConsumerState<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends ConsumerState<CityPickerScreen> {
  String _query = '';

  void _pick(CityOption city) {
    ref.read(settingsProvider.notifier).setSelectedCityId(city.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final isApple = PlatformCapabilities.isApple;
    final selectedId = ref.watch(manualCityProvider).id;
    final groups = filterCities(l10n, _query);

    return Scaffold(
      extendBodyBehindAppBar: isApple,
      appBar: GlassTopBar(title: l10n.city),
      body: ListView.builder(
        // The search field, then one item per country (or the empty note).
        itemCount: 1 + (groups.isEmpty ? 1 : groups.length),
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return _SearchField(onChanged: (q) => setState(() => _query = q));
          }
          if (groups.isEmpty) return _EmptyNote(text: l10n.noCityFound);
          final (country, cities) = groups[i - 1];
          return _CountryGroup(
            title: countryLabel(l10n, country),
            cities: cities,
            selectedId: selectedId,
            onPick: _pick,
            isLast: i == groups.length,
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xxs),
      child: PlatformCapabilities.isApple
          ? CupertinoSearchTextField(
              placeholder: l10n.searchCity,
              onChanged: onChanged,
              style: Theme.of(ctx)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Theme.of(ctx).colorScheme.onSurface),
              // CupertinoIcons render as boxes on macOS.
              prefixIcon: const Icon(Icons.search),
              suffixIcon: const Icon(Icons.cancel),
            )
          : SearchBar(
              hintText: l10n.searchCity,
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: onChanged,
            ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String text;

  const _EmptyNote({required this.text});

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// One country's cities: an inset glass card on iOS and macOS, a titled
/// list elsewhere, like the settings sections.
class _CountryGroup extends StatelessWidget {
  final String title;
  final List<CityOption> cities;
  final String selectedId;
  final ValueChanged<CityOption> onPick;

  /// The last group leaves room to scroll clear of the floating nav bar.
  final bool isLast;

  const _CountryGroup({
    required this.title,
    required this.cities,
    required this.selectedId,
    required this.onPick,
    required this.isLast,
  });

  @override
  Widget build(BuildContext ctx) {
    final isApple = PlatformCapabilities.isApple;
    final accent = AppColors.accentOf(ctx);
    final header = Padding(
      padding: EdgeInsets.fromLTRB(
        // Line the header up with the rows inside the inset card.
        isApple ? AppSpacing.md * 2 : AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxs,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: accent,
              letterSpacing: 1.2,
            ),
      ),
    );
    final rows = [
      for (final city in cities)
        PlatformListTile(
          title: Text(city.name),
          trailing:
              city.id == selectedId ? Icon(Icons.check, color: accent) : null,
          onTap: () => onPick(city),
        ),
    ];

    return Padding(
      padding:
          EdgeInsets.only(bottom: isLast ? GlassNavBar.occupiedHeight(ctx) : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (isApple)
            GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(children: [
                for (final (i, row) in rows.indexed) ...[
                  if (i > 0) const Hairline(indent: AppSpacing.md),
                  row,
                ],
              ]),
            )
          else
            ...rows,
        ],
      ),
    );
  }
}
