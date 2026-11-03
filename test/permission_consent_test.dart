import 'dart:async';

import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/providers/permission_provider.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:bedug/features/tour/app_tour_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.baseflow.com/geolocator');
  const notificationChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];
  var granted = false;
  var permanentlyDenied = false;

  setUp(() {
    calls.clear();
    granted = false;
    permanentlyDenied = false;
    SharedPreferences.setMockInitialValues({});
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return switch (call.method) {
        'isLocationServiceEnabled' => true,
        'checkPermission' =>
          permanentlyDenied
              ? 1
              : granted
              ? 3
              : 0,
        'requestPermission' => (granted = true) ? 3 : 1,
        'getCurrentPosition' => {
          'latitude': -6.2,
          'longitude': 106.8,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'accuracy': 10.0,
          'altitude': 0.0,
          'altitude_accuracy': 0.0,
          'heading': 0.0,
          'heading_accuracy': 0.0,
          'speed': 0.0,
          'speed_accuracy': 0.0,
        },
        _ => null,
      };
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Future<ProviderContainer> containerFor(
    Future<bool> Function(AppPermission) acknowledge,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        permissionAcknowledgementProvider.overrideWithValue(acknowledge),
        reverseGeocoderProvider.overrideWithValue((_, _) async => []),
        notificationSchedulerProvider.overrideWithValue((_, _, _, _) async {}),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'Not now for notifications is remembered without repeated prompts',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      var explanations = 0;
      final container = await containerFor((permission) async {
        expect(permission, AppPermission.notifications);
        explanations++;
        return false;
      });
      expect(container.read(settingsProvider).notifications.enabled, isTrue);
      await container.read(notificationConsentProvider.future);
      expect(container.read(settingsProvider).notifications.enabled, isFalse);
      container.invalidate(notificationConsentProvider);
      await container.read(notificationConsentProvider.future);
      expect(explanations, 1);
      expect(
        container
            .read(sharedPreferencesProvider)
            .getBool(notificationAcknowledgementKey),
        isFalse,
      );
    },
  );

  test(
    'accepted notification consent opens system settings when access stays off',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final notificationCalls = <String>[];
      messenger.setMockMethodCallHandler(notificationChannel, (call) async {
        notificationCalls.add(call.method);
        return switch (call.method) {
          'areNotificationsEnabled' => false,
          'requestNotificationsPermission' => false,
          _ => true,
        };
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(notificationChannel, null),
      );
      final container = await containerFor((permission) async {
        expect(permission, AppPermission.notifications);
        return true;
      });

      await container.read(notificationConsentProvider.future);

      expect(
        notificationCalls,
        containsAll([
          'requestNotificationsPermission',
          'areNotificationsEnabled',
          'openAppNotificationSettings',
        ]),
      );
    },
  );

  test(
    'location waits for acknowledgement before requesting system access',
    () async {
      final answer = Completer<bool>();
      final container = await containerFor((permission) {
        expect(permission, AppPermission.location);
        return answer.future;
      });
      container.listen(prayerProvider, (_, _) {});
      await pumpEventQueue();
      expect(calls, isNot(contains('requestPermission')));
      answer.complete(true);
      await pumpEventQueue();
      expect(calls.where((call) => call == 'requestPermission'), hasLength(1));
      expect(container.read(prayerProvider).times, isNotNull);
    },
  );

  test('Not now defers location; only an explicit retry asks again', () async {
    var explanations = 0;
    final container = await containerFor((_) async {
      explanations++;
      return false;
    });
    container.listen(prayerProvider, (_, _) {});
    await pumpEventQueue();
    await container.read(prayerProvider.notifier).load();
    expect(explanations, 1);
    expect(calls, isNot(contains('requestPermission')));
    expect(
      container
          .read(sharedPreferencesProvider)
          .getBool(locationAcknowledgementKey),
      isFalse,
    );
    await container.read(prayerProvider.notifier).load(requestPermission: true);
    expect(explanations, 2);
    expect(calls, isNot(contains('requestPermission')));
  });

  test('permanent denial never opens Settings automatically', () async {
    permanentlyDenied = true;
    final container = await containerFor((_) async => true);
    container.listen(prayerProvider, (_, _) {});
    await pumpEventQueue();
    expect(calls, isNot(contains('openAppSettings')));
    expect(calls, isNot(contains('requestPermission')));
    expect(container.read(prayerProvider).error, isNotNull);
  });

  test(
    'permission work waiting on the tour is released by skip and replay',
    () async {
      final container = await containerFor((_) async => false);
      final tour = container.read(appTourControllerProvider.notifier);
      var released = false;
      final pending = tour.finished.then((_) => released = true);
      await pumpEventQueue();
      expect(released, isFalse);
      await tour.finish();
      await pending;
      expect(released, isTrue);
      tour.start();
      expect(container.read(appTourControllerProvider), 0);
      await tour.finish();
    },
  );
}
