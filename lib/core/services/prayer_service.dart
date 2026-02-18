import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_widget/home_widget.dart';
import '../providers/locale_provider.dart';
import 'kemenag_method.dart';

// ── State ─────────────────────────────────────────────────────────────────────
class PrayerState {
  final PrayerTimes? times;
  final bool loading;
  final String? error;

  const PrayerState({this.times, this.loading = true, this.error});

  PrayerState copyWith({PrayerTimes? times, bool? loading, String? error}) =>
      PrayerState(
        times:   times   ?? this.times,
        loading: loading ?? this.loading,
        error:   error,           // error bisa null (reset)
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class PrayerNotifier extends Notifier<PrayerState> {
  @override
  PrayerState build() {
    // Tunggu settingsProvider siap sebelum load
    ref.listen(settingsProvider, (prev, next) {
      if (prev?.method != next.method || prev?.isHanafi != next.isHanafi) {
        load();
      }
    });
    // Load setelah frame pertama selesai
    Future.microtask(() => load());
    return const PrayerState(loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final pos    = await _getPosition();
      final coords = Coordinates(pos.latitude, pos.longitude);
      final method = ref.read(settingsProvider).method;
      final params = method.getParameters();
      if (ref.read(settingsProvider).isHanafi) {
        params.madhab = Madhab.hanafi;
      }

      final times = PrayerTimes.today(coords, params);
      await _saveToWidget(times);

      state = state.copyWith(times: times, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<Position> _getPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw Exception('Layanan lokasi tidak aktif. Aktifkan di System Settings.');

    LocationPermission perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw Exception('Izin lokasi ditolak permanen.\nBuka System Settings → Privacy & Security → Location Services → bedug → Allow, lalu coba lagi.');
    }

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
      if (perm == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        throw Exception('Izin lokasi ditolak permanen.\nBuka System Settings → Privacy & Security → Location Services → bedug → Allow, lalu coba lagi.');
      }
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low, // Lebih cepat untuk hisab
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  Future<void> _saveToWidget(PrayerTimes t) async {
    // home_widget hanya support Android & iOS
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      await Future.wait([
        HomeWidget.saveWidgetData('fajr',    _fmt(t.fajr)),
        HomeWidget.saveWidgetData('dhuhr',   _fmt(t.dhuhr)),
        HomeWidget.saveWidgetData('asr',     _fmt(t.asr)),
        HomeWidget.saveWidgetData('maghrib', _fmt(t.maghrib)),
        HomeWidget.saveWidgetData('isha',    _fmt(t.isha)),
      ]);
      await HomeWidget.updateWidget(
        androidName: 'BedugWidgetProvider',
        iOSName:     'BedugWidget',
      );
    } catch (_) {}
  }

  String _fmt(DateTime? d) {
    if (d == null) return '--:--';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final prayerProvider = NotifierProvider<PrayerNotifier, PrayerState>(
  PrayerNotifier.new,
);

final nextPrayerProvider = Provider<({String key, DateTime? time})>((ref) {
  final times = ref.watch(prayerProvider).times;
  if (times == null) return (key: '--', time: null);

  final now = DateTime.now();
  final Map<String, DateTime> schedule = {
    'fajr': times.fajr,
    'dhuhr': times.dhuhr,
    'asr': times.asr,
    'maghrib': times.maghrib,
    'isha': times.isha,
  };

  for (final e in schedule.entries) {
    if (e.value.isAfter(now)) {
      return (key: e.key, time: e.value);
    }
  }
  // Setelah Isya, tampilkan Subuh hari berikutnya agar countdown tidak negatif.
  final nextFajr = times.fajr.add(const Duration(days: 1));
  return (key: 'fajr', time: nextFajr);
});
