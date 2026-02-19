import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_widget/home_widget.dart';
import '../../generated/l10n/app_localizations.dart';
import '../constants/city_catalog.dart';
import '../providers/locale_provider.dart';
import 'kemenag_method.dart';

class PrayerLoadException implements Exception {
  final String message;
  final bool showLocationGuide;

  const PrayerLoadException(this.message, {this.showLocationGuide = false});

  @override
  String toString() => message;
}

// ── State ─────────────────────────────────────────────────────────────────────
class PrayerState {
  final PrayerTimes? times;
  final String? locationLabel;
  final bool loading;
  final String? error;
  final bool showLocationGuide;

  const PrayerState({
    this.times,
    this.locationLabel,
    this.loading = true,
    this.error,
    this.showLocationGuide = false,
  });

  PrayerState copyWith({
    PrayerTimes? times,
    String? locationLabel,
    bool? loading,
    String? error,
    bool? showLocationGuide,
  }) =>
      PrayerState(
        times: times ?? this.times,
        locationLabel: locationLabel ?? this.locationLabel,
        loading: loading ?? this.loading,
        error: error, // error bisa null (reset)
        showLocationGuide: showLocationGuide ?? this.showLocationGuide,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class PrayerNotifier extends Notifier<PrayerState> {
  @override
  PrayerState build() {
    // Tunggu settingsProvider siap sebelum load
    ref.listen(settingsProvider, (prev, next) {
      if (prev?.method != next.method ||
          prev?.isHanafi != next.isHanafi ||
          prev?.useAutoLocation != next.useAutoLocation ||
          prev?.selectedCityId != next.selectedCityId) {
        load();
      }
    });
    // Load setelah frame pertama selesai
    Future.microtask(() => load());
    return const PrayerState(loading: true);
  }

  Future<void> load() async {
    state =
        state.copyWith(loading: true, error: null, showLocationGuide: false);
    try {
      final settings = ref.read(settingsProvider);
      final Coordinates coords;
      final String locationLabel;

      if (settings.useAutoLocation) {
        final pos = await _getPosition();
        coords = Coordinates(pos.latitude, pos.longitude);
        locationLabel = await _resolveLocationLabel(pos);
      } else {
        final city = _findCityById(settings.selectedCityId);
        if (city == null) {
          throw PrayerLoadException(_l10n.cityRequiredError);
        }
        coords = Coordinates(city.latitude, city.longitude);
        locationLabel = city.name;
      }

      final method = ref.read(settingsProvider).method;
      final params = method.getParameters();
      if (ref.read(settingsProvider).isHanafi) {
        params.madhab = Madhab.hanafi;
      }

      final times = PrayerTimes.today(coords, params);
      await _saveToWidget(times);

      state = state.copyWith(
        times: times,
        locationLabel: locationLabel,
        loading: false,
      );
    } catch (e) {
      if (e is PrayerLoadException) {
        state = state.copyWith(
          loading: false,
          error: e.message,
          showLocationGuide: e.showLocationGuide,
        );
      } else {
        state = state.copyWith(
          loading: false,
          error: _l10n.locationError,
          showLocationGuide: true,
        );
      }
    }
  }

  CityOption? _findCityById(String? cityId) {
    if (cityId == null || cityId.isEmpty) return null;
    for (final city in supportedCities) {
      if (city.id == cityId) return city;
    }
    return null;
  }

  CityOption? _nearestCity(double latitude, double longitude) {
    if (supportedCities.isEmpty) return null;
    CityOption nearest = supportedCities.first;
    double minDistance = Geolocator.distanceBetween(
      latitude,
      longitude,
      nearest.latitude,
      nearest.longitude,
    );

    for (final city in supportedCities.skip(1)) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        city.latitude,
        city.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = city;
      }
    }
    return nearest;
  }

  AppLocalizations get _l10n =>
      lookupAppLocalizations(ref.read(localeProvider));

  bool get _isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  String get _locationServiceDisabledMessage => _isApplePlatform
      ? _l10n.locationServiceDisabledApple
      : _l10n.locationServiceDisabledAndroid;

  String get _locationPermissionDeniedForeverMessage => _isApplePlatform
      ? _l10n.locationPermissionDeniedForeverApple
      : _l10n.locationPermissionDeniedForeverAndroid;

  Future<Position> _getPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw PrayerLoadException(
        _locationServiceDisabledMessage,
        showLocationGuide: true,
      );
    }

    LocationPermission perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw PrayerLoadException(
        _locationPermissionDeniedForeverMessage,
        showLocationGuide: false,
      );
    }

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw PrayerLoadException(_l10n.locationPermissionDenied);
      }
      if (perm == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        throw PrayerLoadException(
          _locationPermissionDeniedForeverMessage,
          showLocationGuide: false,
        );
      }
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );
    } on TimeoutException {
      final lastKnown = await _getRecentLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      throw PrayerLoadException(_l10n.locationError, showLocationGuide: true);
    } catch (_) {
      final lastKnown = await _getRecentLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      throw PrayerLoadException(_l10n.locationError, showLocationGuide: true);
    }
  }

  LocationSettings get _locationSettings {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        forceLocationManager: true,
        timeLimit: Duration(seconds: 15),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    );
  }

  Future<Position?> _getRecentLastKnownPosition() async {
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown == null) return null;
    final age = DateTime.now().difference(lastKnown.timestamp);
    if (age > const Duration(minutes: 5)) return null;
    return lastKnown;
  }

  Future<String> _resolveLocationLabel(Position pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
          if ((p.subAdministrativeArea ?? '').trim().isNotEmpty)
            p.subAdministrativeArea!.trim(),
          if ((p.administrativeArea ?? '').trim().isNotEmpty)
            p.administrativeArea!.trim(),
          if ((p.country ?? '').trim().isNotEmpty) p.country!.trim(),
        ];
        final unique = <String>[];
        for (final part in parts) {
          if (!unique.contains(part)) unique.add(part);
        }
        if (unique.isNotEmpty) return unique.take(3).join(', ');
      }
    } catch (_) {}

    final nearest = _nearestCity(pos.latitude, pos.longitude);
    return nearest?.name ??
        '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
  }

  Future<void> _saveToWidget(PrayerTimes t) async {
    // home_widget hanya support Android & iOS
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      await Future.wait([
        HomeWidget.saveWidgetData('fajr', _fmt(t.fajr)),
        HomeWidget.saveWidgetData('dhuhr', _fmt(t.dhuhr)),
        HomeWidget.saveWidgetData('asr', _fmt(t.asr)),
        HomeWidget.saveWidgetData('maghrib', _fmt(t.maghrib)),
        HomeWidget.saveWidgetData('isha', _fmt(t.isha)),
      ]);
      await HomeWidget.updateWidget(
        androidName: 'BedugWidgetProvider',
        iOSName: 'BedugWidget',
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
