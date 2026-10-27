import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoTheme;

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
import '../../core/utils/hijri_utils.dart';
import '../../core/widgets/calculation_method_picker.dart';
import '../../core/widgets/city_picker.dart';
import '../../core/widgets/glass_menu.dart';
import '../../generated/l10n/app_localizations.dart';
import '../changelog/changelog_screen.dart';
import '../dzikir/dzikir.dart';
import '../infaq/infaq_provider.dart';
import '../infaq/infaq_screen.dart';
import 'settings_section.dart';

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
    final dzikirCollections = ref.watch(dzikirCollectionsProvider).value;

    final sections = [
      // ── Section: Salat ─────────────────────────────────────────────────
      SettingsSection(
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

          // Hijri date adjustment
          _ChoiceTile<int>(
            icon: Icons.calendar_month_outlined,
            title: l10n.hijriAdjustment,
            subtitle: Text(l10n.hijriAdjustmentSubtitle),
            value: settings.hijriAdjustment,
            options: [
              for (final days in hijriAdjustmentOptions)
                GlassMenuOption(
                  value: days,
                  label: switch (days) {
                    0 => l10n.hijriAdjustmentNone,
                    > 0 => l10n.hijriAdjustmentLater(days),
                    _ => l10n.hijriAdjustmentEarlier(-days),
                  },
                ),
            ],
            onChanged: notifier.setHijriAdjustment,
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

      // ── Section: Ibadah (shown once there is a collection to choose) ──
      if (dzikirCollections case final collections? when collections.length > 1)
        SettingsSection(
          title: l10n.worship,
          children: [
            _ChoiceTile<String>(
              icon: Icons.menu_book_outlined,
              title: l10n.dzikirCollection,
              value: ref.watch(dzikirCollectionIdProvider),
              options: [
                for (final c in collections)
                  GlassMenuOption(
                    value: c.id,
                    label: c.nameFor(locale.languageCode),
                  ),
              ],
              onChanged: ref.read(dzikirCollectionIdProvider.notifier).select,
            ),
          ],
        ),

      // ── Section: Tampilan ────────────────────────────────────────────────
      SettingsSection(
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
      SettingsSection(
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
      SettingsSection(
        title: l10n.about,
        children: [
          PlatformListTile(
            leading: Icon(
              Icons.volunteer_activism_outlined,
              color: AppColors.accentOf(ctx),
            ),
            title: Text(l10n.infaq),
            subtitle: Text(
              ref.watch(infaqProvider.select((s) => s.adFree))
                  ? l10n.infaqThanksSubtitle
                  : l10n.infaqSubtitle,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(builder: (_) => const InfaqScreen()),
            ),
          ),
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

String _alertName(AppLocalizations l10n, PrayerAlert alert) => switch (alert) {
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

/// The alert's sound as the menu names it; a picked phone tone by its name.
String _soundLabel(
  AppLocalizations l10n,
  NotificationPreferences preferences,
  PrayerAlert alert,
  PrayerNotificationSound sound,
) => switch (sound) {
  PrayerNotificationSound.system => l10n.systemNotificationSound,
  PrayerNotificationSound.bedug => l10n.bedugNotificationSound,
  PrayerNotificationSound.siren => l10n.sirenNotificationSound,
  PrayerNotificationSound.phone =>
    preferences.soundOf(alert) == sound
        ? preferences.phoneSounds[alert]!.title
        : l10n.phoneNotificationSound,
  PrayerNotificationSound.silent => l10n.silentNotificationSound,
};

/// One row per time: its switch, and when it's on, a summary of its sound
/// and reminder that opens [_NotificationTimeScreen]. Each alert plays the
/// system sound, a bundled bedug or siren, a phone tone, or nothing; never
/// a recorded azan.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final l10n = AppLocalizations.of(ctx);
    final preferences = ref.watch(settingsProvider).notifications;
    final notifier = ref.read(settingsProvider.notifier);
    final failed = ref.watch(prayerProvider.select((s) => s.notificationError));
    final muted = Theme.of(ctx).colorScheme.onSurfaceVariant;
    void setAlert(PrayerAlert alert, bool value) {
      final alerts = {...preferences.alerts};
      value ? alerts.add(alert) : alerts.remove(alert);
      notifier.setNotifications(preferences.copyWith(alerts: alerts));
    }

    void setDzikir(DzikirReminder reminder, bool value) {
      final reminders = {...preferences.dzikirReminders};
      value ? reminders.add(reminder) : reminders.remove(reminder);
      notifier.setNotifications(
        preferences.copyWith(dzikirReminders: reminders),
      );
    }

    String summaryOf(PrayerAlert alert) {
      final minutes = preferences.reminderOf(alert);
      return [
        _soundLabel(l10n, preferences, alert, preferences.soundOf(alert)),
        if (minutes > 0) l10n.minutesBeforePrayer(minutes),
      ].join(' · ');
    }

    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: l10n.notifications),
      body: ListView(
        children: [
          SettingsSection(
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
            ],
          ),
          if (failed)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(l10n.notificationSchedulingError),
            ),
          if (preferences.enabled)
            SettingsSection(
              title: l10n.notificationTimes,
              children: [
                for (final alert in PrayerAlert.values)
                  PlatformListTile(
                    key: ValueKey('notification-row-${alert.name}'),
                    title: Text(_alertName(l10n, alert)),
                    subtitle: preferences.includes(alert)
                        ? Text(
                            summaryOf(alert),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AdaptiveSwitch(
                          key: ValueKey('notification-${alert.name}'),
                          value: preferences.includes(alert),
                          onChanged: (value) => setAlert(alert, value),
                        ),
                        // Keeps the switches aligned whether or not the
                        // row opens its detail page.
                        Opacity(
                          opacity: preferences.includes(alert) ? 1 : 0,
                          child: Icon(Icons.chevron_right, color: muted),
                        ),
                      ],
                    ),
                    // An off time turns on; an on time opens its options.
                    onTap: preferences.includes(alert)
                        ? () => Navigator.of(ctx).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  _NotificationTimeScreen(alert: alert),
                            ),
                          )
                        : () => setAlert(alert, true),
                  ),
              ],
            ),
          // Collections without morning and evening sessions get no
          // reminders.
          if (preferences.enabled &&
              (ref.watch(selectedDzikirCollectionProvider).value?.hasSessions ??
                  false))
            SettingsSection(
              title: l10n.dzikir,
              children: [
                for (final reminder in DzikirReminder.values)
                  PlatformListTile(
                    key: ValueKey('dzikir-reminder-row-${reminder.name}'),
                    title: Text(switch (reminder) {
                      DzikirReminder.morning => l10n.dzikirMorningReminder,
                      DzikirReminder.evening => l10n.dzikirEveningReminder,
                    }),
                    subtitle: Text(
                      l10n.dzikirReminderAfter(
                        dzikirReminderDelay.inMinutes,
                        switch (reminder) {
                          DzikirReminder.morning => l10n.fajr,
                          DzikirReminder.evening => l10n.asr,
                        },
                      ),
                    ),
                    trailing: _AdaptiveSwitch(
                      key: ValueKey('dzikir-reminder-${reminder.name}'),
                      value: preferences.includesDzikir(reminder),
                      onChanged: (value) => setDzikir(reminder, value),
                    ),
                    onTap: () => setDzikir(
                      reminder,
                      !preferences.includesDzikir(reminder),
                    ),
                  ),
              ],
            ),
          if (preferences.enabled)
            SettingsSection(
              title: l10n.hijriEvents,
              children: [
                PlatformListTile(
                  key: const ValueKey('event-reminder-row'),
                  title: Text(l10n.hijriEventReminder),
                  subtitle: Text(l10n.hijriEventReminderSubtitle),
                  trailing: _AdaptiveSwitch(
                    key: const ValueKey('event-reminder'),
                    value: preferences.includesEvents,
                    onChanged: (value) => notifier.setNotifications(
                      preferences.copyWith(eventReminders: value),
                    ),
                  ),
                  onTap: () => notifier.setNotifications(
                    preferences.copyWith(
                      eventReminders: !preferences.eventReminders,
                    ),
                  ),
                ),
              ],
            ),
          if (NotificationService.supportsScheduling)
            SettingsSection(
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
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              NotificationService.supportsScheduling
                  ? l10n.notificationDeliveryInfo
                  : l10n.notificationPlatformUnavailable,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// One time's early reminder and sound.
class _NotificationTimeScreen extends ConsumerWidget {
  final PrayerAlert alert;

  const _NotificationTimeScreen({required this.alert});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final l10n = AppLocalizations.of(ctx);
    final preferences = ref.watch(settingsProvider).notifications;
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      extendBodyBehindAppBar: PlatformCapabilities.isApple,
      appBar: GlassTopBar(title: _alertName(l10n, alert)),
      body: ListView(
        children: [
          SettingsSection(
            children: [
              _ChoiceTile<PrayerNotificationSound>(
                key: ValueKey('notification-sound-${alert.name}'),
                icon:
                    preferences.soundOf(alert) == PrayerNotificationSound.silent
                    ? Icons.volume_off_outlined
                    : Icons.volume_up_outlined,
                title: l10n.notificationSound,
                value: preferences.soundOf(alert),
                options: [
                  for (final sound in PrayerNotificationSound.values)
                    if (sound != PrayerNotificationSound.phone ||
                        PhoneSoundPicker.isSupported)
                      GlassMenuOption(
                        value: sound,
                        label: _soundLabel(l10n, preferences, alert, sound),
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
                      phoneSounds: {...latest.phoneSounds, alert: ?picked},
                    ),
                  );
                },
              ),
              _ChoiceTile<int>(
                key: ValueKey('notification-reminder-${alert.name}'),
                icon: Icons.alarm_outlined,
                title: l10n.beforePrayerReminder,
                value: preferences.reminderOf(alert),
                options: [
                  for (final minutes in reminderMinuteOptions)
                    GlassMenuOption(
                      value: minutes,
                      label: minutes == 0
                          ? l10n.reminderOff
                          : l10n.minutesBeforePrayer(minutes),
                    ),
                ],
                onChanged: (minutes) {
                  final latest = ref.read(settingsProvider).notifications;
                  notifier.setNotifications(
                    latest.copyWith(
                      reminders: {...latest.reminders, alert: minutes},
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
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

// Sample order is Dhuhr through Fajr; current-prayer mode starts at Asr.
IconData _widgetPreviewPrayerIcon(int index, {bool showCurrent = false}) {
  const icons = [
    Icons.wb_sunny_outlined,
    Icons.wb_cloudy_outlined,
    Icons.nights_stay_outlined,
    Icons.dark_mode_outlined,
    Icons.bedtime_outlined,
  ];
  return icons[(index + (showCurrent ? 1 : 0)) % icons.length];
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
          SettingsSection(
            title: l10n.widgetStyle,
            children: [
              if (PlatformCapabilities.isApple)
                PlatformListTile(
                  title: Text(l10n.widgetShowCurrent),
                  subtitle: Text(l10n.widgetShowCurrentDescription),
                  trailing: _AdaptiveSwitch(
                    key: const ValueKey('widget_current_switch'),
                    value: appearance.showCurrent,
                    onChanged: notifier.setShowCurrent,
                  ),
                ),
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
    final showCurrent = PlatformCapabilities.isApple && appearance.showCurrent;
    final names = showCurrent
        ? [l10n.asr, l10n.maghrib, l10n.isha, l10n.fajr, l10n.dhuhr]
        : [l10n.dhuhr, l10n.asr, l10n.maghrib, l10n.isha, l10n.fajr];
    final hours = showCurrent ? [15, 18, 19, 4, 12] : [12, 15, 18, 19, 4];
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
            constraints: BoxConstraints(maxWidth: size == 0 ? 200 : 400),
            child: !PlatformCapabilities.isApple
                ? _AndroidWidgetCard(
                    size: size,
                    appearance: appearance,
                    names: names,
                    time: time,
                    location: location,
                  )
                : _AppleWidgetCard(
                    size: size,
                    appearance: appearance,
                    names: names,
                    time: time,
                    location: location,
                  ),
          ),
        ),
      ],
    );
  }
}

/// A scaled WidgetKit canvas, following PrayerWidgetView's sizes and spacing.
/// Keep app text scaling outside this illustration: widget text has its own
/// system typography, independent of the app's Plus Jakarta Sans theme.
class _AppleWidgetCard extends StatelessWidget {
  final int size;
  final WidgetAppearance appearance;
  final List<String> names;
  final String Function(int index) time;
  final String location;

  const _AppleWidgetCard({
    required this.size,
    required this.appearance,
    required this.names,
    required this.time,
    required this.location,
  });

  // Representative iPhone widget canvases; WidgetKit varies them by device.
  static const _canvases = [Size(170, 170), Size(364, 170), Size(364, 382)];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Match the palette sent to WidgetKit, rather than the app's glass tint.
    final background = dark ? AppColors.darkBg : AppColors.lightBg;
    final ink = dark ? AppColors.darkText : AppColors.lightText;
    final accent = dark ? AppColors.emeraldDark : AppColors.emerald;
    final small = size == 0;
    final large = size == 2;
    final focus = large && !appearance.showSchedule;
    final city = location
        .replaceFirst(
          RegExp(r'^(Kota Administrasi |Kabupaten |Kab\. |Kota )'),
          '',
        )
        .split(',')
        .first
        .trim();
    final family = CupertinoTheme.of(context).textTheme.textStyle.fontFamily;

    // SwiftUI default point sizes for caption, title2, title and callout.
    TextStyle style(double points, {FontWeight weight = FontWeight.normal}) =>
        text.bodyMedium!.copyWith(
          fontFamily: family,
          fontSize: points,
          height: 1.2,
          letterSpacing: 0,
          fontWeight: weight,
          color: ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    Widget label(
      String value,
      double points, {
      Color? color,
      FontWeight weight = FontWeight.normal,
      TextAlign? align,
    }) => Text(
      value,
      style: style(points, weight: weight).copyWith(color: color ?? ink),
      maxLines: 1,
      textAlign: align,
    );
    Widget fit(
      Widget child, {
      AlignmentGeometry alignment = AlignmentDirectional.centerStart,
    }) => FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child);
    final headline = appearance.showCurrent ? l10n.dhuhr : names.first;
    final timeLine = appearance.showCurrent
        ? '${names.first} · ${time(0)}'
        : time(0);
    Widget countdown({bool prominent = false}) => fit(
      label(
        l10n.widgetPreviewCountdown,
        prominent ? 34 : 22,
        weight: prominent
            ? FontWeight.bold
            : small
            ? FontWeight.normal
            : FontWeight.w600,
      ),
      alignment: focus ? Alignment.center : AlignmentDirectional.centerStart,
    );
    Widget dial(double diameter) => ExcludeSemantics(
      child: SizedBox.square(
        key: ValueKey('widget_preview_analog_$size'),
        dimension: diameter,
        child: CustomPaint(
          painter: _WidgetDialPainter(accent),
          child: Icon(
            _widgetPreviewPrayerIcon(0, showCurrent: appearance.showCurrent),
            size: 22,
            color: accent,
          ),
        ),
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xxs,
      children: [
        fit(
          label(
            headline,
            small || large ? 28 : 22,
            color: accent,
            weight: FontWeight.bold,
          ),
        ),
        fit(label(timeLine, small ? 13 : 16)),
        if (!small) countdown(),
      ],
    );
    // The outer VStack uses six points between sections (14 on large widgets).
    final gap = large ? 14.0 : 6.0;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: large
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      spacing: gap,
      children: [
        Row(
          children: [
            Flexible(
              child: fit(
                label(
                  appearance.showCurrent ? l10n.widgetNow : l10n.nextPrayer,
                  13,
                ),
              ),
            ),
            if (!small) ...[
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: fit(
                  label(city, 13, color: ink.withValues(alpha: 0.65)),
                  alignment: AlignmentDirectional.centerEnd,
                ),
              ),
            ],
          ],
        ),
        if (focus)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.xs,
                children: [
                  if (appearance.showAnalog) dial(144),
                  fit(
                    label(headline, 28, weight: FontWeight.bold, color: accent),
                  ),
                  fit(label(timeLine, 20)),
                  countdown(prominent: true),
                ],
              ),
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(child: details),
              if (appearance.showAnalog) ...[
                SizedBox(width: small ? AppSpacing.xs : AppSpacing.md),
                dial(
                  small
                      ? 48
                      : large
                      ? 96
                      : 70,
                ),
              ],
            ],
          ),
          if (small) ...[
            countdown(),
            fit(label(city, 13)),
          ] else if (appearance.showSchedule)
            if (large)
              Expanded(
                child: Column(
                  children: [
                    for (var index = 1; index < names.length; index++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Icon(
                                _widgetPreviewPrayerIcon(
                                  index,
                                  showCurrent: appearance.showCurrent,
                                ),
                                size: 18,
                                color: ink,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(child: fit(label(names[index], 15))),
                              const SizedBox(width: AppSpacing.xs),
                              label(time(index), 15),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Row(
                spacing: AppSpacing.xxs,
                children: [
                  for (var index = 1; index < names.length; index++)
                    Expanded(
                      child: Column(
                        key: ValueKey('widget_preview_schedule_${size}_$index'),
                        mainAxisSize: MainAxisSize.min,
                        spacing: 2,
                        children: [
                          fit(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 2,
                              children: [
                                Icon(
                                  _widgetPreviewPrayerIcon(
                                    index,
                                    showCurrent: appearance.showCurrent,
                                  ),
                                  size: 11,
                                  color: ink,
                                ),
                                label(names[index], 11),
                              ],
                            ),
                            alignment: Alignment.center,
                          ),
                          fit(
                            label(time(index), 11),
                            alignment: Alignment.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
        ],
      ],
    );
    final canvas = _canvases[size];
    return AspectRatio(
      key: ValueKey('widget_preview_apple_$size'),
      aspectRatio: canvas.aspectRatio,
      child: FittedBox(
        child: SizedBox.fromSize(
          size: canvas,
          child: MediaQuery.withNoTextScaling(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                // The native widget palette can match the page background.
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: content,
              ),
            ),
          ),
        ),
      ),
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
              for (var index = 1; index < names.length; index++)
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        _widgetPreviewPrayerIcon(index),
                        size: 16,
                        color: ink,
                      ),
                      for (final value in [names[index], time(index)])
                        line(value, text.labelSmall, color: ink),
                    ],
                  ),
                ),
            ],
          ),
        ],
        if (appearance.showSchedule && large) ...[
          const SizedBox(height: AppSpacing.sm),
          for (var index = 1; index < names.length; index++)
            Container(
              height: _rowHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                children: [
                  Icon(_widgetPreviewPrayerIcon(index), size: 16, color: ink),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: line(names[index], text.bodyMedium, color: ink),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  line(
                    time(index),
                    text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    color: ink,
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

/// WidgetKit's ring has a heavier stroke with ticks inside its outer edge.
class _WidgetDialPainter extends CustomPainter {
  final Color accent;
  const _WidgetDialPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = size.shortestSide / 10;
    final radius = (size.shortestSide - stroke) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.25);
    final ring = Rect.fromCircle(center: center, radius: radius);
    canvas.drawOval(ring, paint);
    paint.color = accent;
    canvas.drawArc(ring, -math.pi / 2, math.pi * 1.5, false, paint);
    // Same 2 pt capsules and positions as countdownDial in SwiftUI.
    paint
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
  }

  @override
  bool shouldRepaint(_WidgetDialPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
