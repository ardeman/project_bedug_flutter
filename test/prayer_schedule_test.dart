import 'package:adhan/adhan.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final jakarta = Coordinates(-6.2088, 106.8456);
  final params = CalculationMethod.singapore.getParameters();
  final reference = PrayerTimes(jakarta, DateComponents(2026, 10, 20), params);

  test('calculates the given calendar day at the same place and method', () {
    final day = prayerTimesOn(reference, DateTime(2027, 1, 1, 23, 59));
    final d = day.dateComponents;

    expect([d.year, d.month, d.day], [2027, 1, 1]);
    expect(day.coordinates, same(jakarta));
    expect(day.calculationParameters, same(params));
    expect(day.fajr.isBefore(day.isha), isTrue);
  });

  test('reaches past dates', () {
    final day = prayerTimesOn(reference, DateTime(1990, 3, 15));
    expect(day.dateComponents.year, 1990);
  });
}
