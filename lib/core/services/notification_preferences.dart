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
/// `ios|macos/Runner/Sounds`, the previews in `assets/sounds`. [phone] is
/// a tone installed on an Android phone, kept in
/// [NotificationPreferences.phoneSounds].
enum PrayerNotificationSound {
  system,
  bedug,
  siren,
  phone,
  silent;

  /// The bundled file's name without its extension, or null for none.
  String? get resource => switch (this) {
    bedug || siren => 'prayer_$name',
    system || phone || silent => null,
  };
}

/// A tone picked from the phone's own sounds (Android only).
class PhoneSound {
  /// The tone's content URI, as the system picker returned it.
  final String uri;

  /// The tone's name, as the system shows it.
  final String title;

  const PhoneSound({required this.uri, required this.title});
}

/// Device-local preferences.
class NotificationPreferences {
  final bool enabled;
  final Set<PrayerAlert> alerts;

  /// Each alert's early reminder in minutes; an alert missing here has none.
  final Map<PrayerAlert, int> reminders;

  /// Each alert's sound; an alert missing here plays the system sound.
  final Map<PrayerAlert, PrayerNotificationSound> sounds;

  /// The tone of each alert whose sound is [PrayerNotificationSound.phone].
  final Map<PrayerAlert, PhoneSound> phoneSounds;

  const NotificationPreferences({
    this.enabled = true,
    this.alerts = defaultPrayerAlerts,
    this.reminders = const {},
    this.sounds = const {},
    this.phoneSounds = const {},
  });

  bool includes(PrayerAlert alert) => enabled && alerts.contains(alert);

  int reminderOf(PrayerAlert alert) => reminders[alert] ?? 0;

  /// A phone sound without a stored tone falls back to the system sound.
  PrayerNotificationSound soundOf(PrayerAlert alert) => switch (sounds[alert]) {
    PrayerNotificationSound.phone when phoneSounds[alert] == null =>
      PrayerNotificationSound.system,
    final sound? => sound,
    null => PrayerNotificationSound.system,
  };

  NotificationPreferences copyWith({
    bool? enabled,
    Set<PrayerAlert>? alerts,
    Map<PrayerAlert, int>? reminders,
    Map<PrayerAlert, PrayerNotificationSound>? sounds,
    Map<PrayerAlert, PhoneSound>? phoneSounds,
  }) => NotificationPreferences(
    enabled: enabled ?? this.enabled,
    alerts: Set.unmodifiable(alerts ?? this.alerts),
    reminders: Map.unmodifiable(reminders ?? this.reminders),
    sounds: Map.unmodifiable(sounds ?? this.sounds),
    phoneSounds: Map.unmodifiable(phoneSounds ?? this.phoneSounds),
  );
}
