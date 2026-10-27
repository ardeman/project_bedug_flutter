import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/city_catalog.dart';
import '../utils/hijri_utils.dart';
import '../services/kemenag_method.dart';
import '../services/notification_preferences.dart';

// ─── Preferences ──────────────────────────────────────────────────────────────

/// The app's [SharedPreferences], loaded once in `main` and provided through a
/// `ProviderScope` override, so settings are read synchronously on the first
/// frame instead of switching from defaults after a frame.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider'),
);

// ─── Locale Provider ──────────────────────────────────────────────────────────

const _kLocale = 'app_locale';

class LocaleNotifier extends Notifier<Locale> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Locale build() => Locale(_prefs.getString(_kLocale) ?? 'id');

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _prefs.setString(_kLocale, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

const supportedLocales = [
  Locale('id'),
  Locale('en'),
  Locale('ar'),
  Locale('ms'),
];

const localeDisplayNames = {
  'id': 'Bahasa Indonesia',
  'en': 'English',
  'ar': 'العربية',
  'ms': 'Bahasa Melayu',
};

// ─── Settings ─────────────────────────────────────────────────────────────────

// Earlier builds saved the method's enum index, which breaks when
// methods are added or reordered; it is still read once to migrate.
const _kLegacyMethodIndex = 'calc_method';
const _kMethod = 'calc_method_name';
const _kMadhab = 'madhab';
const _kTheme = 'theme_mode';
const _kUseAutoLocation = 'use_auto_location';
const _kSelectedCityId = 'selected_city_id';
const _kHijriAdjustment = 'hijri_adjustment';
const _kHijriSource = 'hijri_source';

class AppSettings {
  final AppCalculationMethod method;
  final bool isHanafi;
  final int themeMode;
  final bool useAutoLocation;
  final String? selectedCityId;
  final NotificationPreferences notifications;

  /// Days the Hijri dates move from the calculated calendar to follow a
  /// local announcement, one of [hijriAdjustmentOptions].
  final int hijriAdjustment;

  /// Whose calendar the Hijri dates follow.
  final HijriSource hijriSource;

  const AppSettings({
    this.method = AppCalculationMethod.kemenag,
    this.isHanafi = false,
    this.themeMode = 0,
    this.useAutoLocation = true,
    this.selectedCityId,
    this.notifications = const NotificationPreferences(),
    this.hijriAdjustment = 0,
    this.hijriSource = HijriSource.ummAlQura,
  });

  /// How every Hijri date in the app is reckoned.
  HijriReckoning get hijriReckoning =>
      HijriReckoning(source: hijriSource, adjustment: hijriAdjustment);

  AppSettings copyWith({
    AppCalculationMethod? method,
    bool? isHanafi,
    int? themeMode,
    bool? useAutoLocation,
    String? selectedCityId,
    bool clearSelectedCity = false,
    NotificationPreferences? notifications,
    int? hijriAdjustment,
    HijriSource? hijriSource,
  }) => AppSettings(
    hijriAdjustment: hijriAdjustment ?? this.hijriAdjustment,
    hijriSource: hijriSource ?? this.hijriSource,
    notifications: notifications ?? this.notifications,
    method: method ?? this.method,
    isHanafi: isHanafi ?? this.isHanafi,
    themeMode: themeMode ?? this.themeMode,
    useAutoLocation: useAutoLocation ?? this.useAutoLocation,
    selectedCityId: clearSelectedCity
        ? null
        : (selectedCityId ?? this.selectedCityId),
  );
}

class SettingsNotifier extends Notifier<AppSettings> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final p = _prefs;
    return AppSettings(
      method: _storedMethod(p),
      isHanafi: p.getBool(_kMadhab) ?? false,
      themeMode: p.getInt(_kTheme) ?? 0,
      useAutoLocation: p.getBool(_kUseAutoLocation) ?? true,
      selectedCityId: p.getString(_kSelectedCityId),
      hijriAdjustment: switch (p.getInt(_kHijriAdjustment)) {
        final days? when hijriAdjustmentOptions.contains(days) => days,
        _ => 0,
      },
      hijriSource: HijriSource.values.firstWhere(
        (source) => source.name == p.getString(_kHijriSource),
        orElse: () => HijriSource.ummAlQura,
      ),
      notifications: NotificationPreferences(
        enabled: p.getBool('notifications_enabled') ?? true,
        alerts: Set.unmodifiable(_storedAlerts(p)),
        reminders: Map.unmodifiable(_storedReminders(p)),
        sounds: Map.unmodifiable(_storedSounds(p)),
        phoneSounds: Map.unmodifiable(_storedPhoneSounds(p)),
        dzikirReminders: Set.unmodifiable(
          DzikirReminder.values.where(
            (reminder) => (p.getStringList('notification_dzikir') ?? const [])
                .contains(reminder.name),
          ),
        ),
        eventReminders: p.getBool('notification_events') ?? false,
      ),
    );
  }

  /// The method saved by name, else by a legacy index, else Kemenag.
  static AppCalculationMethod _storedMethod(SharedPreferences p) {
    final named = AppCalculationMethod.values
        .where((m) => m.name == p.getString(_kMethod))
        .firstOrNull;
    if (named != null) return named;
    final index = p.getInt(_kLegacyMethodIndex);
    // Guard against an index stored by a build with more methods.
    return index != null &&
            index >= 0 &&
            index < AppCalculationMethod.values.length
        ? AppCalculationMethod.values[index]
        : AppCalculationMethod.kemenag;
  }

  static PrayerNotificationSound? _soundNamed(String? name) =>
      PrayerNotificationSound.values.where((s) => s.name == name).firstOrNull;

  /// Builds before this one saved one sound for every alert.
  static Map<PrayerAlert, PrayerNotificationSound> _storedSounds(
    SharedPreferences p,
  ) {
    final legacy = _soundNamed(p.getString('notification_sound'));
    return {
      for (final alert in PrayerAlert.values)
        alert:
            ?(_soundNamed(p.getString('notification_sound_${alert.name}')) ??
            legacy),
    };
  }

  /// Builds before this one saved one reminder for every alert.
  static Map<PrayerAlert, int> _storedReminders(SharedPreferences p) {
    int? valid(int? minutes) =>
        reminderMinuteOptions.contains(minutes) && minutes! > 0
        ? minutes
        : null;
    final legacy = valid(p.getInt('notification_reminder_minutes'));
    return {
      for (final alert in PrayerAlert.values)
        if (p.containsKey('notification_reminder_${alert.name}'))
          alert: ?valid(p.getInt('notification_reminder_${alert.name}'))
        else
          alert: ?legacy,
    };
  }

  /// Each tone is stored as `[uri, title]`.
  static Map<PrayerAlert, PhoneSound> _storedPhoneSounds(SharedPreferences p) {
    return {
      for (final alert in PrayerAlert.values)
        if (p.getStringList('notification_phone_sound_${alert.name}') case [
          final uri,
          final title,
        ])
          alert: PhoneSound(uri: uri, title: title),
    };
  }

  /// Builds before this one saved only the disabled prayers out of five.
  static Iterable<PrayerAlert> _storedAlerts(SharedPreferences p) {
    final stored = p.getStringList('notification_alerts');
    if (stored != null) {
      return PrayerAlert.values.where((alert) => stored.contains(alert.name));
    }
    final disabled = p.getStringList('notifications_disabled') ?? const [];
    return defaultPrayerAlerts.where((alert) => !disabled.contains(alert.name));
  }

  Future<void> setNotifications(NotificationPreferences value) async {
    state = state.copyWith(notifications: value);
    await _prefs.setBool('notifications_enabled', value.enabled);
    await _prefs.setStringList(
      'notification_alerts',
      value.alerts.map((alert) => alert.name).toList(),
    );
    await _prefs.setStringList(
      'notification_dzikir',
      value.dzikirReminders.map((reminder) => reminder.name).toList(),
    );
    await _prefs.setBool('notification_events', value.eventReminders);
    for (final alert in PrayerAlert.values) {
      await _prefs.setInt(
        'notification_reminder_${alert.name}',
        value.reminderOf(alert),
      );
      await _prefs.setString(
        'notification_sound_${alert.name}',
        value.soundOf(alert).name,
      );
      final phone = value.phoneSounds[alert];
      if (phone == null) {
        await _prefs.remove('notification_phone_sound_${alert.name}');
      } else {
        await _prefs.setStringList('notification_phone_sound_${alert.name}', [
          phone.uri,
          phone.title,
        ]);
      }
    }
    await _prefs.remove('notification_sound');
    await _prefs.remove('notification_reminder_minutes');
  }

  Future<void> setMethod(AppCalculationMethod m) async {
    state = state.copyWith(method: m);
    await _prefs.setString(_kMethod, m.name);
    await _prefs.remove(_kLegacyMethodIndex);
  }

  Future<void> setMadhab(bool isHanafi) async {
    state = state.copyWith(isHanafi: isHanafi);
    await _prefs.setBool(_kMadhab, isHanafi);
  }

  Future<void> setThemeMode(int mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt(_kTheme, mode);
  }

  Future<void> setHijriAdjustment(int days) async {
    state = state.copyWith(hijriAdjustment: days);
    await _prefs.setInt(_kHijriAdjustment, days);
  }

  Future<void> setHijriSource(HijriSource source) async {
    state = state.copyWith(hijriSource: source);
    await _prefs.setString(_kHijriSource, source.name);
  }

  Future<void> setUseAutoLocation(bool enabled) async {
    state = state.copyWith(useAutoLocation: enabled);
    await _prefs.setBool(_kUseAutoLocation, enabled);
  }

  Future<void> setSelectedCityId(String? cityId) async {
    if (cityId == null || cityId.isEmpty) {
      state = state.copyWith(clearSelectedCity: true);
      await _prefs.remove(_kSelectedCityId);
      return;
    }
    state = state.copyWith(selectedCityId: cityId);
    await _prefs.setString(_kSelectedCityId, cityId);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// The city prayer times use when auto detect is off: the picked one, or the
/// default for the app language until one is picked.
final manualCityProvider = Provider<CityOption>((ref) {
  final id = ref.watch(settingsProvider.select((s) => s.selectedCityId));
  return cityById(id) ?? defaultCityFor(ref.watch(localeProvider).languageCode);
});
