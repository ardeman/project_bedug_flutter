import 'package:bedug/core/constants/city_catalog.dart';
import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/services/kemenag_method.dart';
import 'package:bedug/core/services/notification_preferences.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('reads stored settings and locale on the first build', () async {
    final container = await _container({
      'calc_method': AppCalculationMethod.values.last.index,
      'madhab': true,
      'theme_mode': 2,
      'use_auto_location': false,
      'selected_city_id': 'jakarta',
      'app_locale': 'en',
    });

    final settings = container.read(settingsProvider);
    expect(settings.method, AppCalculationMethod.values.last);
    expect(settings.isHanafi, isTrue);
    expect(settings.themeMode, 2);
    expect(settings.useAutoLocation, isFalse);
    expect(settings.selectedCityId, 'jakarta');
    expect(container.read(localeProvider), const Locale('en'));
  });

  test('falls back to Kemenag for an unknown stored method index', () async {
    final container = await _container({'calc_method': 999});
    expect(
      container.read(settingsProvider).method,
      AppCalculationMethod.kemenag,
    );
  });

  test('clearing the selected city clears state and storage', () async {
    final container = await _container({'selected_city_id': 'jakarta'});
    final notifier = container.read(settingsProvider.notifier);

    await notifier.setSelectedCityId(null);

    expect(container.read(settingsProvider).selectedCityId, isNull);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString('selected_city_id'), isNull);
  });

  test('without a picked city, the manual city follows the language', () async {
    const expected = {
      'id': 'jakarta',
      'ms': 'kuala_lumpur',
      'ar': 'makkah',
      'en': 'silicon_valley',
    };
    for (final MapEntry(key: lang, value: cityId) in expected.entries) {
      final container = await _container({'app_locale': lang});
      expect(container.read(manualCityProvider).id, cityId, reason: lang);
    }
  });

  test('a picked city wins over the language default', () async {
    final container = await _container({
      'app_locale': 'en',
      'selected_city_id': 'medan',
    });
    expect(container.read(manualCityProvider).id, 'medan');

    await container.read(settingsProvider.notifier).setSelectedCityId(null);
    expect(container.read(manualCityProvider).id, 'silicon_valley');
  });

  test('notification preferences persist across provider recreation', () async {
    final container = await _container({});
    final notifier = container.read(settingsProvider.notifier);
    expect(
      container.read(settingsProvider).notifications.sound,
      PrayerNotificationSound.system,
    );
    await notifier.setNotifications(
      const NotificationPreferences(
        enabled: false,
        alerts: {PrayerAlert.imsak, PrayerAlert.dhuhr},
        reminderMinutes: 15,
        sound: PrayerNotificationSound.silent,
      ),
    );
    container.invalidate(settingsProvider);
    final preferences = container.read(settingsProvider).notifications;
    expect(preferences.enabled, isFalse);
    expect(preferences.alerts, {PrayerAlert.imsak, PrayerAlert.dhuhr});
    expect(preferences.reminderMinutes, 15);
    expect(preferences.sound, PrayerNotificationSound.silent);
    await notifier.setThemeMode(2);
    expect(container.read(settingsProvider).notifications.reminderMinutes, 15);
  });

  test(
    'unknown and legacy stored notification options fall back safely',
    () async {
      final container = await _container({
        'notification_reminder_minutes': -1,
        'notification_sound': 'removed_sound',
        'notifications_disabled': ['fajr', 'unknown'],
      });
      final preferences = container.read(settingsProvider).notifications;
      expect(preferences.reminderMinutes, 0);
      expect(preferences.sound, PrayerNotificationSound.system);
      expect(preferences.alerts, {
        PrayerAlert.dhuhr,
        PrayerAlert.asr,
        PrayerAlert.maghrib,
        PrayerAlert.isha,
      });
    },
  );

  test('city ids are unique', () {
    final ids = supportedCities.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
