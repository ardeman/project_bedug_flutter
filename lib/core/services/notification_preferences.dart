import 'package:adhan/adhan.dart';

const notificationPrayers = [
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

const reminderMinuteOptions = [0, 5, 10, 15, 30];

enum PrayerNotificationSound { system, silent }

/// Device-local preferences; prayer names are stable storage keys.
class NotificationPreferences {
  final bool enabled;
  final Set<Prayer> disabledPrayers;
  final int reminderMinutes;
  final PrayerNotificationSound sound;

  const NotificationPreferences({
    this.enabled = true,
    this.disabledPrayers = const {},
    this.reminderMinutes = 0,
    this.sound = PrayerNotificationSound.system,
  });

  bool includes(Prayer prayer) => enabled && !disabledPrayers.contains(prayer);

  NotificationPreferences copyWith({
    bool? enabled,
    Set<Prayer>? disabledPrayers,
    int? reminderMinutes,
    PrayerNotificationSound? sound,
  }) => NotificationPreferences(
    enabled: enabled ?? this.enabled,
    disabledPrayers: Set.unmodifiable(disabledPrayers ?? this.disabledPrayers),
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    sound: sound ?? this.sound,
  );
}
