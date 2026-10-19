import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../generated/l10n/app_localizations.dart';
import '../constants/city_catalog.dart';
import '../providers/locale_provider.dart';
import 'kemenag_method.dart';
import 'notification_service.dart';

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

  /// Times for [scheduleDays] days, starting today.
  final List<PrayerTimes> schedule;
  final String? locationLabel;
  final bool loading;
  final String? error;
  final bool showLocationGuide;

  const PrayerState({
    this.times,
    this.schedule = const [],
    this.locationLabel,
    this.loading = true,
    this.error,
    this.showLocationGuide = false,
  });

  PrayerState copyWith({
    PrayerTimes? times,
    List<PrayerTimes>? schedule,
    String? locationLabel,
    bool? loading,
    String? error,
    bool? showLocationGuide,
  }) =>
      PrayerState(
        times: times ?? this.times,
        schedule: schedule ?? this.schedule,
        locationLabel: locationLabel ?? this.locationLabel,
        loading: loading ?? this.loading,
        error: error, // Always replaced, so omitting it clears the error.
        showLocationGuide: showLocationGuide ?? this.showLocationGuide,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class PrayerNotifier extends Notifier<PrayerState> {
  /// Incremented by every [load], so a slow earlier load can't overwrite the
  /// result of a newer one.
  int _loadId = 0;

  @override
  PrayerState build() {
    // Reload when a setting that affects the times changes.
    ref.listen(settingsProvider, (prev, next) {
      if (prev?.method != next.method ||
          prev?.isHanafi != next.isHanafi ||
          prev?.useAutoLocation != next.useAutoLocation ||
          prev?.selectedCityId != next.selectedCityId) {
        load();
      }
    });
    // Load after build returns, since state can't be set during build.
    Future.microtask(load);
    return const PrayerState(loading: true);
  }

  Future<void> load() async {
    final loadId = ++_loadId;
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

      final params = settings.method.getParameters();
      if (settings.isHanafi) params.madhab = Madhab.hanafi;
      final schedule = buildPrayerSchedule(coords, params, DateTime.now());
      final times = schedule.first;

      if (loadId != _loadId) return;
      NotificationService.schedulePrayerNotifications(times, _l10n)
          .catchError((_) {});
      state = state.copyWith(
        times: times,
        schedule: schedule,
        locationLabel: locationLabel,
        loading: false,
      );
    } catch (e) {
      if (loadId != _loadId) return;
      final error = e is PrayerLoadException
          ? e
          : PrayerLoadException(_l10n.locationError, showLocationGuide: true);
      state = state.copyWith(
        loading: false,
        error: error.message,
        showLocationGuide: error.showLocationGuide,
      );
    }
  }

  CityOption? _findCityById(String? cityId) {
    if (cityId == null || cityId.isEmpty) return null;
    return supportedCities.where((c) => c.id == cityId).firstOrNull;
  }

  CityOption? _nearestCity(double latitude, double longitude) {
    CityOption? nearest;
    var minDistance = double.infinity;
    for (final city in supportedCities) {
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

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw PrayerLoadException(_l10n.locationPermissionDenied);
      }
    }
    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      // One actionable message; the separate location guide would repeat it.
      throw PrayerLoadException(_locationPermissionDeniedForeverMessage);
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );
    } catch (_) {
      // Covers the timeout too: fall back to a recent last-known fix.
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
      final placemarks = await Geocoding().placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
        locale: ref.read(localeProvider),
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
        // A set literal keeps insertion order and drops repeated names.
        final unique = {...parts};
        if (unique.isNotEmpty) return unique.take(3).join(', ');
      }
    } catch (_) {}

    final nearest = _nearestCity(pos.latitude, pos.longitude);
    return nearest?.name ??
        '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
  }
}

/// How many days the prayer-times tab lists, today included.
const scheduleDays = 30;

/// Prayer times for [days] consecutive days, starting on [start]'s date.
List<PrayerTimes> buildPrayerSchedule(
  Coordinates coords,
  CalculationParameters params,
  DateTime start, {
  int days = scheduleDays,
}) {
  return List.generate(days, (i) {
    // Calendar arithmetic, so a DST change can't skip or repeat a date.
    final date = DateTime(start.year, start.month, start.day + i);
    return PrayerTimes(coords, DateComponents.from(date), params);
  });
}

// ── Providers ─────────────────────────────────────────────────────────────────
final prayerProvider = NotifierProvider<PrayerNotifier, PrayerState>(
  PrayerNotifier.new,
);

final nextPrayerProvider = Provider<({String key, DateTime? time})>((ref) {
  final times = ref.watch(prayerProvider).times;
  if (times == null) return (key: '--', time: null);

  final now = DateTime.now();
  final schedule = {
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
  // After Isha, count down to the next day's Fajr so it never goes negative.
  final nextFajr = times.fajr.add(const Duration(days: 1));
  return (key: 'fajr', time: nextFajr);
});
