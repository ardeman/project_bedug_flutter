import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';
import 'tour_targets.dart';

const _completedKey = 'app_tour_completed';

/// A separate preference keeps the tour independent of worship settings.
class AppTourNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(_completedKey) ?? false;

  Future<void> complete() async {
    await ref.read(sharedPreferencesProvider).setBool(_completedKey, true);
    state = true;
  }
}

final appTourCompletedProvider = NotifierProvider<AppTourNotifier, bool>(
  AppTourNotifier.new,
);

/// Drives the coachmarks over the real tabs, including a replay from Settings.
class AppTourController extends Notifier<int?> {
  Completer<void>? _finished;
  bool _finishing = false;

  @override
  int? build() {
    final completed = ref.read(appTourCompletedProvider);
    _finished = completed ? null : Completer<void>();
    return completed ? null : 0;
  }

  Future<void> get finished => _finished?.future ?? Future.value();

  void start() {
    _finished ??= Completer<void>();
    state = 0;
  }

  void next() {
    if (state != null && state! < tourStops.length - 1) state = state! + 1;
  }

  void back() {
    if (state != null && state! > 0) state = state! - 1;
  }

  Future<void> finish() async {
    if (_finishing) return;
    _finishing = true;
    try {
      await ref.read(appTourCompletedProvider.notifier).complete();
      state = null;
      _finished?.complete();
      _finished = null;
    } finally {
      _finishing = false;
    }
  }
}

final appTourControllerProvider = NotifierProvider<AppTourController, int?>(
  AppTourController.new,
);
