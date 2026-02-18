import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/city_catalog.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/widgets/calculation_method_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final l10n = AppLocalizations.of(ctx);
    final settings = ref.watch(settingsProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(children: [
        // ── Section: Sholat ─────────────────────────────────────────────────
        _SectionHeader(l10n.prayerTimes),

        // Metode Hisab
        ListTile(
          leading:
              const Icon(Icons.calculate_outlined, color: AppColors.emerald),
          title: Text(l10n.calculationMethod),
          subtitle: Text(calculationMethodLabel(ctx, settings.method)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showCalculationMethodPicker(
            ctx,
            ref,
            current: settings.method,
          ),
        ),

        // Mazhab
        ListTile(
          leading: const Icon(Icons.school_outlined, color: AppColors.emerald),
          title: Text(l10n.madhab),
          trailing: ToggleButtons(
            isSelected: [!settings.isHanafi, settings.isHanafi],
            onPressed: (i) =>
                ref.read(settingsProvider.notifier).setMadhab(i == 1),
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.white,
            fillColor: AppColors.emerald,
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(l10n.madhabShafi)),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(l10n.madhabHanafi)),
            ],
          ),
        ),

        // Notifikasi
        ListTile(
          leading: const Icon(Icons.notifications_outlined,
              color: AppColors.emerald),
          title: Text(l10n.azanNotifications),
          subtitle: Text(l10n.allPrayers),
          trailing: Switch(
            value: true,
            activeThumbColor: AppColors.emerald,
            onChanged: (_) {},
          ),
        ),

        ListTile(
          leading:
              const Icon(Icons.my_location_outlined, color: AppColors.emerald),
          title: Text(l10n.locationModeAuto),
          subtitle: Text(
            settings.useAutoLocation
                ? l10n.locationModeAutoDescOn
                : l10n.locationModeAutoDescOff,
          ),
          trailing: Switch(
            value: settings.useAutoLocation,
            activeThumbColor: AppColors.emerald,
            onChanged: (enabled) =>
                ref.read(settingsProvider.notifier).setUseAutoLocation(enabled),
          ),
        ),

        ListTile(
          leading: const Icon(Icons.location_city_outlined,
              color: AppColors.emerald),
          title: Text(l10n.city),
          subtitle: !settings.useAutoLocation && settings.selectedCityId == null
              ? Text(
                  l10n.cityRequiredHint,
                  style: TextStyle(color: Colors.redAccent),
                )
              : null,
          trailing: DropdownButton<String>(
            value: settings.selectedCityId,
            hint: Text(l10n.selectCity),
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(12),
            items: supportedCities
                .map((city) => DropdownMenuItem<String>(
                      value: city.id,
                      child: Text(city.name),
                    ))
                .toList(),
            onChanged: (value) =>
                ref.read(settingsProvider.notifier).setSelectedCityId(value),
          ),
        ),

        const Divider(),

        // ── Section: Tampilan ────────────────────────────────────────────────
        _SectionHeader(l10n.theme),

        ListTile(
          leading: const Icon(Icons.palette_outlined, color: AppColors.emerald),
          title: Text(l10n.theme),
          trailing: DropdownButton<int>(
            value: settings.themeMode,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(12),
            items: [
              DropdownMenuItem(value: 0, child: Text(l10n.themeSystem)),
              DropdownMenuItem(value: 1, child: Text(l10n.themeLight)),
              DropdownMenuItem(value: 2, child: Text(l10n.themeDark)),
            ],
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setThemeMode(v ?? 0),
          ),
        ),

        const Divider(),

        // ── Section: Bahasa ──────────────────────────────────────────────────
        _SectionHeader(l10n.language),

        ListTile(
          leading:
              const Icon(Icons.language_outlined, color: AppColors.emerald),
          title: Text(l10n.language),
          trailing: DropdownButton<String>(
            value: locale.languageCode,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(12),
            items: supportedLocales
                .map((loc) => DropdownMenuItem(
                      value: loc.languageCode,
                      child: Text(localeDisplayNames[loc.languageCode] ??
                          loc.languageCode),
                    ))
                .toList(),
            onChanged: (code) {
              if (code != null) {
                ref.read(localeProvider.notifier).setLocale(Locale(code));
              }
            },
          ),
        ),

        const Divider(),

        // ── Section: Lainnya ─────────────────────────────────────────────────
        _SectionHeader(l10n.about),

        ListTile(
          leading: const Icon(Icons.widgets_outlined, color: AppColors.emerald),
          title: Text(l10n.widgetStyle),
          subtitle: Text(l10n.widgetCompact),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),

        ListTile(
          leading: const Icon(Icons.info_outline, color: AppColors.emerald),
          title: Text(l10n.about),
          subtitle: Text(l10n.version('1.0.0')),
          onTap: () {},
        ),

        const SizedBox(height: 32),
      ]),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.emerald,
              letterSpacing: 1.2,
            )),
      );
}
