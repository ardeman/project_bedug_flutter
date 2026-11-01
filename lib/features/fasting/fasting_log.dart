import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/locale_provider.dart';

/// How a day went; names are stable storage keys.
enum FastStatus {
  /// A Ramadan fast kept.
  fasted,

  /// A Ramadan fast missed, to be made up.
  missed,

  /// A Ramadan fast not kept for a reason the law allows, such as illness,
  /// travel or menstruation; it is still made up.
  excused,

  /// A make-up (qada) fast for a missed or excused day.
  qada;

  /// Whether the day adds to the fasts owed.
  bool get owesQada => this == missed || this == excused;
}

/// The fasting log, by calendar day: Ramadan fasts and make-up fasts. Kept
/// on the device only.
@immutable
class FastingLog {
  /// Keyed by the local calendar day at midnight.
  final Map<DateTime, FastStatus> days;

  const FastingLog([this.days = const {}]);

  FastStatus? statusOn(DateTime day) => days[fastingLogDay(day)];

  /// Missed and excused Ramadan days not yet made up; never below zero.
  int get qadaOwed {
    var owed = 0;
    for (final status in days.values) {
      if (status.owesQada) owed++;
      if (status == FastStatus.qada) owed--;
    }
    return owed < 0 ? 0 : owed;
  }

  /// The make-up fasts, the newest first.
  List<DateTime> get qadaDays => [
    for (final MapEntry(:key, :value) in days.entries)
      if (value == FastStatus.qada) key,
  ]..sort((a, b) => b.compareTo(a));

  FastingLog withStatus(DateTime day, FastStatus? status) {
    final next = Map.of(days);
    if (status == null) {
      next.remove(fastingLogDay(day));
    } else {
      next[fastingLogDay(day)] = status;
    }
    return FastingLog(Map.unmodifiable(next));
  }

  String toJson() => jsonEncode({
    for (final MapEntry(:key, :value) in days.entries)
      _dateKey(key): value.name,
  });

  /// Unknown statuses and malformed dates are skipped, so a log written by
  /// a newer version still loads.
  static FastingLog parse(String? source) {
    if (source == null) return const FastingLog();
    try {
      final json = jsonDecode(source) as Map<String, dynamic>;
      final days = <DateTime, FastStatus>{};
      for (final MapEntry(:key, :value) in json.entries) {
        final date = DateTime.tryParse(key);
        final status = FastStatus.values.asNameMap()[value];
        if (date != null && status != null) {
          days[fastingLogDay(date)] = status;
        }
      }
      return FastingLog(Map.unmodifiable(days));
    } on FormatException {
      return const FastingLog();
    } on TypeError {
      return const FastingLog();
    }
  }

  static String _dateKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

/// The calendar day of [date] at local midnight.
DateTime fastingLogDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

const _kFastingLog = 'fasting_log';

class FastingLogNotifier extends Notifier<FastingLog> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  FastingLog build() => FastingLog.parse(_prefs.getString(_kFastingLog));

  /// Sets [day]'s status, or clears it when [status] is null.
  Future<void> set(DateTime day, FastStatus? status) async {
    state = state.withStatus(day, status);
    await _prefs.setString(_kFastingLog, state.toJson());
  }
}

final fastingLogProvider = NotifierProvider<FastingLogNotifier, FastingLog>(
  FastingLogNotifier.new,
);
