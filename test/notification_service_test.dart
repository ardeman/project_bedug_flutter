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
        const NotificationPreferences(sound: PrayerNotificationSound.silent),
      );
      final scheduled = calls.where((call) => call.method == 'zonedSchedule');
      expect(scheduled, isNotEmpty);
      final details =
          (scheduled.first.arguments as Map)['platformSpecifics'] as Map;
      expect(details['channelId'], 'bedug_prayer_v2_silent');
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
    expect(details['channelId'], 'bedug_prayer_v2_system');
    expect(details['playSound'], isTrue);
    expect(details['scheduleMode'], 'exactAllowWhileIdle');
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
        const NotificationPreferences(sound: PrayerNotificationSound.silent),
      );
      final first = calls.firstWhere((call) => call.method == 'zonedSchedule');
      final details = (first.arguments as Map)['platformSpecifics'] as Map;
      expect(details['presentSound'], isFalse);
      expect(details['sound'], isNull);
    });
  }
}
