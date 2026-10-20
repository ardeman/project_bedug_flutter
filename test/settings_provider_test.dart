import 'package:bedug/core/constants/city_catalog.dart';
import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/services/kemenag_method.dart';
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
        container.read(settingsProvider).method, AppCalculationMethod.kemenag);
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
    final container =
        await _container({'app_locale': 'en', 'selected_city_id': 'medan'});
    expect(container.read(manualCityProvider).id, 'medan');

    await container.read(settingsProvider.notifier).setSelectedCityId(null);
    expect(container.read(manualCityProvider).id, 'silicon_valley');
  });

  test('city ids are unique', () {
    final ids = supportedCities.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
