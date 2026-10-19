import 'package:adhan/adhan.dart';
import 'package:bedug/core/utils/qibla_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final jakarta = Coordinates(-6.2088, 106.8456);

  group('qiblaBearing', () {
    test('points northwest from Jakarta', () {
      expect(qiblaBearing(jakarta), closeTo(295.1, 0.5));
      expect(compassPointIndex(qiblaBearing(jakarta)), 7); // NW
    });

    test('points northeast from New York', () {
      expect(qiblaBearing(Coordinates(40.7128, -74.0060)), closeTo(58.5, 0.5));
    });
  });

  test('distanceToKaabaKm from Jakarta is about 7,900 km', () {
    expect(distanceToKaabaKm(jakarta), closeTo(7920, 30));
  });

  test('compassPointIndex wraps around north', () {
    expect(compassPointIndex(0), 0);
    expect(compassPointIndex(350), 0);
    expect(compassPointIndex(-10), 0);
    expect(compassPointIndex(44), 1);
    expect(compassPointIndex(316), 7);
  });

  test('relativeAngle is signed and takes the short way round', () {
    expect(relativeAngle(10, 350), -20);
    expect(relativeAngle(350, 10), 20);
    expect(relativeAngle(90, 270), 180);
  });

  group('sunPosition', () {
    test('is overhead the Kaaba at rashdul qibla (28 May, 09:18 UTC)', () {
      final sun = sunPosition(DateTime.utc(2026, 5, 28, 9, 18), Qibla.MAKKAH);
      expect(sun.altitude, greaterThan(89));
    });

    test('is in the east in the Jakarta morning and set at night', () {
      // 08:00 WIB (UTC+7)
      final morning = sunPosition(DateTime.utc(2026, 3, 20, 1), jakarta);
      expect(morning.azimuth, closeTo(90, 5));
      expect(morning.isUsable, isTrue);

      // 22:00 WIB
      final night = sunPosition(DateTime.utc(2026, 3, 20, 15), jakarta);
      expect(night.isUsable, isFalse);
    });
  });
}
