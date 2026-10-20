import 'package:bedug/core/constants/city_catalog.dart';
import 'package:bedug/core/widgets/city_picker.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final id = lookupAppLocalizations(const Locale('id'));

  test('an empty query lists every city, grouped by country', () {
    final groups = filterCities(en, '  ');
    expect(groups.expand((g) => g.$2).length, supportedCities.length);
    expect(groups.map((g) => g.$1).toSet().length, groups.length);
  });

  test('matches city names regardless of case', () {
    final groups = filterCities(en, 'kuala');
    final names = groups.expand((g) => g.$2).map((c) => c.name);
    expect(names, containsAll(['Kuala Lumpur', 'Kuala Terengganu']));
    expect(groups.single.$1, CityCountry.malaysia);
  });

  test('matches the country name in the app language', () {
    expect(filterCities(id, 'jepang').single.$1, CityCountry.japan);
    expect(filterCities(en, 'jepang'), isEmpty);
  });
}
