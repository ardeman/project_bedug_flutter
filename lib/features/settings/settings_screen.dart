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
import '../../core/services/notification_sound_preview.dart';
import '../../core/services/phone_sound_picker.dart';
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
              borderRadius: BorderRadius.circular(AppRadii.sm),
              selectedColor: Theme.of(ctx).colorScheme.onPrimary,
              fillColor: AppColors.accentOf(ctx),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(l10n.madhabShafi),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
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
            title: Text(l10n.notifications),
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

/// Each prayer alert plays the system sound, a bundled bedug or siren, or
/// nothing; never a recorded azan.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final l10n = AppLocalizations.of(ctx);
    final preferences = ref.watch(settingsProvider).notifications;
    final notifier = ref.read(settingsProvider.notifier);
    final failed = ref.watch(prayerProvider.select((s) => s.notificationError));
    String nameOf(PrayerAlert alert) => switch (alert) {
      PrayerAlert.lastThirdOfNight => l10n.lastThirdOfNight,
      PrayerAlert.imsak => l10n.imsak,
      PrayerAlert.fajr => l10n.fajr,
      PrayerAlert.sunrise => l10n.sunrise,
      PrayerAlert.dhuha => l10n.dhuha,
      PrayerAlert.dhuhr => l10n.dhuhr,
      PrayerAlert.asr => l10n.asr,
      PrayerAlert.maghrib => l10n.maghrib,
      PrayerAlert.isha => l10n.isha,
    };
    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: l10n.notifications),
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
            title: l10n.notificationTimes,
            children: [
              PlatformListTile(
                title: Text(l10n.allNotifications),
                trailing: _AdaptiveSwitch(
                  key: const ValueKey('notifications-enabled'),
                  value: preferences.enabled,
                  onChanged: (value) => notifier.setNotifications(
                    preferences.copyWith(enabled: value),
                  ),
                ),
              ),
              if (preferences.enabled) ...[
                for (final alert in PrayerAlert.values)
                  PlatformListTile(
                    title: Text(nameOf(alert)),
                    trailing: _AdaptiveSwitch(
                      key: ValueKey('notification-${alert.name}'),
                      value: preferences.includes(alert),
                      onChanged: (value) {
                        final alerts = {...preferences.alerts};
                        value ? alerts.add(alert) : alerts.remove(alert);
                        notifier.setNotifications(
                          preferences.copyWith(alerts: alerts),
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
              ],
            ),
          if (preferences.enabled && preferences.alerts.isNotEmpty)
            _Section(
              title: l10n.notificationSound,
              children: [
                for (final alert in PrayerAlert.values)
                  if (preferences.includes(alert))
                    _ChoiceTile<PrayerNotificationSound>(
                      key: ValueKey('notification-sound-${alert.name}'),
                      icon:
                          preferences.soundOf(alert) ==
                              PrayerNotificationSound.silent
                          ? Icons.volume_off_outlined
                          : Icons.volume_up_outlined,
                      title: nameOf(alert),
                      value: preferences.soundOf(alert),
                      options: [
                        for (final sound in PrayerNotificationSound.values)
                          if (sound != PrayerNotificationSound.phone ||
                              PhoneSoundPicker.isSupported)
                            GlassMenuOption(
                              value: sound,
                              label: switch (sound) {
                                PrayerNotificationSound.system =>
                                  l10n.systemNotificationSound,
                                PrayerNotificationSound.bedug =>
                                  l10n.bedugNotificationSound,
                                PrayerNotificationSound.siren =>
                                  l10n.sirenNotificationSound,
                                // Once picked, the menu names the tone.
                                PrayerNotificationSound.phone =>
                                  preferences.soundOf(alert) == sound
                                      ? preferences.phoneSounds[alert]!.title
                                      : l10n.phoneNotificationSound,
                                PrayerNotificationSound.silent =>
                                  l10n.silentNotificationSound,
                              },
                            ),
                      ],
                      onChanged: (sound) async {
                        NotificationSoundPreview.play(sound);
                        PhoneSound? picked;
                        if (sound == PrayerNotificationSound.phone) {
                          // The system picker plays each tone as it's tried.
                          picked = await PhoneSoundPicker.pick(
                            current: preferences.phoneSounds[alert],
                          );
                          if (picked == null || !ctx.mounted) return;
                        }
                        // Read again: the picker may have been open a while.
                        final latest = ref.read(settingsProvider).notifications;
                        await notifier.setNotifications(
                          latest.copyWith(
                            sounds: {...latest.sounds, alert: sound},
                            phoneSounds: {
                              ...latest.phoneSounds,
                              alert: ?picked,
                            },
                          ),
                        );
                      },
                    ),
              ],
            ),
          if (NotificationService.supportsScheduling)
            _Section(
              title: l10n.notificationSystemSection,
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
                        return;
                      }
                      // Tapping the selected item deselects it; rebuild to
                      // reselect it (the dropdown reloads its items) and treat
                      // it as picking it again, e.g. to choose another tone.
                      setState(() {});
                      if (widget.value case final T value) {
                        widget.onChanged(value);
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
              borderRadius: BorderRadius.circular(AppRadii.sm),
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
          Icon(
            Icons.unfold_more,
            size: AppControlSizes.toolbarIcon,
            color: muted,
          ),
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
    // Show the widget's location line without starting a prayer-time load;
    // the provider already exists once the app's home tab has been built.
    final location = ref.exists(prayerProvider)
        ? ref.watch(prayerProvider).locationLabel ?? ''
        : '';
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
              child: _WidgetLayoutPreview(
                size: size,
                appearance: appearance,
                location: location,
              ),
            ),
        ],
      ),
    );
  }
}

class _WidgetLayoutPreview extends StatelessWidget {
  final int size;
  final WidgetAppearance appearance;
  final String location;

  const _WidgetLayoutPreview({
    required this.size,
    required this.appearance,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final accent = AppColors.accentOf(context);
    final names = [l10n.dhuhr, l10n.asr, l10n.maghrib, l10n.isha, l10n.fajr];
    final hours = [12, 15, 18, 19, 4];
    final focus = size == 2 && !appearance.showSchedule;
    String time(int index) => MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: hours[index], minute: 0),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    Widget countdown({bool prominent = false}) => Text(
      l10n.widgetPreviewCountdown,
      style: prominent ? text.headlineLarge : text.titleLarge,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    Widget dial(double diameter) => ExcludeSemantics(
      child: SizedBox.square(
        key: ValueKey('widget_preview_analog_$size'),
        dimension: diameter,
        child: CustomPaint(
          painter: _WidgetDialPainter(
            accent,
            apple: PlatformCapabilities.isApple,
          ),
          // WidgetKit shows the next prayer's sky; the preview's is Dhuhr.
          child: PlatformCapabilities.isApple
              ? Icon(Icons.light_mode, size: diameter / 4, color: accent)
              : null,
        ),
      ),
    );
    Widget details() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          names.first,
          style: (size == 2 ? text.headlineSmall : text.titleLarge)?.copyWith(
            color: accent,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(time(0), style: text.bodyMedium),
        if (size != 0) countdown(),
      ],
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
            constraints: BoxConstraints(maxWidth: size == 0 ? 200 : 400),
            child: !PlatformCapabilities.isApple
                ? _AndroidWidgetCard(
                    size: size,
                    appearance: appearance,
                    names: names,
                    time: time,
                    location: location,
                  )
                : GlassCard(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.nextPrayer, style: text.labelSmall),
                          const SizedBox(height: AppSpacing.xs),
                          if (focus)
                            SizedBox(
                              width: double.infinity,
                              child: Column(
                                children: [
                                  if (appearance.showAnalog) ...[
                                    dial(AppSpacing.xxl * 3),
                                    const SizedBox(height: AppSpacing.xs),
                                  ],
                                  Text(
                                    names.first,
                                    style: text.headlineSmall?.copyWith(
                                      color: accent,
                                    ),
                                  ),
                                  Text(time(0), style: text.titleMedium),
                                  countdown(prominent: true),
                                ],
                              ),
                            )
                          else ...[
                            Row(
                              children: [
                                Expanded(child: details()),
                                if (appearance.showAnalog) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  dial(
                                    size == 2
                                        ? AppSpacing.xxl * 2
                                        : size == 0
                                        ? AppSpacing.xxl
                                        : AppSpacing.xxl + AppSpacing.lg,
                                  ),
                                ],
                              ],
                            ),
                            if (size == 0) ...[
                              const SizedBox(height: AppSpacing.xs),
                              countdown(),
                            ],
                          ],
                          if (appearance.showSchedule && size > 0) ...[
                            const SizedBox(height: AppSpacing.md),
                            if (size == 2)
                              for (var index = 0; index < names.length; index++)
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: index == 0
                                        ? accent.withValues(alpha: 0.12)
                                        : null,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.sm,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          names[index],
                                          style: text.bodyMedium?.copyWith(
                                            color: index == 0 ? accent : null,
                                            fontWeight: index == 0
                                                ? FontWeight.bold
                                                : null,
                                          ),
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
                                  for (
                                    var index = 0;
                                    index < names.length;
                                    index++
                                  )
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          names[index],
                                          style: text.labelSmall,
                                        ),
                                        Text(
                                          time(index),
                                          style: text.bodySmall,
                                        ),
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

/// Mirrors the Android home screen widget layouts (`prayer_widget_small.xml`,
/// `prayer_widget.xml` and `prayer_widget_large.xml`) for the size each
/// preview stands for: two cells wide, four by two and four by four.
class _AndroidWidgetCard extends StatelessWidget {
  final int size;
  final WidgetAppearance appearance;
  final List<String> names;
  final String Function(int index) time;
  final String location;

  const _AndroidWidgetCard({
    required this.size,
    required this.appearance,
    required this.names,
    required this.time,
    required this.location,
  });

  // Dial sizes and paddings in dp, matching the native layouts.
  static const _dials = [56.0, 76.0, 104.0];
  static const _paddings = [12.0, 16.0, 20.0];
  static const _rowHeight = 36.0;

  // About 16% of the accent behind the next prayer's row, as on the widget.
  static const _highlightAlpha = 40 / 255;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // The native widget uses the brand palette Flutter sends it, not the
    // dynamic Material colors, so the preview does too.
    final background = dark ? AppColors.darkBg : AppColors.lightBg;
    final ink = dark ? AppColors.darkText : AppColors.lightText;
    final accent = dark ? AppColors.emeraldDark : AppColors.emerald;
    final countdown = l10n.widgetPreviewCountdown;
    final dial = appearance.showAnalog
        ? Padding(
            padding: EdgeInsetsDirectional.only(
              start: size == 0 ? AppSpacing.xs : AppSpacing.sm,
            ),
            child: ExcludeSemantics(
              child: SizedBox.square(
                key: ValueKey('widget_preview_analog_$size'),
                dimension: _dials[size],
                child: CustomPaint(painter: _AndroidDialPainter(accent)),
              ),
            ),
          )
        : null;
    Text line(String value, TextStyle? style, {Color? color}) => Text(
      value,
      style: style?.copyWith(color: color ?? ink),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final List<Widget> children;
    if (size == 0) {
      children = [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  line(names.first, text.titleMedium, color: accent),
                  line(time(0), text.bodySmall),
                  line(countdown, text.titleLarge),
                ],
              ),
            ),
            ?dial,
          ],
        ),
      ];
    } else {
      final large = size == 2;
      children = [
        line(l10n.nextPrayer, large ? text.bodyMedium : text.bodySmall),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  line(
                    '${names.first} · ${time(0)}',
                    large ? text.headlineMedium : text.headlineSmall,
                    color: accent,
                  ),
                  line(countdown, large ? text.displayMedium : text.titleLarge),
                  if (location.isNotEmpty)
                    line(location, large ? text.bodyMedium : text.bodySmall),
                ],
              ),
            ),
            ?dial,
          ],
        ),
        if (appearance.showSchedule && !large) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var index = 0; index < names.length; index++)
                Expanded(
                  child: Column(
                    children: [
                      for (final value in [names[index], time(index)])
                        line(
                          value,
                          text.labelSmall,
                          color: index == 0 ? accent : ink,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
        if (appearance.showSchedule && large) ...[
          const SizedBox(height: AppSpacing.sm),
          for (var index = 0; index < names.length; index++)
            Container(
              height: _rowHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: index == 0
                    ? accent.withValues(alpha: _highlightAlpha)
                    : null,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: line(
                      names[index],
                      text.bodyMedium,
                      color: index == 0 ? accent : ink,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  line(
                    time(index),
                    text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    color: index == 0 ? accent : ink,
                  ),
                ],
              ),
            ),
        ],
      ];
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: ink.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(_paddings[size]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

/// The dial `PrayerWidgetProvider.countdownDial` draws, in its 76-unit grid.
/// Dhuhr's sun as the Android widget draws it in `PrayerWidgetProvider.kt`,
/// in units of its 76-unit dial.
void _paintSun(Canvas canvas, Offset center, double unit, Paint paint) {
  canvas.drawCircle(center, 5.5 * unit, paint..style = PaintingStyle.fill);
  paint.style = PaintingStyle.stroke;
  for (var ray = 0; ray < 8; ray++) {
    final direction = Offset.fromDirection(ray * math.pi / 4);
    canvas.drawLine(
      center + direction * 8.5 * unit,
      center + direction * 11.5 * unit,
      paint,
    );
  }
}

class _AndroidDialPainter extends CustomPainter {
  final Color accent;
  const _AndroidDialPainter(this.accent);

  // Three quarters of the interval left, as in the preview countdown.
  static const _remaining = 0.75;
  static const _grid = 76.0;
  static const _center = Offset(_grid / 2, _grid / 2);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.shortestSide / _grid);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 35 / 255);
    final ring = Rect.fromCircle(center: _center, radius: 28);
    canvas.drawOval(ring, paint);
    paint.color = accent;
    canvas.drawArc(ring, -math.pi / 2, _remaining * 2 * math.pi, false, paint);
    paint
      ..strokeWidth = 1.5
      ..color = accent.withValues(alpha: 120 / 255);
    for (var tick = 0; tick < 12; tick++) {
      canvas.save();
      canvas.translate(_center.dx, _center.dy);
      canvas.rotate(tick * math.pi / 6);
      canvas.translate(-_center.dx, -_center.dy);
      canvas.drawLine(
        const Offset(_grid / 2, 1),
        Offset(_grid / 2, tick % 3 == 0 ? 6 : 4),
        paint,
      );
      canvas.restore();
    }
    paint
      ..strokeWidth = 2
      ..color = accent;
    // The widget shows the coming prayer's sky; the preview's is Dhuhr.
    _paintSun(canvas, _center, 1, paint);
  }

  @override
  bool shouldRepaint(_AndroidDialPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _WidgetDialPainter extends CustomPainter {
  final Color accent;
  final bool apple;
  const _WidgetDialPainter(this.accent, {required this.apple});

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
    if (apple) {
      // WidgetKit's ticks: 2 pt capsules at 40% accent, longer every quarter.
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent.withValues(alpha: 0.4);
      for (var tick = 0; tick < 12; tick++) {
        final angle = tick * math.pi / 6 - math.pi / 2;
        final direction = Offset(math.cos(angle), math.sin(angle));
        final outer = size.shortestSide / 2 - 4 + 2.5;
        final length = tick % 3 == 0 ? 5 : 3;
        canvas.drawLine(
          center + direction * (outer - length),
          center + direction * outer,
          paint,
        );
      }
    } else {
      // Scale the Android widget's 76-unit dial to this preview.
      _paintSun(canvas, center, size.shortestSide / 76, paint..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_WidgetDialPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.apple != apple;
}
