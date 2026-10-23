import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:adhan/adhan.dart';

import '../../generated/l10n/app_localizations.dart';
import 'extra_prayer_times.dart';
import 'notification_preferences.dart';
import 'notification_schedule.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Completes with whether the plugin initialized on this platform.
  static Future<bool>? _ready;

  /// Starts initialization once; [schedulePrayerNotifications] waits for it.
  static Future<bool> init() => _ready ??= _init();

  static Future<bool> _init() async {
    try {
      await _initialize();
      return true;
    } catch (_) {
      // No notification support on this platform (or in tests).
      return false;
    }
  }

  static Future<void> _initialize() async {
    final l10n = _resolveL10n();
    const android = AndroidInitializationSettings('ic_stat_bedug');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final linux = LinuxInitializationSettings(
      defaultActionName: l10n.openAction,
    );

    await _plugin.initialize(
      settings: InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        linux: linux,
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static bool get supportsScheduling =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static Future<void> _queue = Future.value();

  /// Serializes replacements so rapid setting changes cannot leave old alerts.
  static Future<void> schedulePrayerNotifications(
    PrayerTimes? times,
    AppLocalizations l10n,
    NotificationPreferences preferences,
  ) {
    final result = _queue.then((_) => _replace(times, l10n, preferences));
    _queue = result.catchError((Object _) {});
    return result;
  }

  static Future<void> _replace(
    PrayerTimes? times,
    AppLocalizations l10n,
    NotificationPreferences preferences,
  ) async {
    if (!supportsScheduling) return;
    if (!await init()) throw StateError(l10n.notificationSchedulingError);
    await _plugin.cancelAll();
    if (times == null) return;
    final schedule = buildNotificationSchedule(times, preferences, clock.now());
    if (schedule.isEmpty) return;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exact = await android?.canScheduleExactNotifications() ?? false;
    final playSound = preferences.sound == PrayerNotificationSound.system;
    for (final alert in schedule) {
      final name = switch (alert.alert) {
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
      final body = alert.isReminder
          ? l10n.prayerReminderBody(name, preferences.reminderMinutes)
          : switch (alert.alert) {
              PrayerAlert.lastThirdOfNight => l10n.notifLastThirdOfNight,
              PrayerAlert.imsak => l10n.notifImsak(
                ExtraPrayerTimes.imsakLead.inMinutes,
              ),
              PrayerAlert.fajr => l10n.notifSubuh,
              PrayerAlert.sunrise => l10n.notifSunrise,
              PrayerAlert.dhuha => l10n.notifDhuha,
              PrayerAlert.dhuhr => l10n.notifDzuhur,
              PrayerAlert.asr => l10n.notifAshar,
              PrayerAlert.maghrib => l10n.notifMaghrib,
              PrayerAlert.isha => l10n.notifIsya,
            };
      await _plugin.zonedSchedule(
        id: alert.id,
        scheduledDate: tz.TZDateTime.from(alert.time, tz.local),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        title: name,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            // Android channel sound is immutable after creation.
            'bedug_prayer_v2_${preferences.sound.name}',
            playSound ? l10n.notificationChannelName : l10n.silentPrayerChannel,
            channelDescription: l10n.notificationChannelDescription,
            icon: 'ic_stat_bedug',
            importance: Importance.high,
            priority: Priority.high,
            playSound: playSound,
            silent: !playSound,
            enableVibration: playSound,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: playSound,
            presentBanner: true,
            presentList: true,
          ),
          macOS: DarwinNotificationDetails(presentSound: playSound),
        ),
      );
    }
  }

  static Future<void> openSystemSettings() async {
    if (!await init()) return;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.openAppNotificationSettings();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.openAppNotificationSettings();
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.openAppNotificationSettings();
    }
  }

  static Future<void> requestPreciseAlarms() async {
    if (!await init()) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  static AppLocalizations _resolveL10n() {
    final locale = PlatformDispatcher.instance.locale;
    try {
      return lookupAppLocalizations(locale);
    } catch (_) {
      return lookupAppLocalizations(const Locale('id'));
    }
  }
}
