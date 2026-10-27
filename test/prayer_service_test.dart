import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:bedug/core/services/notification_preferences.dart';
import 'package:bedug/features/dzikir/dzikir.dart';
import 'package:fake_async/fake_async.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The method channel geolocator falls back to when no platform
/// implementation registers, as in tests.
const _geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');

class _FakePrayerNotifier extends PrayerNotifier {
  _FakePrayerNotifier(this._state);

  final PrayerState _state;

  @override
  PrayerState build() => _state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final outcome in [
    'resolved',
    'failed',
    'superseded',
    'disposed',
    'timeout',
  ]) {
    test(
      'GPS schedule does not wait for reverse geocoding: $outcome',
      () async {
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(_geolocatorChannel, (call) async {
          return switch (call.method) {
            'isLocationServiceEnabled' => true,
            'checkPermission' => 3,
            'getCurrentPosition' => {
              'latitude': -6.2088,
              'longitude': 106.8456,
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
        addTearDown(
          () => messenger.setMockMethodCallHandler(_geolocatorChannel, null),
        );
        SharedPreferences.setMockInitialValues({'use_auto_location': true});
        final prefs = await SharedPreferences.getInstance();
        final lookup = Completer<List<Placemark>>();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            reverseGeocoderProvider.overrideWithValue((_, _) => lookup.future),
            notificationSchedulerProvider.overrideWithValue(
              (_, _, _, _) async {},
            ),
          ],
        );
        if (outcome != 'disposed') addTearDown(container.dispose);
        container.listen(prayerProvider, (_, _) {});
        await pumpEventQueue();
        final initial = container.read(prayerProvider);
        expect(initial.loading, isFalse);
        expect(initial.error, isNull);
        expect(initial.times, isNotNull);
        expect(initial.locationLabel, 'Jakarta');
        expect(lookup.isCompleted, isFalse);
        if (outcome == 'superseded') {
          await container
              .read(settingsProvider.notifier)
              .setUseAutoLocation(false);
          await pumpEventQueue();
        }
        if (outcome == 'disposed') container.dispose();
        if (outcome == 'timeout') {
          await Future<void>.delayed(const Duration(milliseconds: 3100));
          expect(container.read(prayerProvider).locationLabel, 'Jakarta');
        }
        if (outcome == 'failed') {
          lookup.completeError(PlatformException(code: 'offline'));
        } else {
          lookup.complete([Placemark(locality: 'Resolved address')]);
        }
        await pumpEventQueue();
        if (outcome != 'disposed') {
          final result = container.read(prayerProvider);
          expect(result.loading, isFalse);
          expect(result.error, isNull);
          expect(
            result.locationLabel,
            outcome == 'resolved'
                ? 'Resolved address'
                : outcome == 'superseded'
                ? container.read(manualCityProvider).name
                : 'Jakarta',
          );
          if (outcome != 'superseded') {
            expect(result.times, same(initial.times));
          }
        }
      },
    );
  }

  for (final servicesEnabled in [false, true]) {
    test(
      'failed auto detect preserves preference and can retry, services: $servicesEnabled',
      () async {
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        var attempts = 0;
        messenger.setMockMethodCallHandler(_geolocatorChannel, (call) async {
          if (call.method == 'isLocationServiceEnabled') {
            attempts++;
            return servicesEnabled;
          }
          if (call.method == 'checkPermission') return 3;
          if (call.method == 'getCurrentPosition') {
            throw PlatformException(code: 'LOCATION_UPDATE_FAILURE');
          }
          return null;
        });
        addTearDown(
          () => messenger.setMockMethodCallHandler(_geolocatorChannel, null),
        );

        SharedPreferences.setMockInitialValues({
          'use_auto_location': true,
          'selected_city_id': 'jakarta',
        });
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);
        container.listen(prayerProvider, (_, _) {});

        await pumpEventQueue();

        expect(container.read(settingsProvider).useAutoLocation, isTrue);
        expect(prefs.getBool('use_auto_location'), isTrue);
        final state = container.read(prayerProvider);
        expect(state.loading, isFalse);
        expect(state.error, isNotEmpty);
        expect(state.showLocationGuide, isTrue);
        expect(state.times, isNull);
        expect(state.locationLabel, isNull);
        expect(attempts, 1);

        await container.read(prayerProvider.notifier).load();
        expect(attempts, 2);
        expect(container.read(settingsProvider).useAutoLocation, isTrue);
        expect(prefs.getBool('use_auto_location'), isTrue);
        expect(container.read(prayerProvider).loading, isFalse);
        expect(container.read(prayerProvider).error, isNotEmpty);

        // Manual-city fallback happens only when the user chooses it.
        await container
            .read(settingsProvider.notifier)
            .setUseAutoLocation(false);
        await pumpEventQueue();
        final manualState = container.read(prayerProvider);
        expect(manualState.error, isNull);
        expect(manualState.times, isNotNull);
        expect(
          manualState.locationLabel,
          container.read(manualCityProvider).name,
        );
      },
    );
  }

  test(
    'notification changes reschedule without reloading prayer times',
    () async {
      SharedPreferences.setMockInitialValues({'use_auto_location': false});
      final prefs = await SharedPreferences.getInstance();
      final scheduled = <NotificationPreferences>[];
      var fail = false;
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationSchedulerProvider.overrideWithValue((
            times,
            l10n,
            preferences,
            _,
          ) async {
            scheduled.add(preferences);
            if (fail) throw Exception();
          }),
        ],
      );
      addTearDown(container.dispose);
      container.listen(prayerProvider, (_, _) {});
      await pumpEventQueue();
      final times = container.read(prayerProvider).times;
      expect(times, isNotNull);
      expect(scheduled, hasLength(1));
      await container
          .read(settingsProvider.notifier)
          .setNotifications(
            const NotificationPreferences(reminders: {PrayerAlert.fajr: 10}),
          );
      await pumpEventQueue();
      expect(scheduled.last.reminderOf(PrayerAlert.fajr), 10);
      expect(container.read(prayerProvider).times, same(times));
      expect(container.read(prayerProvider).loading, isFalse);
      fail = true;
      await container
          .read(settingsProvider.notifier)
          .setNotifications(const NotificationPreferences(enabled: false));
      await pumpEventQueue();
      expect(container.read(prayerProvider).notificationError, isTrue);
      fail = false;
      await container.read(prayerProvider.notifier).refreshNotifications();
      expect(container.read(prayerProvider).notificationError, isFalse);
    },
  );

  test('a collection without sessions gets no dzikir reminders until another is picked', () async {
    SharedPreferences.setMockInitialValues({
      'use_auto_location': false,
      'dzikir_collection': 'rateb_siribee',
      'notification_dzikir': ['morning', 'evening'],
    });
    final prefs = await SharedPreferences.getInstance();
    final scheduled = <NotificationPreferences>[];
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationSchedulerProvider.overrideWithValue((
          _,
          _,
          preferences,
          _,
        ) async {
          scheduled.add(preferences);
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(prayerProvider, (_, _) {});
    await container.read(dzikirCollectionsProvider.future);
    await pumpEventQueue();
    expect(scheduled.last.dzikirReminders, isEmpty);
    // The switches stay saved for collections with sessions.
    expect(
      container.read(settingsProvider).notifications.dzikirReminders,
      hasLength(2),
    );
    await container
        .read(dzikirCollectionIdProvider.notifier)
        .select('hisnul_muslim');
    await pumpEventQueue();
    expect(scheduled.last.dzikirReminders, {
      DzikirReminder.morning,
      DzikirReminder.evening,
    });
  });

  test('after Isha uses tomorrow’s calculation and advances past Fajr', () {
    final times = PrayerTimes(
      Coordinates(-6.2088, 106.8456),
      DateComponents(2026, 10, 20),
      CalculationMethod.singapore.getParameters(),
    );
    final tomorrow = prayerTimesOn(times, DateTime(2026, 10, 21));
    expect(tomorrow.fajr, isNot(times.fajr.add(const Duration(days: 1))));
    final now = times.isha.add(const Duration(minutes: 1));
    FakeAsync(initialTime: now).run((async) {
      final container = ProviderContainer(
        overrides: [
          prayerProvider.overrideWith(
            () =>
                _FakePrayerNotifier(PrayerState(times: times, loading: false)),
          ),
        ],
      );
      container.listen(nextPrayerProvider, (_, _) {});
      expect(container.read(nextPrayerProvider), (
        key: 'fajr',
        time: tomorrow.fajr,
      ));
      // Even if the reference schedule has not refreshed after midnight,
      // the next boundary must use the new day's actual schedule.
      async.elapse(tomorrow.fajr.difference(now));
      expect(container.read(nextPrayerProvider), (
        key: 'dhuhr',
        time: tomorrow.dhuhr,
      ));
      container.dispose();
    });
  });

  test('the next prayer moves on once its time arrives', () {
    final times = PrayerTimes(
      Coordinates(-6.2088, 106.8456),
      DateComponents(2026, 10, 20),
      CalculationMethod.singapore.getParameters(),
    );
    final beforeDhuhr = times.dhuhr.subtract(const Duration(minutes: 1));
    FakeAsync(initialTime: beforeDhuhr).run((async) {
      final container = ProviderContainer(
        overrides: [
          prayerProvider.overrideWith(
            () => _FakePrayerNotifier(
              PrayerState(
                times: times,
                locationLabel: 'Jakarta',
                loading: false,
              ),
            ),
          ),
        ],
      );
      final seen = <String>[];
      container.listen(nextPrayerProvider, (_, next) => seen.add(next.key));
      expect(container.read(nextPrayerProvider).key, 'dhuhr');

      async.elapse(const Duration(minutes: 1, seconds: 1));
      expect(container.read(nextPrayerProvider).key, 'asr');
      expect(seen, ['asr']);
      container.dispose();
    });
  });
}
