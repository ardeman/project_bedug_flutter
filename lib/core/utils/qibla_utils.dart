import 'dart:math' as math;

import 'package:adhan/adhan.dart';

/// Mean Earth radius in kilometres, used for great-circle distances.
const double _earthRadiusKm = 6371.0;

/// Sun altitude (degrees) below which the sun is too low, or set, to use as a
/// direction reference.
const double minUsableSunAltitude = 5.0;

/// Bearing from true north to the Kaaba, clockwise, in degrees [0, 360).
double qiblaBearing(Coordinates from) => Qibla(from).direction % 360;

/// Great-circle distance from [from] to the Kaaba, in kilometres.
double distanceToKaabaKm(Coordinates from) {
  final kaaba = Qibla.MAKKAH;
  final lat1 = _rad(from.latitude);
  final lat2 = _rad(kaaba.latitude);
  final dLat = lat2 - lat1;
  final dLng = _rad(kaaba.longitude - from.longitude);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusKm * math.asin(math.min(1, math.sqrt(a)));
}

/// Index (0 = N, 1 = NE, ... 7 = NW) of the 8-point compass direction
/// nearest to [bearing].
int compassPointIndex(double bearing) =>
    ((_normalize360(bearing) + 22.5) ~/ 45) % 8;

/// Signed smallest angle from [from] to [to], in degrees (-180, 180].
/// Positive means [to] is clockwise (to the right) of [from].
double relativeAngle(double from, double to) {
  final diff = _normalize360(to - from);
  return diff > 180 ? diff - 360 : diff;
}

/// Position of the sun in the sky as seen from one place.
class SunPosition {
  /// Clockwise from true north, in degrees [0, 360).
  final double azimuth;

  /// Above the horizon, in degrees (negative below it).
  final double altitude;

  const SunPosition({required this.azimuth, required this.altitude});

  bool get isUsable => altitude >= minUsableSunAltitude;
}

/// Sun position at [time] for [at], from the low-precision solar formulas of
/// the Astronomical Almanac (accurate to about 1°, enough for a direction
/// hint).
SunPosition sunPosition(DateTime time, Coordinates at) {
  // Days since the J2000.0 epoch (2000-01-01 12:00 UTC).
  final julianDay = time.toUtc().millisecondsSinceEpoch / 86400000 + 2440587.5;
  final n = julianDay - 2451545.0;

  final meanLongitude = _normalize360(280.460 + 0.9856474 * n);
  final meanAnomaly = _rad(_normalize360(357.528 + 0.9856003 * n));
  final eclipticLongitude = _rad(meanLongitude +
      1.915 * math.sin(meanAnomaly) +
      0.020 * math.sin(2 * meanAnomaly));
  final obliquity = _rad(23.439 - 0.0000004 * n);

  final rightAscension = math.atan2(
    math.cos(obliquity) * math.sin(eclipticLongitude),
    math.cos(eclipticLongitude),
  );
  final declination =
      math.asin(math.sin(obliquity) * math.sin(eclipticLongitude));

  // Greenwich mean sidereal time in degrees, then the local hour angle.
  final siderealDeg = _normalize360(280.46061837 + 360.98564736629 * n);
  final hourAngle = _rad(siderealDeg + at.longitude) - rightAscension;

  final lat = _rad(at.latitude);
  final altitude = math.asin(math.sin(lat) * math.sin(declination) +
      math.cos(lat) * math.cos(declination) * math.cos(hourAngle));
  final azimuth = math.atan2(
    -math.sin(hourAngle),
    math.tan(declination) * math.cos(lat) - math.sin(lat) * math.cos(hourAngle),
  );

  return SunPosition(
    azimuth: _normalize360(_deg(azimuth)),
    altitude: _deg(altitude),
  );
}

double _normalize360(double deg) => ((deg % 360) + 360) % 360;
double _rad(double deg) => deg * math.pi / 180;
double _deg(double rad) => rad * 180 / math.pi;
