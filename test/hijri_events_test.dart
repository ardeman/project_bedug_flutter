import 'dart:io';

import 'package:bedug/features/hijri_events/hijri_events.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';

const _languages = ['id', 'en', 'ms', 'ar'];

/// The Gregorian day of Hijri [month] [day] in 1448 AH (2026–2027).
DateTime _hijri(int month, int day) {
  final date = HijriCalendar().hijriToGregorian(1448, month, day);
  return DateTime(date.year, date.month, date.day);
}

void main() {
  final events = parseHijriEvents(File(hijriEventsAsset).readAsStringSync());

  List<String> idsOn(DateTime day) => [for (final e in events.on(day)) e.id];

  test('every event is named in every language', () {
    for (final event in events.events) {
      for (final language in _languages) {
        expect(event.name[language], isNotEmpty, reason: event.id);
      }
    }
  });

  test('events fall on their Hijri days', () {
    expect(idsOn(_hijri(1, 1)), ['hijri_new_year']);
    expect(idsOn(_hijri(1, 10)), ['ashura']);
    expect(idsOn(_hijri(9, 1)), ['ramadan_start']);
    expect(idsOn(_hijri(10, 1)), ['eid_al_fitr']);
    expect(idsOn(_hijri(12, 10)), ['eid_al_adha']);
    expect(idsOn(_hijri(1, 2)), isEmpty);
  });

  test('the white days come every month but skip 13 Dhu al-Hijjah', () {
    for (final day in [13, 14, 15]) {
      expect(idsOn(_hijri(5, day)), ['ayyamul_bidh']);
    }
    expect(idsOn(_hijri(5, 16)), isEmpty);
    expect(idsOn(_hijri(12, 13)), ['tashreeq']);
    expect(idsOn(_hijri(12, 14)), ['ayyamul_bidh']);
  });

  test('an adjustment moves events to follow a local announcement', () {
    // Announced a day later than calculated: Eid comes the day after.
    final eid = _hijri(10, 1);
    final dayAfter = DateTime(eid.year, eid.month, eid.day + 1);
    expect(events.on(eid, -1).map((e) => e.id), isEmpty);
    expect(events.on(dayAfter, -1).map((e) => e.id), ['eid_al_fitr']);
    final dayBefore = DateTime(eid.year, eid.month, eid.day - 1);
    expect(events.on(dayBefore, 2).map((e) => e.id), isEmpty);
    expect(events.on(dayBefore, 1).map((e) => e.id), ['eid_al_fitr']);
    expect(events.upcoming(eid, count: 1, adjustment: -1).single.day, dayAfter);
  });

  test('upcoming lists each run of days once, from its first day', () {
    final next = events.upcoming(_hijri(12, 9), count: 4);
    expect(
      [for (final e in next) e.day],
      [_hijri(12, 9), _hijri(12, 10), _hijri(12, 11), _hijri(12, 14)],
    );
    expect(
      [for (final e in next) e.events.single.id],
      ['arafah', 'eid_al_adha', 'tashreeq', 'ayyamul_bidh'],
    );
  });

  test('upcoming starting mid-run shows the run from that day', () {
    final next = events.upcoming(_hijri(5, 14), count: 1);
    expect(next.single.day, _hijri(5, 14));
  });

  test('the year ahead holds every event once', () {
    final next = events.upcoming(_hijri(1, 10));
    final ids = [
      for (final e in next)
        for (final event in e.events) event.id,
    ];
    expect(ids.where((id) => id == 'ashura'), hasLength(1));
    expect(ids.where((id) => id == 'ayyamul_bidh'), hasLength(12));
    expect(ids.toSet(), {for (final e in events.events) e.id});
  });

  test('days outside the Umm al-Qura table have no events', () {
    expect(events.on(DateTime(1900)), isEmpty);
  });
}
