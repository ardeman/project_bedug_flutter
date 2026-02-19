import 'dart:io';

import 'package:adhan/adhan.dart';

void main() {
  final coords = Coordinates(-6.2, 106.8);
  final params = CalculationMethod.muslim_world_league.getParameters();
  final t = PrayerTimes.today(coords, params);
  final list = {
    'fajr': t.fajr,
    'sunrise': t.sunrise,
    'dhuhr': t.dhuhr,
    'asr': t.asr,
    'maghrib': t.maghrib,
    'isha': t.isha,
  };
  for (final e in list.entries) {
    stdout.writeln(
      '${e.key}: raw=${e.value.toIso8601String()} isUtc=${e.value.isUtc} local=${e.value.toLocal().toIso8601String()}',
    );
  }
}
