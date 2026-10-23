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
  var existingChannels = <String>[];

  setUpAll(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    tz.initializeTimeZones();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'canScheduleExactNotifications') return allowExact;
          if (call.method == 'getNotificationChannels') {
            return [for (final id in existingChannels) _channelMap(id)];
          }
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
  setUp(() {
    calls.clear();
    existingChannels = [];
  });

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
    'a phone tone gets a channel per URI; unused ones are deleted',
    () async {
      const tone = PhoneSound(
        uri: 'content://media/internal/audio/media/42',
        title: 'Chime',
      );
      final toneChannel = NotificationService.phoneChannelId(tone);
      existingChannels = [
        toneChannel,
        'bedug_prayer_v3_phone_content_media_internal_audio_media_7',
        'bedug_prayer_v3_bedug',
      ];
      await NotificationService.schedulePrayerNotifications(
        times,
        l10n,
        const NotificationPreferences(
          sounds: {
            PrayerAlert.fajr: PrayerNotificationSound.phone,
            // No stored tone: plays the system sound.
            PrayerAlert.asr: PrayerNotificationSound.phone,
          },
          phoneSounds: {PrayerAlert.fajr: tone},
        ),
      );
      final channels = {
        for (final call in calls.where((c) => c.method == 'zonedSchedule'))
          (call.arguments as Map)['title']:
              (call.arguments as Map)['platformSpecifics'] as Map,
      };
      expect(
        toneChannel,
        'bedug_prayer_v3_phone_content_media_internal_audio_media_42',
      );
      expect(channels['Fajr']!['channelId'], toneChannel);
      expect(channels['Fajr']!['sound'], tone.uri);
      expect(channels['Fajr']!['channelName'], 'Prayer Times (Chime)');
      expect(channels['Asr']!['channelId'], 'bedug_prayer_v3_system');
      final deleted = calls
          .where((c) => c.method == 'deleteNotificationChannel')
          .map((c) => c.arguments);
      expect(
        deleted,
        contains('bedug_prayer_v3_phone_content_media_internal_audio_media_7'),
      );
      expect(deleted, isNot(contains(toneChannel)));
      expect(deleted, isNot(contains('bedug_prayer_v3_bedug')));
    },
  );

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
      calls.clear();
      await NotificationService.schedulePrayerNotifications(
        times,
        l10n,
        const NotificationPreferences(),
      );
      expect(calls.map((c) => c.method), contains('zonedSchedule'));
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

/// A channel as the Android plugin reports it.
Map<String, Object?> _channelMap(String id) => {
  'id': id,
  'name': id,
  'importance': Importance.high.value,
  'showBadge': true,
  'bypassDnd': false,
  'playSound': true,
  'enableLights': false,
  'enableVibration': true,
  'ledColor': 0,
};
