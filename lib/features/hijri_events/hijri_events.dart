import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

const hijriEventsAsset = 'assets/content/hijri_events.json';

/// A day or a run of days on the Hijri calendar, such as Eid al-Fitr or the
/// days of Tashreeq.
@immutable
class HijriEvent {
  final String id;

  /// The event's name in every language.
  final Map<String, String> name;

  /// The Hijri month it falls in, 1 to 12; null for every month, as with
  /// the white days.
  final int? hijriMonth;

  /// The first and last day of the event within its month.
  final (int, int) hijriDays;

  /// (month, day) pairs the event skips, such as 13 Dhu al-Hijjah for the
  /// white days, a day of Tashreeq on which fasting is not allowed.
  final Set<(int, int)> except;

  const HijriEvent({
    required this.id,
    required this.name,
    this.hijriMonth,
    required this.hijriDays,
    this.except = const {},
  });

  String nameFor(String languageCode) => name[languageCode] ?? name['en']!;

  bool fallsOn(HijriCalendar hijri) {
    if (hijriMonth case final month? when month != hijri.hMonth) return false;
    if (except.contains((hijri.hMonth, hijri.hDay))) return false;
    return hijri.hDay >= hijriDays.$1 && hijri.hDay <= hijriDays.$2;
  }
}

class HijriEvents {
  final List<HijriEvent> events;

  const HijriEvents(this.events);

  /// The events on the Gregorian [day], in the file's order. Hijri dates use
  /// the standard conversion of the daytime date, without local
  /// moon-sighting adjustments; days outside the Umm al-Qura table have none.
  List<HijriEvent> on(DateTime day) {
    final HijriCalendar hijri;
    try {
      hijri = HijriCalendar.fromDate(DateTime(day.year, day.month, day.day));
    } on ArgumentError {
      return const [];
    }
    return [
      for (final event in events)
        if (event.fallsOn(hijri)) event,
    ];
  }

  /// The event days in the [days] days from [from] (that day included),
  /// at most [count] of them, each with its events. A run of days, such as
  /// the white days, counts once, on its first day, or on [from] when it is
  /// already under way. The default window is 354 days, the shorter Hijri
  /// year, so every event comes round exactly once.
  List<({DateTime day, List<HijriEvent> events})> upcoming(
    DateTime from, {
    int? count,
    int days = 354,
  }) {
    final result = <({DateTime day, List<HijriEvent> events})>[];
    var previous = <HijriEvent>{};
    for (var i = 0; i < days && result.length < (count ?? days); i++) {
      final day = _addDays(from, i);
      final today = on(day);
      final starting = [
        for (final event in today)
          if (!previous.contains(event)) event,
      ];
      if (starting.isNotEmpty) result.add((day: day, events: starting));
      previous = today.toSet();
    }
    return result;
  }

  // Calendar days, so daylight saving never skips or repeats one.
  static DateTime _addDays(DateTime day, int days) =>
      DateTime(day.year, day.month, day.day + days);
}

/// Parses [hijriEventsAsset].
HijriEvents parseHijriEvents(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  return HijriEvents([
    for (final e in json['events'] as List)
      HijriEvent(
        id: e['id'] as String,
        name: Map<String, String>.from(e['name'] as Map),
        hijriMonth: e['hijriMonth'] as int?,
        hijriDays: (e['hijriDays'][0] as int, e['hijriDays'][1] as int),
        except: {
          for (final d in (e['except'] as List?) ?? const [])
            (d[0] as int, d[1] as int),
        },
      ),
  ]);
}

final hijriEventsProvider = FutureProvider<HijriEvents>(
  (ref) async =>
      parseHijriEvents(await rootBundle.loadString(hijriEventsAsset)),
);
