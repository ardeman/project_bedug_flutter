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

enum PrayerNotificationSound { system, silent }

/// Device-local preferences.
class NotificationPreferences {
  final bool enabled;
  final Set<PrayerAlert> alerts;
  final int reminderMinutes;
  final PrayerNotificationSound sound;

  const NotificationPreferences({
    this.enabled = true,
    this.alerts = defaultPrayerAlerts,
    this.reminderMinutes = 0,
    this.sound = PrayerNotificationSound.system,
  });

  bool includes(PrayerAlert alert) => enabled && alerts.contains(alert);

  NotificationPreferences copyWith({
    bool? enabled,
    Set<PrayerAlert>? alerts,
    int? reminderMinutes,
    PrayerNotificationSound? sound,
  }) => NotificationPreferences(
    enabled: enabled ?? this.enabled,
    alerts: Set.unmodifiable(alerts ?? this.alerts),
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    sound: sound ?? this.sound,
  );
}
