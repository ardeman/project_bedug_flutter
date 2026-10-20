import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../core/design/platform_design.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/liquid_glass.dart';
import '../../core/design/glass_controls.dart';
import '../../core/design/platform_capabilities.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/services/notification_preferences.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/widget_appearance.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/calculation_method_picker.dart';
import '../../core/widgets/city_picker.dart';
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
    final manualCity = ref.watch(manualCityProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isApple = PlatformCapabilities.isApple;

    final sections = [
      // ── Section: Salat ─────────────────────────────────────────────────
      _Section(
        title: l10n.prayerTimes,
        children: [
          // Metode Hisab
          PlatformListTile(
            leading: Icon(
              Icons.calculate_outlined,
              color: AppColors.accentOf(ctx),
            ),
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
                  child: Text(l10n.madhabShafi),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(l10n.madhabHanafi),
                ),
              ],
            ),
          ),

          // Notifikasi
          PlatformListTile(
            leading: Icon(
              Icons.notifications_outlined,
              color: AppColors.accentOf(ctx),
            ),
            title: Text(l10n.azanNotifications),
            subtitle: Text(
              settings.notifications.enabled
                  ? l10n.notificationPreferences
                  : l10n.notificationsOff,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationSettingsScreen(),
              ),
            ),
          ),

          PlatformListTile(
            leading: Icon(
              Icons.my_location_outlined,
              color: AppColors.accentOf(ctx),
            ),
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

          PlatformListTile(
            enabled: !settings.useAutoLocation,
            leading: Icon(
              Icons.location_city_outlined,
              color: AppColors.accentOf(ctx),
            ),
            title: Text(l10n.city),
            subtitle: Text(
              settings.useAutoLocation
                  ? l10n.cityAutoDetectHint
                  : '${manualCity.name}, '
                        '${countryLabel(l10n, manualCity.country)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showCityPicker(ctx),
          ),
        ],
      ),

      // ── Section: Tampilan ────────────────────────────────────────────────
      _Section(
        title: l10n.theme,
        children: [
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
        ],
      ),

      // ── Section: Bahasa ──────────────────────────────────────────────────
      _Section(
        title: l10n.language,
        children: [
          _ChoiceTile<String>(
            icon: Icons.language_outlined,
            title: l10n.language,
            value: locale.languageCode,
            options: [
              for (final loc in supportedLocales)
                GlassMenuOption(
                  value: loc.languageCode,
                  label:
                      localeDisplayNames[loc.languageCode] ?? loc.languageCode,
                ),
            ],
            onChanged: (code) =>
                ref.read(localeProvider.notifier).setLocale(Locale(code)),
          ),
        ],
      ),

      // ── Section: Lainnya ─────────────────────────────────────────────────
      _Section(
        title: l10n.about,
        children: [
          PlatformListTile(
            leading: Icon(
              Icons.new_releases_outlined,
              color: AppColors.accentOf(ctx),
            ),
            title: Text(l10n.whatsNew),
            subtitle: Text(l10n.whatsNewSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(builder: (_) => const ChangelogScreen()),
            ),
          ),
          PlatformListTile(
            leading: Icon(
              Icons.widgets_outlined,
              color: AppColors.accentOf(ctx),
            ),
            title: Text(l10n.widgetStyle),
            subtitle: Text(
              ref.watch(widgetAppearanceProvider).showAnalog
                  ? l10n.widgetAnalogAndDigital
                  : l10n.widgetDigitalOnly,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                builder: (_) => const WidgetAppearanceScreen(),
              ),
            ),
          ),
          PlatformListTile(
            leading: Icon(Icons.info_outline, color: AppColors.accentOf(ctx)),
            title: Text(l10n.about),
            subtitle: Text(l10n.version('1.0.0')),
            onTap: () {},
          ),
        ],
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: isApple,
      appBar: GlassTopBar(title: l10n.settings),
      body: ListView(
        children: [
          for (final (i, section) in sections.indexed) ...[
            // Glass sections are separate cards; Material ones need a rule.
            if (i > 0 && !isApple && !PlatformDesign.usesExpressive)
              const Divider(),
            section,
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Prayer alerts use the platform sound or silent delivery, never a recording.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final l10n = AppLocalizations.of(ctx);
    final preferences = ref.watch(settingsProvider).notifications;
    final notifier = ref.read(settingsProvider.notifier);
    final failed = ref.watch(prayerProvider.select((s) => s.notificationError));
    final names = [l10n.fajr, l10n.dhuhr, l10n.asr, l10n.maghrib, l10n.isha];
    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: l10n.azanNotifications),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              NotificationService.supportsScheduling
                  ? l10n.notificationDeliveryInfo
                  : l10n.notificationPlatformUnavailable,
            ),
          ),
          if (failed)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(l10n.notificationSchedulingError),
            ),
          _Section(
            title: l10n.azanNotifications,
            children: [
              PlatformListTile(
                title: Text(l10n.azanNotifications),
                trailing: _AdaptiveSwitch(
                  key: const ValueKey('notifications-enabled'),
                  value: preferences.enabled,
                  onChanged: (value) => notifier.setNotifications(
                    preferences.copyWith(enabled: value),
                  ),
                ),
              ),
              if (preferences.enabled) ...[
                for (final (index, prayer) in notificationPrayers.indexed)
                  PlatformListTile(
                    title: Text(names[index]),
                    trailing: _AdaptiveSwitch(
                      key: ValueKey('notification-${prayer.name}'),
                      value: preferences.includes(prayer),
                      onChanged: (value) {
                        final disabled = {...preferences.disabledPrayers};
                        value ? disabled.remove(prayer) : disabled.add(prayer);
                        notifier.setNotifications(
                          preferences.copyWith(disabledPrayers: disabled),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
          if (preferences.enabled)
            _Section(
              title: l10n.notificationPreferences,
              children: [
                _ChoiceTile<int>(
                  icon: Icons.alarm_outlined,
                  title: l10n.beforePrayerReminder,
                  value: preferences.reminderMinutes,
                  options: [
                    for (final minutes in reminderMinuteOptions)
                      GlassMenuOption(
                        value: minutes,
                        label: minutes == 0
                            ? l10n.reminderOff
                            : l10n.minutesBeforePrayer(minutes),
                      ),
                  ],
                  onChanged: (minutes) => notifier.setNotifications(
                    preferences.copyWith(reminderMinutes: minutes),
                  ),
                ),
                _ChoiceTile<PrayerNotificationSound>(
                  icon: Icons.volume_up_outlined,
                  title: l10n.notificationSound,
                  value: preferences.sound,
                  options: [
                    GlassMenuOption(
                      value: PrayerNotificationSound.system,
                      label: l10n.systemNotificationSound,
                    ),
                    GlassMenuOption(
                      value: PrayerNotificationSound.silent,
                      label: l10n.silentNotificationSound,
                    ),
                  ],
                  onChanged: (sound) => notifier.setNotifications(
                    preferences.copyWith(sound: sound),
                  ),
                ),
              ],
            ),
          if (NotificationService.supportsScheduling)
            _Section(
              title: l10n.notificationSystemSettings,
              children: [
                PlatformListTile(
                  title: Text(l10n.notificationSystemSettings),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    await NotificationService.openSystemSettings();
                    if (ctx.mounted) {
                      await ref
                          .read(prayerProvider.notifier)
                          .refreshNotifications();
                    }
                  },
                ),
                if (defaultTargetPlatform == TargetPlatform.android)
                  PlatformListTile(
                    title: Text(l10n.precisePrayerAlerts),
                    subtitle: Text(l10n.precisePrayerAlertsDescription),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () async {
                      await NotificationService.requestPreciseAlarms();
                      if (ctx.mounted) {
                        await ref
                            .read(prayerProvider.notifier)
                            .refreshNotifications();
                      }
                    },
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
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
    if (PlatformDesign.usesExpressive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: M3EList(
              itemCount: children.length,
              onTap: (index) {
                final row = children[index];
                if (row is PlatformListTile && row.enabled) row.onTap?.call();
              },
              itemBuilder: (context, index) => children[index],
            ),
          ),
        ],
      );
    }
    if (!isApple) {
      return Column(children: [header, ...children]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (final (i, row) in children.indexed) ...[
                // Inset past the leading icon, like grouped iOS lists.
                if (i > 0) const Hairline(indent: PlatformListTile.textInset),
                row,
              ],
            ],
          ),
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

  const _AdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

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
    if (PlatformDesign.usesExpressive) {
      return M3ESwitch(value: value, onChanged: onChanged);
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

    if (PlatformDesign.usesExpressive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformListTile(
            leading: leading,
            title: title,
            subtitle: widget.subtitle,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: widget.materialTrailing != null
                ? M3ESegmentedButton<T>(
                    segments: [
                      for (final option in widget.options)
                        M3ESegment(value: option.value, label: option.label),
                    ],
                    selected: {if (widget.value != null) widget.value as T},
                    onSelectionChanged: (values) =>
                        widget.onChanged(values.single),
                  )
                : M3EDropdownMenu<T>(
                    singleSelect: true,
                    showChipAnimation: false,
                    fieldStyle: const M3EDropdownFieldStyle(
                      showClearIcon: false,
                    ),
                    selectedItemBuilder: (item) => Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    items: [
                      for (final option in widget.options)
                        M3EDropdownItem(
                          value: option.value,
                          label: option.label,
                          selected: option.value == widget.value,
                        ),
                    ],
                    onSelectionChanged: (items) {
                      if (items.isNotEmpty) {
                        widget.onChanged(items.single.value);
                      }
                    },
                  ),
          ),
        ],
      );
    }
    if (!PlatformCapabilities.isApple) {
      return PlatformListTile(
        leading: leading,
        title: title,
        subtitle: widget.subtitle,
        trailing:
            widget.materialTrailing ??
            DropdownButton<T>(
              value: widget.value,
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

    final current = widget.options
        .where((o) => o.value == widget.value)
        .firstOrNull;
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
              current?.label ?? '',
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

class WidgetAppearanceScreen extends ConsumerWidget {
  const WidgetAppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final appearance = ref.watch(widgetAppearanceProvider);
    final notifier = ref.read(widgetAppearanceProvider.notifier);
    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: l10n.widgetStyle),
      body: ListView(
        padding: EdgeInsets.only(
          top: PlatformCapabilities.isApple
              ? kToolbarHeight + MediaQuery.paddingOf(context).top
              : 0,
          bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
        ),
        children: [
          _Section(
            title: l10n.widgetStyle,
            children: [
              PlatformListTile(
                title: Text(l10n.widgetAnalogCountdown),
                subtitle: Text(l10n.widgetAnalogDescription),
                trailing: _AdaptiveSwitch(
                  key: const ValueKey('widget_analog_switch'),
                  value: appearance.showAnalog,
                  onChanged: notifier.setShowAnalog,
                ),
              ),
              PlatformListTile(
                title: Text(l10n.widgetSchedule),
                subtitle: Text(l10n.widgetScheduleDescription),
                trailing: _AdaptiveSwitch(
                  key: const ValueKey('widget_schedule_switch'),
                  value: appearance.showSchedule,
                  onChanged: notifier.setShowSchedule,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.widgetAppearanceHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              l10n.widgetPreview,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.widgetPreviewHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          for (var size = 0; size < 3; size++)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: _WidgetLayoutPreview(size: size, appearance: appearance),
            ),
        ],
      ),
    );
  }
}

class _WidgetLayoutPreview extends StatelessWidget {
  final int size;
  final WidgetAppearance appearance;

  const _WidgetLayoutPreview({required this.size, required this.appearance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final accent = AppColors.accentOf(context);
    final names = [l10n.dhuhr, l10n.asr, l10n.maghrib, l10n.isha, l10n.fajr];
    final hours = [12, 15, 18, 19, 4];
    String time(int index) => MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: hours[index], minute: 0),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [l10n.widgetSmall, l10n.widgetMedium, l10n.widgetLarge][size],
          style: text.labelLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            // Keep previews readable on phones and bounded on desktop windows.
            constraints: BoxConstraints(maxWidth: size == 0 ? 200 : 400),
            child: GlassCard(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.nextPrayer, style: text.labelSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                names.first,
                                style: text.titleLarge?.copyWith(color: accent),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(time(0), style: text.bodyMedium),
                            ],
                          ),
                        ),
                        if (appearance.showAnalog) ...[
                          const SizedBox(width: AppSpacing.xs),
                          ExcludeSemantics(
                            child: SizedBox.square(
                              key: ValueKey('widget_preview_analog_$size'),
                              dimension: size == 2
                                  ? AppSpacing.xxl + AppSpacing.md
                                  : AppSpacing.xxl,
                              child: CustomPaint(
                                painter: _WidgetDialPainter(accent),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(l10n.widgetPreviewCountdown, style: text.titleLarge),
                    if (appearance.showSchedule && size > 0) ...[
                      const SizedBox(height: AppSpacing.md),
                      if (size == 2)
                        for (var index = 0; index < names.length; index++)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    names[index],
                                    style: text.bodyMedium,
                                  ),
                                ),
                                Text(time(index), style: text.bodyMedium),
                              ],
                            ),
                          )
                      else
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (var index = 0; index < names.length; index++)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(names[index], style: text.labelSmall),
                                  Text(time(index), style: text.bodySmall),
                                ],
                              ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WidgetDialPainter extends CustomPainter {
  final Color accent;
  const _WidgetDialPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - AppSpacing.xxs;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSpacing.xxs
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.15);
    final ring = Rect.fromCircle(center: center, radius: radius);
    canvas.drawOval(ring, paint);
    paint.color = accent;
    canvas.drawArc(ring, -math.pi / 2, math.pi * 1.5, false, paint);
    canvas.drawLine(center, center.translate(radius * 0.5, 0), paint);
  }

  @override
  bool shouldRepaint(_WidgetDialPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
