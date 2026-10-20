import 'package:adhan/adhan.dart';

/// Additional times for the morning of the schedule's calendar date.
class ExtraPrayerTimes {
  // Kemenag's precautionary imsak reminder; fasting starts at Fajr.
  // https://kemenag.go.id/en/nasional/penjelasan-kemenag-waktu-imsak-10-menit-sebelum-subuh-3u18r0
  static const imsakLead = Duration(minutes: 10);

  // Approximation, not a solar-altitude calculation or an official timetable.
  // https://muhammadiyah.or.id/2020/08/tatacara-shalat-dhuha/
  static const dhuhaDelay = Duration(minutes: 20);

  final DateTime imsak;
  final DateTime dhuha;
  final DateTime lastThirdOfNight;

  ExtraPrayerTimes(PrayerTimes times)
    : imsak = times.fajr.subtract(imsakLead),
      dhuha = times.sunrise.add(dhuhaDelay),
      lastThirdOfNight = _lastThirdBeforeFajr(times);

  static DateTime _lastThirdBeforeFajr(PrayerTimes times) {
    final date = times.dateComponents;
    // Calendar arithmetic also handles month/year boundaries and leap days.
    final previousDate = DateTime.utc(date.year, date.month, date.day - 1);
    final previous = PrayerTimes(
      times.coordinates,
      DateComponents.from(previousDate),
      times.calculationParameters,
      utcOffset: times.utcOffset,
    );
    final night = times.fajr.difference(previous.maghrib);
    final start = times.fajr.subtract(
      Duration(microseconds: night.inMicroseconds ~/ 3),
    );
    // Round up so the displayed minute is within the final third.
    final minute = const Duration(minutes: 1).inMicroseconds;
    return DateTime.fromMicrosecondsSinceEpoch(
      ((start.microsecondsSinceEpoch + minute - 1) ~/ minute) * minute,
      isUtc: start.isUtc,
    );
  }
}
