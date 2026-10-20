import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/city_catalog.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/calculation_method_picker.dart';
import '../../core/widgets/glass_menu.dart';
import '../../generated/l10n/app_localizations.dart';
import '../changelog/changelog_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final l10n = AppLocalizations.of(ctx);
    final settings = ref.watch(settingsProvider);
    final locale = ref.watch(localeProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isApple = PlatformCapabilities.isApple;

    final sections = [
      // ── Section: Salat ─────────────────────────────────────────────────
      _Section(title: l10n.prayerTimes, children: [
        // Metode Hisab
        PlatformListTile(
          leading:
              Icon(Icons.calculate_outlined, color: AppColors.accentOf(ctx)),
          title: Text(l10n.calculationMethod),
          subtitle: Text(calculationMethodLabel(ctx, settings.method)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showCalculationMethodPage(ctx),
        ),

        // Mazhab
        _ChoiceTile<bool>(
          icon: Icons.school_outlined,
          title: l10n.madhab,
          value: settings.isHanafi,
          options: [
            GlassMenuOption(value: false, label: l10n.madhabShafi),
            GlassMenuOption(value: true, label: l10n.madhabHanafi),
          ],
          onChanged: notifier.setMadhab,
          materialTrailing: ToggleButtons(
            isSelected: [!settings.isHanafi, settings.isHanafi],
            onPressed: (i) => notifier.setMadhab(i == 1),
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.white,
            fillColor: AppColors.accentOf(ctx),
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
        PlatformListTile(
          leading: Icon(Icons.notifications_outlined,
              color: AppColors.accentOf(ctx)),
          title: Text(l10n.azanNotifications),
          subtitle: Text(l10n.allPrayers),
          trailing: _AdaptiveSwitch(value: true, onChanged: (_) {}),
        ),

        PlatformListTile(
          leading:
              Icon(Icons.my_location_outlined, color: AppColors.accentOf(ctx)),
          title: Text(l10n.locationModeAuto),
          subtitle: Text(
            settings.useAutoLocation
                ? l10n.locationModeAutoDescOn
                : l10n.locationModeAutoDescOff,
          ),
          trailing: _AdaptiveSwitch(
            value: settings.useAutoLocation,
            onChanged: notifier.setUseAutoLocation,
          ),
        ),

        _ChoiceTile<String>(
          icon: Icons.location_city_outlined,
          title: l10n.city,
          subtitle: !settings.useAutoLocation && settings.selectedCityId == null
              ? Text(
                  l10n.cityRequiredHint,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                )
              : null,
          value: settings.selectedCityId,
          hint: l10n.selectCity,
          options: [
            for (final city in supportedCities)
              GlassMenuOption(value: city.id, label: city.name),
          ],
          onChanged: notifier.setSelectedCityId,
        ),
      ]),

      // ── Section: Tampilan ────────────────────────────────────────────────
      _Section(title: l10n.theme, children: [
        _ChoiceTile<int>(
          icon: Icons.palette_outlined,
          title: l10n.theme,
          value: settings.themeMode,
          options: [
            GlassMenuOption(value: 0, label: l10n.themeSystem),
            GlassMenuOption(value: 1, label: l10n.themeLight),
            GlassMenuOption(value: 2, label: l10n.themeDark),
          ],
          onChanged: notifier.setThemeMode,
        ),
      ]),

      // ── Section: Bahasa ──────────────────────────────────────────────────
      _Section(title: l10n.language, children: [
        _ChoiceTile<String>(
          icon: Icons.language_outlined,
          title: l10n.language,
          value: locale.languageCode,
          options: [
            for (final loc in supportedLocales)
              GlassMenuOption(
                value: loc.languageCode,
                label: localeDisplayNames[loc.languageCode] ?? loc.languageCode,
              ),
          ],
          onChanged: (code) =>
              ref.read(localeProvider.notifier).setLocale(Locale(code)),
        ),
      ]),

      // ── Section: Lainnya ─────────────────────────────────────────────────
      _Section(title: l10n.about, children: [
        PlatformListTile(
          leading:
              Icon(Icons.new_releases_outlined, color: AppColors.accentOf(ctx)),
          title: Text(l10n.whatsNew),
          subtitle: Text(l10n.whatsNewSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(ctx).push(MaterialPageRoute<void>(
            builder: (_) => const ChangelogScreen(),
          )),
        ),
        PlatformListTile(
          leading: Icon(Icons.widgets_outlined, color: AppColors.accentOf(ctx)),
          title: Text(l10n.widgetStyle),
          subtitle: Text(l10n.widgetCompact),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        PlatformListTile(
          leading: Icon(Icons.info_outline, color: AppColors.accentOf(ctx)),
          title: Text(l10n.about),
          subtitle: Text(l10n.version('1.0.0')),
          onTap: () {},
        ),
      ]),
    ];

    return Scaffold(
      extendBodyBehindAppBar: isApple,
      appBar: GlassTopBar(title: l10n.settings),
      body: ListView(children: [
        for (final (i, section) in sections.indexed) ...[
          // Glass sections are separate cards; Material ones need a rule.
          if (i > 0 && !isApple) const Divider(),
          section,
        ],
        const SizedBox(height: AppSpacing.xl),
      ]),
    );
  }
}

// ─── Section ──────────────────────────────────────────────────────────────────
/// A titled group of rows: an inset glass card on iOS and macOS, like the
/// system Settings app, and a flat list elsewhere.
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext ctx) {
    final isApple = PlatformCapabilities.isApple;
    final header = Padding(
      padding: EdgeInsets.fromLTRB(
        // Line the header up with the rows inside the inset card.
        isApple ? AppSpacing.md * 2 : AppSpacing.md,
        AppSpacing.md + AppSpacing.xxs,
        AppSpacing.md,
        AppSpacing.xxs,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.accentOf(ctx),
              letterSpacing: 1.2,
            ),
      ),
    );
    if (!isApple) {
      return Column(children: [header, ...children]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(children: [
            for (final (i, row) in children.indexed) ...[
              // Inset past the leading icon, like grouped iOS lists.
              if (i > 0) const Hairline(indent: PlatformListTile.textInset),
              row,
            ],
          ]),
        ),
      ],
    );
  }
}

// ─── Switch ───────────────────────────────────────────────────────────────────
/// A Liquid Glass switch on iOS and macOS, a Material switch elsewhere.
class _AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AdaptiveSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext ctx) {
    final accent = AppColors.accentOf(ctx);
    if (PlatformCapabilities.isApple) {
      return LiquidGlassSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: accent,
      );
    }
    return Switch(value: value, activeThumbColor: accent, onChanged: onChanged);
  }
}

// ─── Choice row ───────────────────────────────────────────────────────────────
/// A row that picks one of [options]. On iOS and macOS the row shows the
/// current choice and opens a Liquid Glass pop-up menu; elsewhere it shows
/// [materialTrailing], or a dropdown when that is null.
class _ChoiceTile<T> extends StatefulWidget {
  final IconData icon;
  final String title;
  final Widget? subtitle;
  final T? value;

  /// Shown when [value] matches no option.
  final String? hint;
  final List<GlassMenuOption<T>> options;
  final ValueChanged<T> onChanged;
  final Widget? materialTrailing;

  const _ChoiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    this.subtitle,
    this.hint,
    this.materialTrailing,
  });

  @override
  State<_ChoiceTile<T>> createState() => _ChoiceTileState<T>();
}

class _ChoiceTileState<T> extends State<_ChoiceTile<T>> {
  final _trailingKey = GlobalKey();

  /// Guards against a second menu stacking on repeated taps.
  bool _isMenuOpen = false;

  /// Widest the current choice grows before it ellipsizes, so long city
  /// names leave room for the title.
  static const _maxValueWidth = 160.0;

  Future<void> _openMenu() async {
    final anchorCtx = _trailingKey.currentContext;
    if (_isMenuOpen || anchorCtx == null) return;
    _isMenuOpen = true;
    try {
      await showGlassMenu<T>(
        context,
        anchor: globalRectOf(anchorCtx),
        title: widget.title,
        options: widget.options,
        selected: widget.value,
        onSelected: widget.onChanged,
      );
    } finally {
      _isMenuOpen = false;
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final leading = Icon(widget.icon, color: AppColors.accentOf(ctx));
    final title = Text(widget.title);

    if (!PlatformCapabilities.isApple) {
      return PlatformListTile(
        leading: leading,
        title: title,
        subtitle: widget.subtitle,
        trailing: widget.materialTrailing ??
            DropdownButton<T>(
              value: widget.value,
              hint: widget.hint == null ? null : Text(widget.hint!),
              underline: const SizedBox(),
              borderRadius: BorderRadius.circular(12),
              items: [
                for (final option in widget.options)
                  DropdownMenuItem<T>(
                    value: option.value,
                    child: Text(option.label),
                  ),
              ],
              onChanged: (v) {
                if (v != null) widget.onChanged(v);
              },
            ),
      );
    }

    final current =
        widget.options.where((o) => o.value == widget.value).firstOrNull;
    final muted = theme.colorScheme.onSurfaceVariant;
    return PlatformListTile(
      leading: leading,
      title: title,
      subtitle: widget.subtitle,
      onTap: _openMenu,
      trailing: Row(
        key: _trailingKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxValueWidth),
            child: Text(
              current?.label ?? widget.hint ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Icon(Icons.unfold_more, size: 18, color: muted),
        ],
      ),
    );
  }
}
