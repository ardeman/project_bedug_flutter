import 'dart:ui';

import 'package:adhan/adhan.dart';
import 'package:bedug/core/services/notification_preferences.dart';
import 'package:bedug/core/services/notification_service.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_10y.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  var allowExact = false;
  var failNext = false;

  setUpAll(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    tz.initializeTimeZones();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'canScheduleExactNotifications') return allowExact;
          if (call.method == 'zonedSchedule' && failNext) {
            failNext = false;
            throw PlatformException(code: 'schedule_failed');
          }
          return true;
        });
  });
  tearDownAll(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  setUp(calls.clear);

  final times = PrayerTimes.today(
    Coordinates(-6.2088, 106.8456),
    CalculationMethod.singapore.getParameters(),
  );
  final l10n = lookupAppLocalizations(const Locale('en'));

  test(
    'silent sound uses a separate Android channel and inexact fallback',
    () async {
      await NotificationService.schedulePrayerNotifications(
        times,
        l10n,
        _allSounds(PrayerNotificationSound.silent),
      );
      final initialization = calls.firstWhere(
        (call) => call.method == 'initialize',
      );
      expect((initialization.arguments as Map)['defaultIcon'], 'ic_stat_bedug');
      final scheduled = calls.where((call) => call.method == 'zonedSchedule');
      expect(scheduled, isNotEmpty);
      final details =
          (scheduled.first.arguments as Map)['platformSpecifics'] as Map;
      expect(details['icon'], 'ic_stat_bedug');
      expect(details['channelId'], 'bedug_prayer_v3_silent');
      expect(details['playSound'], isFalse);
      expect(details['enableVibration'], isFalse);
      expect(details['scheduleMode'], 'inexactAllowWhileIdle');
    },
  );

  test('system sound and exact alarms are used when authorized', () async {
    allowExact = true;
    await NotificationService.schedulePrayerNotifications(
      times,
      l10n,
      const NotificationPreferences(),
    );
    final first = calls.firstWhere((call) => call.method == 'zonedSchedule');
    final details = (first.arguments as Map)['platformSpecifics'] as Map;
    expect(details['channelId'], 'bedug_prayer_v3_system');
    expect(details['playSound'], isTrue);
    expect(details['scheduleMode'], 'exactAllowWhileIdle');
  });

  test('each alert uses its own sound and channel', () async {
    await NotificationService.schedulePrayerNotifications(
      times,
      l10n,
      const NotificationPreferences(
        sounds: {
          PrayerAlert.fajr: PrayerNotificationSound.bedug,
          PrayerAlert.dhuhr: PrayerNotificationSound.siren,
        },
      ),
    );
    final channels = {
      for (final call in calls.where((c) => c.method == 'zonedSchedule'))
        (call.arguments as Map)['title']:
            (call.arguments as Map)['platformSpecifics'] as Map,
    };
    expect(channels['Fajr']!['channelId'], 'bedug_prayer_v3_bedug');
    expect(channels['Fajr']!['sound'], 'prayer_bedug');
    expect(channels['Fajr']!['channelName'], 'Prayer Times (Bedug)');
    expect(channels['Dhuhr']!['channelId'], 'bedug_prayer_v3_siren');
    expect(channels['Dhuhr']!['sound'], 'prayer_siren');
    expect(channels['Asr']!['channelId'], 'bedug_prayer_v3_system');
    expect(channels['Asr']!['sound'], isNull);
  });

  test(
    'rapid disable runs after scheduling, leaving no pending alerts',
    () async {
      final enabled = NotificationService.schedulePrayerNotifications(
        times,
        l10n,
        const NotificationPreferences(),
      );
      final disabled = NotificationService.schedulePrayerNotifications(
        null,
        l10n,
        const NotificationPreferences(enabled: false),
      );
      await Future.wait([enabled, disabled]);
      expect(calls.last.method, 'cancelAll');
    },
  );

  test(
    'a failed schedule surfaces the error and does not poison later requests',
    () async {
      failNext = true;
      await expectLater(
        NotificationService.schedulePrayerNotifications(
          times,
          l10n,
          const NotificationPreferences(),
        ),
        throwsA(isA<PlatformException>()),
      );
      await NotificationService.schedulePrayerNotifications(
        times,
        l10n,
        const NotificationPreferences(),
      );
      expect(calls.last.method, 'zonedSchedule');
    },
  );
  for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
    test('silent delivery does not request sound on $platform', () async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(
        () => debugDefaultTargetPlatformOverride = TargetPlatform.android,
      );
      if (platform == TargetPlatform.iOS) {
        IOSFlutterLocalNotificationsPlugin.registerWith();
      } else {
        MacOSFlutterLocalNotificationsPlugin.registerWith();
      }
      await NotificationService.schedulePrayerNotifications(
        times,
        l10n,
        _allSounds(PrayerNotificationSound.silent),
      );
      final first = calls.firstWhere((call) => call.method == 'zonedSchedule');
      final details = (first.arguments as Map)['platformSpecifics'] as Map;
      expect(details['presentSound'], isFalse);
      expect(details['sound'], isNull);
    });

    test('a bundled sound plays its .caf file on $platform', () async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(
        () => debugDefaultTargetPlatformOverride = TargetPlatform.android,
      );
      await NotificationService.schedulePrayerNotifications(
        times,
        l10n,
        _allSounds(PrayerNotificationSound.bedug),
      );
      final first = calls.firstWhere((call) => call.method == 'zonedSchedule');
      final details = (first.arguments as Map)['platformSpecifics'] as Map;
      expect(details['presentSound'], isTrue);
      expect(details['sound'], 'prayer_bedug.caf');
    });
  }
}

NotificationPreferences _allSounds(PrayerNotificationSound sound) =>
    NotificationPreferences(
      sounds: {for (final alert in PrayerAlert.values) alert: sound},
    );
