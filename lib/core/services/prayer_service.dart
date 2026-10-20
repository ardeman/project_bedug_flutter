import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../generated/l10n/app_localizations.dart';
import '../constants/city_catalog.dart';
import '../providers/locale_provider.dart';
import 'kemenag_method.dart';
import 'notification_service.dart';
import 'notification_preferences.dart';

final notificationSchedulerProvider =
    Provider<
      Future<void> Function(
        PrayerTimes?,
        AppLocalizations,
        NotificationPreferences,
      )
    >((ref) => NotificationService.schedulePrayerNotifications);

/// Injectable because address lookup must never block the prayer schedule.
final reverseGeocoderProvider =
    Provider<Future<List<Placemark>> Function(Position, Locale)>(
      (ref) =>
          (position, locale) => Geocoding().placemarkFromCoordinates(
            position.latitude,
            position.longitude,
            locale: locale,
          ),
    );

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
  final bool notificationError;

  const PrayerState({
    this.times,
    this.locationLabel,
    this.loading = true,
    this.error,
    this.showLocationGuide = false,
    this.notificationError = false,
  });

  PrayerState copyWith({
    PrayerTimes? times,
    String? locationLabel,
    bool? loading,
    String? error,
    bool? showLocationGuide,
    bool? notificationError,
  }) => PrayerState(
    notificationError: notificationError ?? this.notificationError,
    times: times ?? this.times,
    locationLabel: locationLabel ?? this.locationLabel,
    loading: loading ?? this.loading,
    error: error, // Always replaced, so omitting it clears the error.
    showLocationGuide: showLocationGuide ?? this.showLocationGuide,
  );
}

class _PrayerLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;

  _PrayerLifecycleObserver(this.onResume);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class PrayerNotifier extends Notifier<PrayerState> {
  /// Incremented by every [load], so a slow earlier load can't overwrite the
  /// result of a newer one.
  int _loadId = 0;

  @override
  PrayerState build() {
    final observer = _PrayerLifecycleObserver(() => load());
    WidgetsBinding.instance.addObserver(observer);
    Timer? midnight;
    void refreshAtMidnight() {
      final now = clock.now();
      midnight = Timer(
        DateTime(now.year, now.month, now.day + 1).difference(now),
        () {
          load();
          refreshAtMidnight();
        },
      );
    }

    refreshAtMidnight();
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(observer);
      midnight?.cancel();
    });
    // Reload when a setting that affects the times changes.
    ref.listen(settingsProvider, (prev, next) {
      if (prev?.method != next.method ||
          prev?.isHanafi != next.isHanafi ||
          prev?.useAutoLocation != next.useAutoLocation) {
        load();
      } else if (prev?.notifications != next.notifications) {
        _scheduleNotifications();
      }
    });
    // A new city, picked or following a language change, only matters
    // while auto detect is off.
    ref.listen(manualCityProvider, (prev, next) {
      if (prev?.id != next.id && !ref.read(settingsProvider).useAutoLocation) {
        load();
      }
    });
    ref.listen(localeProvider, (_, _) => _scheduleNotifications());
    // Load after build returns, since state can't be set during build.
    Future.microtask(load);
    return const PrayerState(loading: true);
  }

  Future<void> load() async {
    final loadId = ++_loadId;
    state = state.copyWith(
      loading: true,
      error: null,
      showLocationGuide: false,
    );
    try {
      final settings = ref.read(settingsProvider);
      final Coordinates coords;
      final String locationLabel;
      Position? position;

      if (settings.useAutoLocation) {
        final pos = await _getPosition();
        coords = Coordinates(pos.latitude, pos.longitude);
        position = pos;
        locationLabel = _fallbackLocationLabel(pos);
      } else {
        final city = ref.read(manualCityProvider);
        coords = Coordinates(city.latitude, city.longitude);
        locationLabel = city.name;
      }

      final params = settings.method.getParameters();
      if (settings.isHanafi) params.madhab = Madhab.hanafi;
      final times = PrayerTimes.today(coords, params);

      if (!ref.mounted || loadId != _loadId) return;
      state = state.copyWith(
        times: times,
        locationLabel: locationLabel,
        loading: false,
      );
      _scheduleNotifications();
      if (position != null) {
        unawaited(_refineLocationLabel(position, loadId));
      }
    } catch (e) {
      if (!ref.mounted || loadId != _loadId) return;
      // Keep the user's location preference: a failed fix should surface an
      // actionable error, not silently switch prayer times to a manual city.
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

  /// Refreshes alerts after returning from system notification settings.
  Future<void> refreshNotifications() => _scheduleNotifications();

  int _notificationRequest = 0;

  Future<void> _scheduleNotifications() async {
    final times = state.times;
    final request = ++_notificationRequest;
    try {
      await ref.read(notificationSchedulerProvider)(
        times,
        _l10n,
        ref.read(settingsProvider).notifications,
      );
      if (ref.mounted && request == _notificationRequest) {
        state = state.copyWith(notificationError: false, error: state.error);
      }
    } catch (_) {
      if (ref.mounted && request == _notificationRequest) {
        state = state.copyWith(notificationError: true, error: state.error);
      }
    }
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

  String _fallbackLocationLabel(Position pos) =>
      (_nearestCity(pos.latitude, pos.longitude) ??
              defaultCityFor(ref.read(localeProvider).languageCode))
          .name;

  Future<void> _refineLocationLabel(Position pos, int loadId) async {
    final label = await _resolveLocationLabel(pos);
    if (!ref.mounted || loadId != _loadId) return;
    state = state.copyWith(locationLabel: label, error: state.error);
  }

  Future<String> _resolveLocationLabel(Position pos) async {
    final fallback = _fallbackLocationLabel(pos);
    try {
      // A stalled/offline geocoder must not leave a pending lookup forever.
      final placemarks = await ref
          .read(reverseGeocoderProvider)(pos, ref.read(localeProvider))
          .timeout(const Duration(seconds: 3));
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

    return fallback;
  }
}

/// Prayer times on [date]'s calendar day, for the same place and method as
/// [reference]. Calculated on demand, so the schedule can reach any date.
PrayerTimes prayerTimesOn(PrayerTimes reference, DateTime date) => PrayerTimes(
  reference.coordinates,
  // Date only, so the time of day and DST never shift the result.
  DateComponents(date.year, date.month, date.day),
  reference.calculationParameters,
);

// ── Providers ─────────────────────────────────────────────────────────────────
final prayerProvider = NotifierProvider<PrayerNotifier, PrayerState>(
  PrayerNotifier.new,
);

final nextPrayerProvider = Provider<({String key, DateTime? time})>((ref) {
  final times = ref.watch(prayerProvider).times;
  if (times == null) return (key: '--', time: null);

  final now = clock.now();
  final schedule = {
    'fajr': times.fajr,
    'dhuhr': times.dhuhr,
    'asr': times.asr,
    'maghrib': times.maghrib,
    'isha': times.isha,
  };

  // After Isha, count down to the next day's Fajr so it never goes negative.
  final next =
      schedule.entries
          .where((e) => e.value.isAfter(now))
          .map((e) => (key: e.key, time: e.value))
          .firstOrNull ??
      (key: 'fajr', time: times.fajr.add(const Duration(days: 1)));

  // Move on to the following prayer once this one's time arrives.
  final timer = Timer(next.time.difference(now), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return next;
});
