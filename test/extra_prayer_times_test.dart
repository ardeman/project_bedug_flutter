import 'package:adhan/adhan.dart';
import 'package:bedug/core/services/extra_prayer_times.dart';
import 'package:bedug/core/services/kemenag_method.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final date in [
    DateTime.utc(2027, 1, 1),
    DateTime.utc(2026, 3, 1),
    DateTime.utc(2028, 3, 1),
  ]) {
    for (final method in AppCalculationMethod.values) {
      test('extra times use the selected morning: $date, ${method.name}', () {
        final coordinates = Coordinates(-6.2088, 106.8456);
        final params = method.getParameters();
        final times = PrayerTimes.utcOffset(
          coordinates,
          DateComponents.from(date),
          params,
          const Duration(hours: 7),
        );
        final extra = ExtraPrayerTimes(times);
        expect(times.fajr.difference(extra.imsak), const Duration(minutes: 10));
        expect(
          extra.dhuha.difference(times.sunrise),
          const Duration(minutes: 20),
        );
        expect(extra.dhuha.isBefore(times.dhuhr), isTrue);

        final previous = PrayerTimes.utcOffset(
          coordinates,
          DateComponents.from(date.subtract(const Duration(days: 1))),
          params,
          const Duration(hours: 7),
        );
        final night = times.fajr.difference(previous.maghrib);
        final remaining = times.fajr.difference(extra.lastThirdOfNight);
        expect(remaining.inSeconds, closeTo(night.inSeconds / 3, 60));
        expect(
          remaining.inMicroseconds,
          lessThanOrEqualTo(night.inMicroseconds / 3),
        );
        expect(extra.lastThirdOfNight.isAfter(previous.isha), isTrue);
        expect(extra.lastThirdOfNight.isBefore(extra.imsak), isTrue);
        expect(extra.lastThirdOfNight.second, 0);
        expect(extra.lastThirdOfNight.day, date.day);
      });
    }
  }
}
