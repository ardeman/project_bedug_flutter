import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_provider.dart';

class WidgetAppearance {
  final bool showAnalog;
  final bool showSchedule;
  final bool showCurrent;

  const WidgetAppearance({
    this.showAnalog = true,
    this.showSchedule = true,
    this.showCurrent = false,
  });
}

class WidgetAppearanceNotifier extends Notifier<WidgetAppearance> {
  @override
  WidgetAppearance build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return WidgetAppearance(
      showAnalog: prefs.getBool('widget_show_analog') ?? true,
      showSchedule: prefs.getBool('widget_show_schedule') ?? true,
      showCurrent: prefs.getBool('widget_show_current') ?? false,
    );
  }

  Future<void> setShowAnalog(bool value) async {
    state = WidgetAppearance(
      showAnalog: value,
      showSchedule: state.showSchedule,
      showCurrent: state.showCurrent,
    );
    await ref
        .read(sharedPreferencesProvider)
        .setBool('widget_show_analog', value);
  }

  Future<void> setShowSchedule(bool value) async {
    state = WidgetAppearance(
      showAnalog: state.showAnalog,
      showSchedule: value,
      showCurrent: state.showCurrent,
    );
    await ref
        .read(sharedPreferencesProvider)
        .setBool('widget_show_schedule', value);
  }

  Future<void> setShowCurrent(bool value) async {
    state = WidgetAppearance(
      showAnalog: state.showAnalog,
      showSchedule: state.showSchedule,
      showCurrent: value,
    );
    await ref
        .read(sharedPreferencesProvider)
        .setBool('widget_show_current', value);
  }
}

final widgetAppearanceProvider =
    NotifierProvider<WidgetAppearanceNotifier, WidgetAppearance>(
      WidgetAppearanceNotifier.new,
    );
