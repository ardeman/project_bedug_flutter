import 'package:adhan/adhan.dart';
import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:fake_async/fake_async.dart';
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

  test('a failed auto detect turns auto detect off and loads the city',
      () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // Location services off, so auto detect fails at its first check.
    messenger.setMockMethodCallHandler(_geolocatorChannel, (call) async {
      if (call.method == 'isLocationServiceEnabled') return false;
      return null;
    });
    addTearDown(
        () => messenger.setMockMethodCallHandler(_geolocatorChannel, null));

    SharedPreferences.setMockInitialValues({'selected_city_id': 'jakarta'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    container.listen(prayerProvider, (_, __) {});

    await pumpEventQueue();

    expect(container.read(settingsProvider).useAutoLocation, isFalse);
    expect(prefs.getBool('use_auto_location'), isFalse);
    final state = container.read(prayerProvider);
    expect(state.error, isNull);
    expect(state.times, isNotNull);
    expect(state.locationLabel, container.read(manualCityProvider).name);
  });

  test('the next prayer moves on once its time arrives', () {
    final times = PrayerTimes(
      Coordinates(-6.2088, 106.8456),
      DateComponents(2026, 10, 20),
      CalculationMethod.singapore.getParameters(),
    );
    final beforeDhuhr = times.dhuhr.subtract(const Duration(minutes: 1));
    FakeAsync(initialTime: beforeDhuhr).run((async) {
      final container = ProviderContainer(overrides: [
        prayerProvider.overrideWith(() => _FakePrayerNotifier(PrayerState(
              times: times,
              locationLabel: 'Jakarta',
              loading: false,
            ))),
      ]);
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
