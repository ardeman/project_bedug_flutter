import 'dart:async';
import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../features/fasting/ramadan.dart';
import '../../generated/l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../providers/locale_provider.dart';
import '../utils/hijri_utils.dart';
import 'extra_prayer_times.dart';
import 'notification_preferences.dart';
import 'prayer_service.dart';
import 'widget_appearance.dart';

/// Absolute instants let native widgets advance without running Flutter.
/// No coordinates are persisted outside the app; only its displayed city.
Map<String, Object> buildPrayerWidgetData({
  required PrayerTimes? times,
  required String? location,
  required AppLocalizations l10n,
  required DateTime now,
  required int themeMode,
  WidgetAppearance appearance = const WidgetAppearance(),
  HijriReckoning hijriReckoning = const HijriReckoning(),
}) {
  final prayers = <Map<String, Object>>[];
  // Today's passed prayers let the lock screen schedule show the whole day,
  // and the latest passed one names the current prayer, even after midnight.
  final earlier = <Map<String, Object>>[];
  var intervalStart = now;
  DateTime? previousPrayer;
  Map<String, Object>? previousEntry;
  if (times != null) {
    // Include yesterday when finding the start of the overnight countdown.
    for (var day = -1; day < 7; day++) {
      final daily = PrayerTimes(
        times.coordinates,
        DateComponents.from(DateTime(now.year, now.month, now.day + day)),
        times.calculationParameters,
      );
      for (final prayer in notificationPrayers) {
        final time = daily.timeForPrayer(prayer);
        if (time == null) continue;
        final name = switch (prayer) {
          Prayer.fajr => l10n.fajr,
          Prayer.dhuhr => dhuhrName(l10n, time),
          Prayer.asr => l10n.asr,
          Prayer.maghrib => l10n.maghrib,
          Prayer.isha => l10n.isha,
          _ => '',
        };
        final entry = <String, Object>{
          'key': prayer.name,
          'name': name,
          'time': time.millisecondsSinceEpoch,
          // Fajr's time ends at sunrise, not at Dhuhr.
          if (prayer == Prayer.fajr)
            'end': daily.sunrise.millisecondsSinceEpoch,
        };
        if (!time.isAfter(now)) {
          if (previousPrayer == null || time.isAfter(previousPrayer)) {
            previousPrayer = time;
            previousEntry = entry;
          }
          if (day == 0) earlier.add(entry);
          continue;
        }
        if (day < 0) continue;
        prayers.add(entry);
      }
    }
    intervalStart = previousPrayer ?? now;
    if (previousEntry != null && !earlier.contains(previousEntry)) {
      earlier.insert(0, previousEntry);
    }
  }
  prayers.sort((a, b) => (a['time'] as int).compareTo(b['time'] as int));
  return {
    'prayers': prayers,
    'earlier': earlier,
    'intervalStart': intervalStart.millisecondsSinceEpoch,
    'location': location ?? '',
    'locale': l10n.localeName,
    'title': l10n.nextPrayer,
    'refresh': l10n.widgetRefresh,
    'themeMode': themeMode,
    'showAnalog': appearance.showAnalog,
    'showSchedule': appearance.showSchedule,
    'showCurrent': appearance.showCurrent,
    'ramadan': buildRamadanWidgetData(
      times: times,
      l10n: l10n,
      now: now,
      reckoning: hijriReckoning,
    ),
    ...widgetPalette(),
  };
}

/// Stands in for the next Ramadan's first day in `next`.
const nextDateToken = '{date}';

/// The Ramadan countdown's week: each fast in the seven days from [now],
/// with when its sahur begins (Maghrib the evening before), imsak, Fajr and
/// iftar, so the widgets switch between counting to imsak and to iftar on
/// their own. Outside Ramadan, `next` says when the next one begins, at
/// `nextStart`.
Map<String, Object> buildRamadanWidgetData({
  required PrayerTimes? times,
  required AppLocalizations l10n,
  required DateTime now,
  HijriReckoning reckoning = const HijriReckoning(),
}) {
  final today = DateTime(now.year, now.month, now.day);
  final fasts = <Map<String, Object>>[];
  if (times != null) {
    for (var offset = 0; offset < 7; offset++) {
      final day = DateTime(today.year, today.month, today.day + offset);
      final ramadanDay = ramadanDayOf(day, reckoning);
      if (ramadanDay == null) continue;
      final daily = prayerTimesOn(times, day);
      final eve = prayerTimesOn(
        times,
        DateTime(day.year, day.month, day.day - 1),
      );
      fasts.add({
        'title': l10n.ramadanTitle(ramadanDay),
        'since': eve.maghrib.millisecondsSinceEpoch,
        'imsak': ExtraPrayerTimes(daily).imsak.millisecondsSinceEpoch,
        'fajr': daily.fajr.millisecondsSinceEpoch,
        'iftar': daily.maghrib.millisecondsSinceEpoch,
      });
    }
  }
  var upcoming = currentOrNextRamadan(today, reckoning);
  if (upcoming != null && upcoming.contains(today)) {
    upcoming = ramadanOf(upcoming.hijriYear + 1, reckoning);
  }
  return {
    'fasts': fasts,
    // Past the week, the fasts are unknown until the app runs again.
    'until': DateTime(
      today.year,
      today.month,
      today.day + 7,
    ).millisecondsSinceEpoch,
    'title': l10n.ramadan,
    'untilImsak': l10n.ramadanUntilImsak,
    'untilIftar': l10n.ramadanUntilIftar,
    'imsak': l10n.imsak,
    'fajr': l10n.fajr,
    'maghrib': l10n.maghrib,
    if (upcoming != null) ...{
      // Native widgets format the date in place of the token, so Flutter
      // needs no date symbols here.
      'next': l10n.fastingLogBegins(nextDateToken, upcoming.hijriYear),
      'nextStart': upcoming.start.millisecondsSinceEpoch,
    },
  };
}

/// Native views share the app's palette instead of duplicating hex values.
Map<String, Object> widgetPalette() => {
  'lightBackground': AppColors.lightBg.toARGB32(),
  'darkBackground': AppColors.darkBg.toARGB32(),
  'lightText': AppColors.lightText.toARGB32(),
  'darkText': AppColors.darkText.toARGB32(),
  'lightAccent': AppColors.emerald.toARGB32(),
  'darkAccent': AppColors.emeraldDark.toARGB32(),
};

class PrayerWidgetService {
  static const appGroup = 'group.com.ardeman.bedug';
  Future<void> _pending = Future.value();

  /// Serialize writes so a slow update cannot replace a newer city or locale.
  Future<void> update(Map<String, Object> data) {
    _pending = _pending.then((_) async {
      try {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          await HomeWidget.setAppGroupId(appGroup);
        }
        await HomeWidget.saveWidgetData<String>(
          'prayer_widget',
          jsonEncode(data),
        );
        await HomeWidget.updateWidget(
          androidName: 'PrayerWidgetProvider',
          iOSName: 'BedugPrayerWidget',
        );
        if (defaultTargetPlatform == TargetPlatform.android) {
          await HomeWidget.updateWidget(androidName: 'RamadanWidgetProvider');
        }
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          // The lock screen schedule and the Ramadan countdown are separate
          // WidgetKit kinds.
          await HomeWidget.updateWidget(iOSName: 'BedugScheduleWidget');
          await HomeWidget.updateWidget(iOSName: 'BedugRamadanWidget');
        }
      } catch (error) {
        // A widget failure must not prevent prayer times from loading.
        debugPrint('Prayer widget update failed: $error');
      }
    });
    return _pending;
  }
}

final prayerWidgetServiceProvider = Provider((ref) => PrayerWidgetService());

final prayerWidgetSyncProvider = Provider<void>((ref) {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    return;
  }
  void sync() {
    final state = ref.read(prayerProvider);
    final ready = !state.loading && state.error == null;
    unawaited(
      ref
          .read(prayerWidgetServiceProvider)
          .update(
            buildPrayerWidgetData(
              times: ready ? state.times : null,
              location: ready ? state.locationLabel : null,
              l10n: lookupAppLocalizations(ref.read(localeProvider)),
              now: clock.now(),
              themeMode: ref.read(settingsProvider).themeMode,
              appearance: ref.read(widgetAppearanceProvider),
              hijriReckoning: ref.read(settingsProvider).hijriReckoning,
            ),
          ),
    );
  }

  ref.listen(prayerProvider, (previous, next) {
    if (previous?.times != next.times ||
        previous?.loading != next.loading ||
        previous?.error != next.error ||
        previous?.locationLabel != next.locationLabel) {
      sync();
    }
  });
  ref.listen(localeProvider, (_, _) => sync());
  ref.listen(widgetAppearanceProvider, (_, _) => sync());
  ref.listen(settingsProvider.select((s) => s.themeMode), (_, _) => sync());
  ref.listen(
    settingsProvider.select((s) => s.hijriReckoning),
    (_, _) => sync(),
  );
  sync();
});
