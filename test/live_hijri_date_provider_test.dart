import 'package:adhan/adhan.dart';
import 'package:bedug/core/providers/live_hijri_date_provider.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:bedug/core/utils/hijri_utils.dart';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Prayer extends PrayerNotifier {
  final PrayerTimes? times;
  _Prayer(this.times);

  @override
  PrayerState build() => PrayerState(times: times, loading: false);

  void replace(PrayerTimes? value) =>
      state = PrayerState(times: value, loading: false);
}

ProviderContainer _container(PrayerTimes? times) => ProviderContainer(
  overrides: [prayerProvider.overrideWith(() => _Prayer(times))],
);

PrayerTimes _times(DateTime date, {double longitude = 106.8456}) => PrayerTimes(
  Coordinates(-6.2088, longitude),
  DateComponents.from(date),
  CalculationMethod.singapore.getParameters(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final date in [
    DateTime(2026, 10, 21),
    hijriToGregorian(buildHijriMonth(1448, 1).last),
    hijriToGregorian(buildHijriMonth(1447, 12).last),
  ]) {
    test('rolls at Maghrib but not again at midnight for $date', () {
      final times = _times(date);
      final before = times.maghrib.subtract(const Duration(seconds: 1));
      FakeAsync(initialTime: before).run((async) {
        final container = _container(times);
        container.listen(liveHijriDateProvider, (_, _) {});
        final today = DateTime(date.year, date.month, date.day);
        final tomorrow = DateTime(date.year, date.month, date.day + 1);
        expect(container.read(liveHijriDateProvider), today);
        async.elapse(const Duration(seconds: 1));
        expect(container.read(liveHijriDateProvider), tomorrow);
        async.elapse(tomorrow.difference(times.maghrib));
        expect(container.read(liveHijriDateProvider), tomorrow);
        // A stale reference schedule must still calculate the next sunset.
        final nextMaghrib = prayerTimesOn(times, tomorrow).maghrib;
        async.elapse(nextMaghrib.difference(tomorrow));
        expect(
          container.read(liveHijriDateProvider),
          DateTime(date.year, date.month, date.day + 2),
        );
        container.dispose();
      });
    });
  }

  test('location changes recalculate sunset; missing times use civil date', () {
    final date = DateTime(2026, 10, 21);
    final east = _times(date, longitude: 120);
    final west = _times(date, longitude: 90);
    final now = east.maghrib.add(const Duration(minutes: 1));
    expect(now.isBefore(west.maghrib), isTrue);
    FakeAsync(initialTime: now).run((async) {
      final container = _container(east);
      container.listen(liveHijriDateProvider, (_, _) {});
      expect(container.read(liveHijriDateProvider), DateTime(2026, 10, 22));
      final notifier = container.read(prayerProvider.notifier) as _Prayer;
      notifier.replace(west);
      expect(container.read(liveHijriDateProvider), date);
      notifier.replace(null);
      expect(container.read(liveHijriDateProvider), date);
      async.elapse(DateTime(2026, 10, 22).difference(now));
      expect(container.read(liveHijriDateProvider), DateTime(2026, 10, 22));
      container.dispose();
    });
  });

  test('resuming refreshes the label after a suspended sunset', () {
    final times = _times(DateTime(2026, 10, 21));
    var now = times.maghrib.subtract(const Duration(minutes: 1));
    withClock(Clock(() => now), () {
      final container = _container(times);
      container.listen(liveHijriDateProvider, (_, _) {});
      expect(container.read(liveHijriDateProvider), DateTime(2026, 10, 21));
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      now = times.maghrib.add(const Duration(minutes: 1));
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      expect(container.read(liveHijriDateProvider), DateTime(2026, 10, 22));
      container.dispose();
    });
  });
}
