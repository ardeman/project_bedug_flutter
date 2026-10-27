import 'dart:math' as math;

/// Sun and moon positions for crescent visibility, after Jean Meeus,
/// *Astronomical Algorithms* (2nd ed.): the sun from chapter 25 (about
/// 0.01°) and the moon from chapter 47 (about 10″), which is far finer than
/// the whole-degree limits of the visibility criteria.
///
/// Times are Julian days in UT unless named `jde` (Terrestrial Time).

/// Mean length of a lunation in days (Meeus 49.1).
const double synodicMonth = 29.530588861;

/// The Julian day of [utc] (Meeus 7.1, Gregorian calendar).
double julianDay(DateTime utc) =>
    utc.millisecondsSinceEpoch / Duration.millisecondsPerDay + 2440587.5;

/// The UTC time of Julian day [jd].
DateTime dateTimeOfJulianDay(double jd) => DateTime.fromMillisecondsSinceEpoch(
  ((jd - 2440587.5) * Duration.millisecondsPerDay).round(),
  isUtc: true,
);

/// TT − UT in days near Julian day [jd], from Espenak and Meeus's polynomial
/// for 2005–2050. Outside those years it drifts by up to about a minute
/// within 1937–2077, which moves the moon by less than 0.01°.
double _deltaTDays(double jd) {
  final t = (jd - 2451544.5) / 365.25;
  return (62.92 + 0.32217 * t + 0.005589 * t * t) / Duration.secondsPerDay;
}

/// Where the sun and moon are at one moment, seen from the Earth's centre.
class SunMoon {
  /// Apparent ecliptic longitudes and the moon's latitude, in degrees.
  final double sunLongitude, moonLongitude, moonLatitude;

  /// Apparent right ascensions and declinations, in degrees.
  final double sunRa, sunDec, moonRa, moonDec;

  /// The moon's equatorial horizontal parallax, in degrees.
  final double moonParallax;

  /// Apparent sidereal time at Greenwich, in degrees.
  final double siderealTime;

  const SunMoon._({
    required this.sunLongitude,
    required this.moonLongitude,
    required this.moonLatitude,
    required this.sunRa,
    required this.sunDec,
    required this.moonRa,
    required this.moonDec,
    required this.moonParallax,
    required this.siderealTime,
  });

  /// The positions at Julian day [jd] (UT).
  factory SunMoon.at(double jd) {
    final t = (jd + _deltaTDays(jd) - 2451545) / 36525;

    // Nutation and obliquity, to the precision of Meeus chapter 22's short
    // series (0.5″ and 0.1″).
    final omega = _rad(125.04452 - 1934.136261 * t);
    final sunMean = _rad(280.4665 + 36000.7698 * t);
    final moonMean = _rad(218.3165 + 481267.8813 * t);
    final nutationLongitude =
        (-17.20 * math.sin(omega) -
            1.32 * math.sin(2 * sunMean) -
            0.23 * math.sin(2 * moonMean) +
            0.21 * math.sin(2 * omega)) /
        3600;
    final nutationObliquity =
        (9.20 * math.cos(omega) +
            0.57 * math.cos(2 * sunMean) +
            0.10 * math.cos(2 * moonMean) -
            0.09 * math.cos(2 * omega)) /
        3600;
    final obliquity =
        23.439291111 -
        (46.8150 * t + 0.00059 * t * t - 0.001813 * t * t * t) / 3600 +
        nutationObliquity;

    final sun = _sunLongitude(t) + nutationLongitude;
    final moon = _moon(t);
    final moonLongitude = moon.longitude + nutationLongitude;

    final sunEq = _equatorial(sun, 0, obliquity);
    final moonEq = _equatorial(moonLongitude, moon.latitude, obliquity);

    // Meeus 12.4, with the equation of the equinoxes.
    final d = jd - 2451545;
    final tu = d / 36525;
    final siderealTime = _normalize(
      280.46061837 +
          360.98564736629 * d +
          0.000387933 * tu * tu -
          tu * tu * tu / 38710000 +
          nutationLongitude * math.cos(_rad(obliquity)),
    );

    return SunMoon._(
      sunLongitude: _normalize(sun),
      moonLongitude: _normalize(moonLongitude),
      moonLatitude: moon.latitude,
      sunRa: sunEq.ra,
      sunDec: sunEq.dec,
      moonRa: moonEq.ra,
      moonDec: moonEq.dec,
      moonParallax: _deg(math.asin(6378.14 / moon.distance)),
      siderealTime: siderealTime,
    );
  }

  /// The moon's longitude ahead of the sun's, in degrees (−180, 180]:
  /// zero at conjunction (the astronomical new moon).
  double get phaseAngle {
    final diff = _normalize(moonLongitude - sunLongitude);
    return diff > 180 ? diff - 360 : diff;
  }

  /// The angle between the centres of the sun and moon, in degrees.
  double get elongation => _deg(
    math.acos(
      math.cos(_rad(moonLatitude)) *
          math.cos(_rad(moonLongitude - sunLongitude)),
    ),
  );

  /// The sun's geometric altitude at [latitude], [longitude] (east positive),
  /// in degrees.
  double sunAltitude(double latitude, double longitude) =>
      _altitude(latitude, siderealTime + longitude - sunRa, sunDec);

  /// The moon centre's apparent altitude at [latitude], [longitude], in
  /// degrees: the geocentric altitude less the parallax in altitude, raised
  /// by refraction (Saemundsson's formula, Meeus 16.4, for 10 °C and
  /// 1010 hPa).
  double moonAltitude(double latitude, double longitude) {
    final geocentric = _altitude(
      latitude,
      siderealTime + longitude - moonRa,
      moonDec,
    );
    final topocentric = geocentric - moonParallax * math.cos(_rad(geocentric));
    final refraction =
        1.02 / math.tan(_rad(topocentric + 10.3 / (topocentric + 5.11))) / 60;
    return topocentric + refraction;
  }
}

/// The Julian day (UT) of the conjunction nearest [jd], found by stepping
/// the moon's lead over the sun to zero; accurate to well under a minute.
double conjunctionNear(double jd) {
  var t = jd;
  for (var i = 0; i < 8; i++) {
    // The moon gains about 12.19° a day on the sun.
    final step = -SunMoon.at(t).phaseAngle / (360 / synodicMonth);
    t += step;
    if (step.abs() < 1e-6) break;
  }
  return t;
}

/// The Julian day (UT) of sunset at [latitude], [longitude] (east positive)
/// nearest [jd]: when the sun's centre is 0.833° below the horizon, for
/// refraction and its semidiameter (Meeus chapter 15).
double sunsetNear(double jd, double latitude, double longitude) {
  const standardAltitude = -0.833;
  var t = jd;
  for (var i = 0; i < 5; i++) {
    final p = SunMoon.at(t);
    final phi = _rad(latitude), dec = _rad(p.sunDec);
    final cosH0 =
        (math.sin(_rad(standardAltitude)) - math.sin(phi) * math.sin(dec)) /
        (math.cos(phi) * math.cos(dec));
    final setting = _deg(math.acos(cosH0.clamp(-1.0, 1.0)));
    final hourAngle = _normalize(p.siderealTime + longitude - p.sunRa);
    var diff = setting - hourAngle;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    // The hour angle grows 360.9856° a day.
    t += diff / 360.98564736629;
  }
  return t;
}

/// The sun's apparent longitude less nutation, in degrees, T centuries
/// from J2000 (Meeus chapter 25).
double _sunLongitude(double t) {
  final l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
  final m = _rad(357.52911 + 35999.05029 * t - 0.0001537 * t * t);
  final c =
      (1.914602 - 0.004817 * t - 0.000014 * t * t) * math.sin(m) +
      (0.019993 - 0.000101 * t) * math.sin(2 * m) +
      0.000289 * math.sin(3 * m);
  // Aberration.
  return l0 + c - 0.00569;
}

/// The moon's geometric longitude and latitude (degrees) and distance (km),
/// T centuries from J2000 (Meeus chapter 47).
({double longitude, double latitude, double distance}) _moon(double t) {
  final t2 = t * t, t3 = t2 * t, t4 = t3 * t;
  final lp =
      218.3164477 +
      481267.88123421 * t -
      0.0015786 * t2 +
      t3 / 538841 -
      t4 / 65194000;
  final d =
      297.8501921 +
      445267.1114034 * t -
      0.0018819 * t2 +
      t3 / 545868 -
      t4 / 113065000;
  final m = 357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24490000;
  final mp =
      134.9633964 +
      477198.8675055 * t +
      0.0087414 * t2 +
      t3 / 69699 -
      t4 / 14712000;
  final f =
      93.2720950 +
      483202.0175233 * t -
      0.0036539 * t2 -
      t3 / 3526000 +
      t4 / 863310000;
  final a1 = 119.75 + 131.849 * t;
  final a2 = 53.09 + 479264.290 * t;
  final a3 = 313.45 + 481266.484 * t;
  // The eccentricity of the Earth's orbit scales the terms with M.
  final e = 1 - 0.002516 * t - 0.0000074 * t2;

  double eccentricity(int mCount) => switch (mCount.abs()) {
    1 => e,
    2 => e * e,
    _ => 1,
  };

  var sl = 0.0, sr = 0.0, sb = 0.0;
  for (final term in _longitudeDistanceTerms) {
    final arg = _rad(term[0] * d + term[1] * m + term[2] * mp + term[3] * f);
    final scale = eccentricity(term[1]);
    sl += term[4] * scale * math.sin(arg);
    sr += term[5] * scale * math.cos(arg);
  }
  for (final term in _latitudeTerms) {
    final arg = _rad(term[0] * d + term[1] * m + term[2] * mp + term[3] * f);
    sb += term[4] * eccentricity(term[1]) * math.sin(arg);
  }
  sl +=
      3958 * math.sin(_rad(a1)) +
      1962 * math.sin(_rad(lp - f)) +
      318 * math.sin(_rad(a2));
  sb +=
      -2235 * math.sin(_rad(lp)) +
      382 * math.sin(_rad(a3)) +
      175 * math.sin(_rad(a1 - f)) +
      175 * math.sin(_rad(a1 + f)) +
      127 * math.sin(_rad(lp - mp)) -
      115 * math.sin(_rad(lp + mp));

  return (
    longitude: lp + sl / 1e6,
    latitude: sb / 1e6,
    distance: 385000.56 + sr / 1000,
  );
}

({double ra, double dec}) _equatorial(
  double longitude,
  double latitude,
  double obliquity,
) {
  final l = _rad(longitude), b = _rad(latitude), e = _rad(obliquity);
  final ra = math.atan2(
    math.sin(l) * math.cos(e) - math.tan(b) * math.sin(e),
    math.cos(l),
  );
  final dec = math.asin(
    math.sin(b) * math.cos(e) + math.cos(b) * math.sin(e) * math.sin(l),
  );
  return (ra: _normalize(_deg(ra)), dec: _deg(dec));
}

double _altitude(double latitude, double hourAngle, double declination) {
  final phi = _rad(latitude), dec = _rad(declination);
  return _deg(
    math.asin(
      math.sin(phi) * math.sin(dec) +
          math.cos(phi) * math.cos(dec) * math.cos(_rad(hourAngle)),
    ),
  );
}

double _normalize(double deg) => ((deg % 360) + 360) % 360;
double _rad(double deg) => deg * math.pi / 180;
double _deg(double rad) => rad * 180 / math.pi;

/// Meeus table 47.A: multiples of D, M, M′ and F, then the longitude
/// (10⁻⁶ degree) and distance (10⁻³ km) coefficients.
const _longitudeDistanceTerms = [
  [0, 0, 1, 0, 6288774, -20905355],
  [2, 0, -1, 0, 1274027, -3699111],
  [2, 0, 0, 0, 658314, -2955968],
  [0, 0, 2, 0, 213618, -569925],
  [0, 1, 0, 0, -185116, 48888],
  [0, 0, 0, 2, -114332, -3149],
  [2, 0, -2, 0, 58793, 246158],
  [2, -1, -1, 0, 57066, -152138],
  [2, 0, 1, 0, 53322, -170733],
  [2, -1, 0, 0, 45758, -204586],
  [0, 1, -1, 0, -40923, -129620],
  [1, 0, 0, 0, -34720, 108743],
  [0, 1, 1, 0, -30383, 104755],
  [2, 0, 0, -2, 15327, 10321],
  [0, 0, 1, 2, -12528, 0],
  [0, 0, 1, -2, 10980, 79661],
  [4, 0, -1, 0, 10675, -34782],
  [0, 0, 3, 0, 10034, -23210],
  [4, 0, -2, 0, 8548, -21636],
  [2, 1, -1, 0, -7888, 24208],
  [2, 1, 0, 0, -6766, 30824],
  [1, 0, -1, 0, -5163, -8379],
  [1, 1, 0, 0, 4987, -16675],
  [2, -1, 1, 0, 4036, -12831],
  [2, 0, 2, 0, 3994, -10445],
  [4, 0, 0, 0, 3861, -11650],
  [2, 0, -3, 0, 3665, 14403],
  [0, 1, -2, 0, -2689, -7003],
  [2, 0, -1, 2, -2602, 0],
  [2, -1, -2, 0, 2390, 10056],
  [1, 0, 1, 0, -2348, 6322],
  [2, -2, 0, 0, 2236, -9884],
  [0, 1, 2, 0, -2120, 5751],
  [0, 2, 0, 0, -2069, 0],
  [2, -2, -1, 0, 2048, -4950],
  [2, 0, 1, -2, -1773, 4130],
  [2, 0, 0, 2, -1595, 0],
  [4, -1, -1, 0, 1215, -3958],
  [0, 0, 2, 2, -1110, 0],
  [3, 0, -1, 0, -892, 3258],
  [2, 1, 1, 0, -810, 2616],
  [4, -1, -2, 0, 759, -1897],
  [0, 2, -1, 0, -713, -2117],
  [2, 2, -1, 0, -700, 2354],
  [2, 1, -2, 0, 691, 0],
  [2, -1, 0, -2, 596, 0],
  [4, 0, 1, 0, 549, -1423],
  [0, 0, 4, 0, 537, -1117],
  [4, -1, 0, 0, 520, -1571],
  [1, 0, -2, 0, -487, -1739],
  [2, 1, 0, -2, -399, 0],
  [0, 0, 2, -2, -381, -4421],
  [1, 1, 1, 0, 351, 0],
  [3, 0, -2, 0, -340, 0],
  [4, 0, -3, 0, 330, 0],
  [2, -1, 2, 0, 327, 0],
  [0, 2, 1, 0, -323, 1165],
  [1, 1, -1, 0, 299, 0],
  [2, 0, 3, 0, 294, 0],
  [2, 0, -1, -2, 0, 8752],
];

/// Meeus table 47.B: multiples of D, M, M′ and F, then the latitude
/// coefficient (10⁻⁶ degree).
const _latitudeTerms = [
  [0, 0, 0, 1, 5128122],
  [0, 0, 1, 1, 280602],
  [0, 0, 1, -1, 277693],
  [2, 0, 0, -1, 173237],
  [2, 0, -1, 1, 55413],
  [2, 0, -1, -1, 46271],
  [2, 0, 0, 1, 32573],
  [0, 0, 2, 1, 17198],
  [2, 0, 1, -1, 9266],
  [0, 0, 2, -1, 8822],
  [2, -1, 0, -1, 8216],
  [2, 0, -2, -1, 4324],
  [2, 0, 1, 1, 4200],
  [2, 1, 0, -1, -3359],
  [2, -1, -1, 1, 2463],
  [2, -1, 0, 1, 2211],
  [2, -1, -1, -1, 2065],
  [0, 1, -1, -1, -1870],
  [4, 0, -1, -1, 1828],
  [0, 1, 0, 1, -1794],
  [0, 0, 0, 3, -1749],
  [0, 1, -1, 1, -1565],
  [1, 0, 0, 1, -1491],
  [0, 1, 1, 1, -1475],
  [0, 1, 1, -1, -1410],
  [0, 1, 0, -1, -1344],
  [1, 0, 0, -1, -1335],
  [0, 0, 3, 1, 1107],
  [4, 0, 0, -1, 1021],
  [4, 0, -1, 1, 833],
  [0, 0, 1, -3, 777],
  [4, 0, -2, 1, 671],
  [2, 0, 0, -3, 607],
  [2, 0, 2, -1, 596],
  [2, -1, 1, -1, 491],
  [2, 0, -2, 1, -451],
  [0, 0, 3, -1, 439],
  [2, 0, 2, 1, 422],
  [2, 0, -3, -1, 421],
  [2, 1, -1, 1, -366],
  [2, 1, 0, 1, -351],
  [4, 0, 0, 1, 331],
  [2, -1, 1, 1, 315],
  [2, -2, 0, -1, 302],
  [0, 0, 1, 3, -283],
  [2, 1, 1, -1, -229],
  [1, 1, 0, -1, 223],
  [1, 1, 0, 1, 223],
  [0, 1, -2, -1, -220],
  [2, 1, -1, -1, -220],
  [1, 0, 1, 1, -185],
  [2, -1, -2, -1, 181],
  [0, 1, 2, 1, -177],
  [4, 0, -2, -1, 176],
  [4, -1, -1, -1, 166],
  [1, 0, 1, -1, -164],
  [4, 0, 1, -1, 132],
  [1, 0, -1, -1, -119],
  [4, -1, 0, -1, 115],
  [2, -2, 0, 1, 107],
];
