import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/locale_provider.dart';
import 'quran.dart';

/// Plan lengths offered, in days: a week, half a month, a juz a day and two
/// months.
const khatamDurations = [7, 15, 30, 60];

/// The calendar day of [local] as a UTC midnight, so counting days ignores
/// daylight saving.
DateTime khatamDay(DateTime local) =>
    DateTime.utc(local.year, local.month, local.day);

/// The first and one-past-last ordinals of [juz].
(int, int) _juzBounds(QuranIndex index, int juz) => (
  index.ordinalOf(index.juzStarts[juz - 1]),
  juz < index.juzStarts.length
      ? index.ordinalOf(index.juzStarts[juz])
      : index.ayahCount,
);

/// How much of the Quran reading up to and including [ref] covers, in juz
/// from 0 to 30. The juz are close to equal in length while ayahs vary a
/// lot, so whole juz count evenly and only the share of a juz counts ayahs.
double juzProgress(QuranIndex index, AyahRef? ref) {
  if (ref == null) return 0;
  final juz = index.juzOf(ref);
  final (start, end) = _juzBounds(index, juz);
  return juz - 1 + (index.ordinalOf(ref) + 1 - start) / (end - start);
}

/// The first ayah whose [juzProgress] reaches [progress]; null for none.
AyahRef? ayahAtProgress(QuranIndex index, double progress) {
  if (progress <= 0) return null;
  final juz = progress.ceil().clamp(1, index.juzStarts.length);
  final (start, end) = _juzBounds(index, juz);
  // The small step back keeps rounding error from adding a whole ayah.
  final read = ((progress - (juz - 1)) * (end - start) - 1e-9).ceil().clamp(
    1,
    end - start,
  );
  return index.ayahAt(start + read - 1);
}

/// A plan to read the whole Quran by [finish] in even daily portions, from
/// where the reader was on [start]. Kept on the device only.
@immutable
class KhatamPlan {
  /// Calendar days from [khatamDay].
  final DateTime start;
  final DateTime finish;

  /// The last ayah read before [start]; null to begin at Al-Fatihah.
  final AyahRef? from;

  /// The last ayah the reader marked as read.
  final AyahRef? reached;

  const KhatamPlan({
    required this.start,
    required this.finish,
    this.from,
    this.reached,
  });

  int get days => finish.difference(start).inDays + 1;

  /// The plan's day [today] falls on, from 1 to [days].
  int dayOf(DateTime today) =>
      (khatamDay(today).difference(start).inDays + 1).clamp(1, days);

  /// Days left including [today]; 0 once [finish] has passed.
  int daysLeft(DateTime today) =>
      max(0, finish.difference(khatamDay(today)).inDays + 1);

  /// The ayah to have read up to by the end of [today].
  AyahRef targetFor(QuranIndex index, DateTime today) {
    final begun = juzProgress(index, from);
    final juzCount = index.juzStarts.length;
    final target = begun + (juzCount - begun) * dayOf(today) / days;
    return ayahAtProgress(index, target) ?? index.lastAyah;
  }

  /// The ayah to continue from: the one after [reached].
  AyahRef next(QuranIndex index) => reached == null || reached == index.lastAyah
      ? const AyahRef(1, 1)
      : index.ayahAt(index.ordinalOf(reached!) + 1);

  bool isComplete(QuranIndex index) => reached == index.lastAyah;

  KhatamPlan withReached(AyahRef ayah) =>
      KhatamPlan(start: start, finish: finish, from: from, reached: ayah);

  Map<String, Object?> toJson() => {
    'start': start.toIso8601String(),
    'finish': finish.toIso8601String(),
    'from': from?.toString(),
    'reached': reached?.toString(),
  };

  static KhatamPlan? tryParse(String? source) {
    if (source == null) return null;
    try {
      final json = jsonDecode(source) as Map<String, dynamic>;
      final start = khatamDay(DateTime.parse(json['start'] as String));
      final finish = khatamDay(DateTime.parse(json['finish'] as String));
      if (finish.isBefore(start)) return null;
      return KhatamPlan(
        start: start,
        finish: finish,
        from: AyahRef.tryParse(json['from'] as String?),
        reached: AyahRef.tryParse(json['reached'] as String?),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}

const _kKhatam = 'quran_khatam';

class KhatamNotifier extends Notifier<KhatamPlan?> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  KhatamPlan? build() => KhatamPlan.tryParse(_prefs.getString(_kKhatam));

  /// Starts a plan of [days] from [today]. A running plan's progress carries
  /// over, so changing the length spreads what is left over the new days.
  Future<void> start({required DateTime today, required int days}) => _save(
    KhatamPlan(
      start: khatamDay(today),
      finish: khatamDay(today).add(Duration(days: days - 1)),
      from: state?.reached,
      reached: state?.reached,
    ),
  );

  Future<void> markRead(AyahRef ayah) async {
    if (state case final plan?) await _save(plan.withReached(ayah));
  }

  Future<void> end() async {
    state = null;
    await _prefs.remove(_kKhatam);
  }

  Future<void> _save(KhatamPlan plan) async {
    state = plan;
    await _prefs.setString(_kKhatam, jsonEncode(plan.toJson()));
  }
}

final khatamProvider = NotifierProvider<KhatamNotifier, KhatamPlan?>(
  KhatamNotifier.new,
);
