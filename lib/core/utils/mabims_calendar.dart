import 'lunar_astronomy.dart';

/// Where the MABIMS criteria are checked: Kemenag's hilal observatory at
/// Lhoknga, Aceh (Observatorium Tgk. Chiek Kuta Karang). The Kemenag calendar
/// starts a month when the crescent meets the criteria anywhere in
/// Indonesia, which is first in the far west, where the sun sets latest;
/// from here the elongation matches the highest Kemenag published for
/// 1 Ramadan 1446 (6°24′), a month decided by hundredths of a degree.
const _latitude = 5.4639, _longitude = 95.2419;

/// Western Indonesian Time (UTC+7), whose evenings the criteria are checked
/// on.
const _utcOffset = Duration(hours: 7);

/// The MABIMS criteria at sunset (2021): the moon at least 3° high and 6.4°
/// from the sun. Kemenag measures the altitude as seen, with refraction
/// (its 4°40′ highest for 1 Ramadan 1446 is 0.17° of refraction above the
/// airless value), and the elongation from the Earth's centre.
const _minAltitude = 3.0, _minElongation = 6.4;

/// Julian day of the new moon that begins Muharram 1421 (5 April 2000, the
/// third of Meeus's lunation numbers counted from 6 January 2000).
const _muharram1421NewMoon = 2451550.09766 + 3 * synodicMonth;

final _starts = <int, DateTime>{};

/// The first day of Hijri [month] of [year] under the MABIMS criteria, as
/// the Indonesian government (Kemenag) and Malaysia, Brunei and Singapore
/// calculate it: the day after the first evening, at or after the
/// conjunction, whose sunset sees the crescent meet the criteria at Lhoknga.
/// The date is in UTC, at midnight.
DateTime mabimsMonthStart(int year, int month) {
  final index = (year - 1) * 12 + month - 1;
  return _starts[index] ??= _monthStart(index);
}

DateTime _monthStart(int index) {
  const muharram1421 = 1420 * 12;
  final conjunction = conjunctionNear(
    _muharram1421NewMoon + (index - muharram1421) * synodicMonth,
  );
  final local = dateTimeOfJulianDay(conjunction).add(_utcOffset);
  var evening = DateTime.utc(local.year, local.month, local.day);
  while (!_meetsCriteria(evening, conjunction)) {
    evening = DateTime.utc(evening.year, evening.month, evening.day + 1);
  }
  return DateTime.utc(evening.year, evening.month, evening.day + 1);
}

/// Whether the crescent meets the criteria at sunset on the local date
/// [evening], after a [conjunction] (Julian day).
bool _meetsCriteria(DateTime evening, double conjunction) {
  // Sunset at Lhoknga is near 18:45 local time all year.
  final sunset = sunsetNear(
    julianDay(evening.add(const Duration(hours: 18, minutes: 45))) -
        _utcOffset.inMinutes / Duration.minutesPerDay,
    _latitude,
    _longitude,
  );
  if (sunset <= conjunction) return false;
  final sky = SunMoon.at(sunset);
  return sky.moonAltitude(_latitude, _longitude) >= _minAltitude &&
      sky.elongation >= _minElongation;
}
