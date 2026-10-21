import 'dart:convert';
import 'dart:ui';

import 'package:adhan/adhan.dart';
import 'package:bedug/core/services/prayer_widget_service.dart';
import 'package:bedug/core/services/widget_appearance.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:bedug/core/providers/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final date = DateTime(2026, 10, 20);
  final times = PrayerTimes(
    Coordinates(-6.2088, 106.8456),
    DateComponents.from(date),
    CalculationMethod.singapore.getParameters(),
  );

  Map<String, Object> build({
    PrayerTimes? schedule,
    DateTime? now,
    String locale = 'en',
  }) => buildPrayerWidgetData(
    times: schedule,
    location: 'Jakarta',
    l10n: lookupAppLocalizations(Locale(locale)),
    now: now ?? date,
    themeMode: 2,
  );

  test(
    'sync clears stale location data and follows locale and theme changes',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = _RecordingWidgets();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          prayerProvider.overrideWith(_ControlledPrayer.new),
          prayerWidgetServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        prayerWidgetSyncProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      final notifier =
          container.read(prayerProvider.notifier) as _ControlledPrayer;
      notifier.replace(
        PrayerState(times: times, locationLabel: 'Jakarta', loading: false),
      );
      expect(service.updates.last['location'], 'Jakarta');
      expect(service.updates.last['prayers'], isNotEmpty);
      await container
          .read(localeProvider.notifier)
          .setLocale(const Locale('ar'));
      expect(service.updates.last['locale'], 'ar');
      await container.read(settingsProvider.notifier).setThemeMode(2);
      expect(service.updates.last['themeMode'], 2);
      await container
          .read(widgetAppearanceProvider.notifier)
          .setShowAnalog(false);
      expect(service.updates.last['showAnalog'], isFalse);
      expect(service.updates.last['showSchedule'], isTrue);
      await container
          .read(widgetAppearanceProvider.notifier)
          .setShowSchedule(false);
      expect(service.updates.last['showSchedule'], isFalse);
      notifier.replace(
        PrayerState(times: times, locationLabel: 'Jakarta', loading: true),
      );
      expect(service.updates.last['prayers'], isEmpty);
      expect(service.updates.last['location'], isEmpty);
      notifier.replace(
        PrayerState(times: times, loading: false, error: 'test'),
      );
      expect(service.updates.last['prayers'], isEmpty);
    },
  );

  test('seven independently calculated days, five prayers, no sunrise', () {
    final data = build(schedule: times);
    final prayers = data['prayers'] as List<Map<String, Object>>;
    expect(prayers, hasLength(35));
    expect(prayers.map((p) => p['name']).toSet(), {
      'Fajr',
      'Dhuhr',
      'Asr',
      'Maghrib',
      'Isha',
    });
    final tomorrow = PrayerTimes(
      times.coordinates,
      DateComponents(2026, 10, 21),
      times.calculationParameters,
    );
    // Native widgets pick the dial's sky symbol from the adhan key.
    expect(
      prayers.first['key'],
      isIn(['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']),
    );
    expect(prayers[5]['key'], 'fajr');
    expect(prayers[5]['time'], tomorrow.fajr.millisecondsSinceEpoch);
    expect(data['themeMode'], 2);
    expect(jsonEncode(data), isNot(contains('latitude')));
  });

  test('at a prayer boundary the next prayer is strictly in the future', () {
    final prayers =
        build(schedule: times, now: times.isha)['prayers']
            as List<Map<String, Object>>;
    expect(prayers.first['name'], 'Fajr');
    expect(
      prayers.every(
        (p) => (p['time'] as int) > times.isha.millisecondsSinceEpoch,
      ),
      isTrue,
    );
    expect(
      prayers.map((p) => p['time']).toList(),
      orderedEquals((prayers.map((p) => p['time'] as int).toList()..sort())),
    );
  });

  test(
    'countdown dial starts at the preceding prayer, including overnight',
    () {
      final yesterday = PrayerTimes(
        times.coordinates,
        DateComponents(2026, 10, 19),
        times.calculationParameters,
      );
      expect(
        build(schedule: times)['intervalStart'],
        yesterday.isha.millisecondsSinceEpoch,
      );
      expect(
        build(schedule: times, now: times.dhuhr)['intervalStart'],
        times.dhuhr.millisecondsSinceEpoch,
      );
    },
  );

  test(
    'wide schedule has five upcoming prayers across midnight in all locales',
    () {
      for (final locale in ['id', 'en', 'ar', 'ms']) {
        final data = build(schedule: times, now: times.maghrib, locale: locale);
        final upcoming = (data['prayers'] as List<Map<String, Object>>)
            .take(5)
            .toList();
        final l10n = lookupAppLocalizations(Locale(locale));
        expect(upcoming.map((prayer) => prayer['name']), [
          l10n.isha,
          l10n.fajr,
          l10n.dhuhr,
          l10n.asr,
          l10n.maghrib,
        ]);
        expect(
          upcoming.last['time'],
          greaterThan(times.isha.millisecondsSinceEpoch),
        );
      }
    },
  );

  test(
    'missing schedule clears times and all locales supply refresh guidance',
    () {
      for (final locale in ['id', 'en', 'ar', 'ms']) {
        final data = build(locale: locale);
        expect(data['prayers'], isEmpty);
        expect(data['refresh'], isNotEmpty);
        expect(data['locale'], locale);
      }
      expect(
        (build(schedule: times, locale: 'ar')['prayers'] as List).first['name'],
        lookupAppLocalizations(const Locale('ar')).fajr,
      );
    },
  );

  test(
    'native writes are serialized and recover after a plugin failure',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel('home_widget');
      final calls = <MethodCall>[];
      var fail = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'saveWidgetData' && fail) {
              fail = false;
              throw PlatformException(code: 'test');
            }
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final service = PrayerWidgetService();
      await Future.wait([
        service.update({'location': 'old'}),
        service.update({'location': 'new'}),
      ]);
      expect(calls.map((c) => c.method), [
        'setAppGroupId',
        'saveWidgetData',
        'setAppGroupId',
        'saveWidgetData',
        'updateWidget',
      ]);
      expect(calls[3].arguments['data'], jsonEncode({'location': 'new'}));
      expect(calls.last.arguments['ios'], 'BedugPrayerWidget');
    },
  );
}

class _ControlledPrayer extends PrayerNotifier {
  @override
  PrayerState build() => const PrayerState();

  void replace(PrayerState value) => state = value;
}

class _RecordingWidgets extends PrayerWidgetService {
  final updates = <Map<String, Object>>[];

  @override
  Future<void> update(Map<String, Object> data) async => updates.add(data);
}
