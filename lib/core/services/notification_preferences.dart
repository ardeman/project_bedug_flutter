import 'package:adhan/adhan.dart';

/// The five obligatory prayers, in daily order.
const notificationPrayers = [
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

/// Every time on the prayer timeline that can send an alert, in timeline
/// order; names are stable storage keys.
enum PrayerAlert {
  lastThirdOfNight,
  imsak,
  fajr,
  sunrise,
  dhuha,
  dhuhr,
  asr,
  maghrib,
  isha,
}

/// Alerts that are on until the user changes them: the five prayers.
const defaultPrayerAlerts = {
  PrayerAlert.fajr,
  PrayerAlert.dhuhr,
  PrayerAlert.asr,
  PrayerAlert.maghrib,
  PrayerAlert.isha,
};

const reminderMinuteOptions = [0, 5, 10, 15, 30];

/// What an alert plays. [bedug] and [siren] are bundled recordings: the
/// native copies live in `android/app/src/main/res/raw` and
/// `ios|macos/Runner/Sounds`, the previews in `assets/sounds`.
enum PrayerNotificationSound {
  system,
  bedug,
  siren,
  silent;

  /// The bundled file's name without its extension, or null for none.
  String? get resource => switch (this) {
    bedug || siren => 'prayer_$name',
    system || silent => null,
  };
}

/// Device-local preferences.
class NotificationPreferences {
  final bool enabled;
  final Set<PrayerAlert> alerts;
  final int reminderMinutes;

  /// Each alert's sound; an alert missing here plays the system sound.
  final Map<PrayerAlert, PrayerNotificationSound> sounds;

  const NotificationPreferences({
    this.enabled = true,
    this.alerts = defaultPrayerAlerts,
    this.reminderMinutes = 0,
    this.sounds = const {},
  });

  bool includes(PrayerAlert alert) => enabled && alerts.contains(alert);

  PrayerNotificationSound soundOf(PrayerAlert alert) =>
      sounds[alert] ?? PrayerNotificationSound.system;

  NotificationPreferences copyWith({
    bool? enabled,
    Set<PrayerAlert>? alerts,
    int? reminderMinutes,
    Map<PrayerAlert, PrayerNotificationSound>? sounds,
  }) => NotificationPreferences(
    enabled: enabled ?? this.enabled,
    alerts: Set.unmodifiable(alerts ?? this.alerts),
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    sounds: Map.unmodifiable(sounds ?? this.sounds),
  );
}
