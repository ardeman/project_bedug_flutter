import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/prayer_service.dart';

/// Gregorian date to convert for the live Hijri label. Static calendar
/// conversions retain their usual mapping when browsing other dates.
final liveHijriDateProvider = Provider<DateTime>((ref) {
  final now = clock.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final reference = ref.watch(prayerProvider).times;
  final maghrib = reference == null
      ? null
      : prayerTimesOn(reference, today).maghrib;
  final afterMaghrib = maghrib != null && !now.isBefore(maghrib);
  final boundary = maghrib != null && now.isBefore(maghrib)
      ? maghrib
      : tomorrow;
  final timer = Timer(boundary.difference(now), ref.invalidateSelf);
  final observer = _ResumeObserver(ref.invalidateSelf);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() {
    timer.cancel();
    WidgetsBinding.instance.removeObserver(observer);
  });
  return afterMaghrib ? tomorrow : today;
});

class _ResumeObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;

  _ResumeObserver(this.onResume);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}
