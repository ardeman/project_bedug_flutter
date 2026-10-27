import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:adhan/adhan.dart';

import '../../features/hijri_events/hijri_events.dart';
import '../../generated/l10n/app_localizations.dart';
import 'extra_prayer_times.dart';
import 'notification_preferences.dart';
import 'notification_schedule.dart';
import 'prayer_service.dart';

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
    const androidSettings = AndroidInitializationSettings('ic_stat_bedug');
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
        android: androidSettings,
        iOS: darwin,
        macOS: darwin,
        linux: linux,
      ),
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    // Channels from builds with one sound for every alert.
    for (final legacy in const ['system', 'silent']) {
      await android?.deleteNotificationChannel(
        channelId: 'bedug_prayer_v2_$legacy',
      );
    }
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
    NotificationPreferences preferences, [
    int hijriAdjustment = 0,
  ]) {
    final result = _queue.then(
      (_) => _replace(times, l10n, preferences, hijriAdjustment),
    );
    _queue = result.catchError((Object _) {});
    return result;
  }

  static Future<void> _replace(
    PrayerTimes? times,
    AppLocalizations l10n,
    NotificationPreferences preferences,
    int hijriAdjustment,
  ) async {
    if (!supportsScheduling) return;
    if (!await init()) throw StateError(l10n.notificationSchedulingError);
    await _plugin.cancelAll();
    if (times == null) return;
    final schedule = buildNotificationSchedule(
      times,
      preferences,
      clock.now(),
      events: preferences.includesEvents ? await _loadEvents() : null,
      hijriAdjustment: hijriAdjustment,
    );
    if (schedule.isEmpty) return;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exact = await android?.canScheduleExactNotifications() ?? false;
    final phoneChannels = <String>{};
    for (final alert in schedule) {
      final name = switch (alert.alert) {
        PrayerAlert.lastThirdOfNight => l10n.lastThirdOfNight,
        PrayerAlert.imsak => l10n.imsak,
        PrayerAlert.fajr => l10n.fajr,
        PrayerAlert.sunrise => l10n.sunrise,
        PrayerAlert.dhuha => l10n.dhuha,
        PrayerAlert.dhuhr => dhuhrName(l10n, alert.time),
        PrayerAlert.asr => l10n.asr,
        PrayerAlert.maghrib => l10n.maghrib,
        PrayerAlert.isha => l10n.isha,
      };
      final dzikir = alert.dzikir;
      final events = alert.events;
      final title = events != null
          ? events
                .map((e) => e.nameFor(l10n.localeName.split('_').first))
                .join(' · ')
          : switch (dzikir) {
              DzikirReminder.morning => l10n.dzikirMorningReminder,
              DzikirReminder.evening => l10n.dzikirEveningReminder,
              null => name,
            };
      final body = events != null
          ? l10n.notifHijriEventTomorrow
          : dzikir != null
          ? switch (dzikir) {
              DzikirReminder.morning => l10n.notifDzikirMorning,
              DzikirReminder.evening => l10n.notifDzikirEvening,
            }
          : alert.isReminder
          ? l10n.prayerReminderBody(name, preferences.reminderOf(alert.alert))
          : switch (alert.alert) {
              PrayerAlert.lastThirdOfNight => l10n.notifLastThirdOfNight,
              PrayerAlert.imsak => l10n.notifImsak(
                ExtraPrayerTimes.imsakLead.inMinutes,
              ),
              PrayerAlert.fajr => l10n.notifSubuh,
              PrayerAlert.sunrise => l10n.notifSunrise,
              PrayerAlert.dhuha => l10n.notifDhuha,
              PrayerAlert.dhuhr =>
                alert.time.weekday == DateTime.friday
                    ? l10n.notifJumuah
                    : l10n.notifDzuhur,
              PrayerAlert.asr => l10n.notifAshar,
              PrayerAlert.maghrib => l10n.notifMaghrib,
              PrayerAlert.isha => l10n.notifIsya,
            };
      // Dzikir and event reminders play the system sound, not their
      // prayer's.
      final sound = dzikir != null || events != null
          ? PrayerNotificationSound.system
          : preferences.soundOf(alert.alert);
      final playSound = sound != PrayerNotificationSound.silent;
      final resource = sound.resource;
      final phone = sound == PrayerNotificationSound.phone
          ? preferences.phoneSounds[alert.alert]
          : null;
      final channelId = phone == null
          ? 'bedug_prayer_v3_${sound.name}'
          : phoneChannelId(phone);
      if (phone != null) phoneChannels.add(channelId);
      await _plugin.zonedSchedule(
        id: alert.id,
        scheduledDate: tz.TZDateTime.from(alert.time, tz.local),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            // Android channel sound is immutable after creation, so each
            // sound gets its own channel.
            channelId,
            switch (sound) {
              PrayerNotificationSound.system => l10n.notificationChannelName,
              PrayerNotificationSound.silent => l10n.silentPrayerChannel,
              PrayerNotificationSound.bedug => l10n.soundPrayerChannel(
                l10n.bedugNotificationSound,
              ),
              PrayerNotificationSound.siren => l10n.soundPrayerChannel(
                l10n.sirenNotificationSound,
              ),
              PrayerNotificationSound.phone => l10n.soundPrayerChannel(
                phone?.title ?? '',
              ),
            },
            channelDescription: l10n.notificationChannelDescription,
            icon: 'ic_stat_bedug',
            importance: Importance.high,
            priority: Priority.high,
            playSound: playSound,
            sound: switch ((resource, phone)) {
              (final resource?, _) => RawResourceAndroidNotificationSound(
                resource,
              ),
              (_, final phone?) => UriAndroidNotificationSound(phone.uri),
              _ => null,
            },
            silent: !playSound,
            enableVibration: playSound,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: playSound,
            sound: resource == null ? null : '$resource.caf',
            presentBanner: true,
            presentList: true,
          ),
          macOS: DarwinNotificationDetails(
            presentSound: playSound,
            sound: resource == null ? null : '$resource.caf',
          ),
        ),
      );
    }
    // Drop the channels of tones no alert plays any more. The alerts are
    // already scheduled, so a failed cleanup only leaves a spare channel.
    try {
      for (final channel
          in await android?.getNotificationChannels() ?? const []) {
        if (channel.id.startsWith(_phoneChannelPrefix) &&
            !phoneChannels.contains(channel.id)) {
          await android?.deleteNotificationChannel(channelId: channel.id);
        }
      }
    } catch (_) {}
  }

  /// The events for event reminders; none when the file can't be read, so
  /// the prayer alerts are still scheduled.
  static Future<HijriEvents?> _loadEvents() async {
    try {
      return parseHijriEvents(await rootBundle.loadString(hijriEventsAsset));
    } catch (_) {
      return null;
    }
  }

  static const _phoneChannelPrefix = 'bedug_prayer_v3_phone_';

  /// One channel per phone tone, named after its URI so it stays stable.
  @visibleForTesting
  static String phoneChannelId(PhoneSound sound) =>
      '$_phoneChannelPrefix${sound.uri.replaceAll(RegExp('[^A-Za-z0-9]+'), '_')}';

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
