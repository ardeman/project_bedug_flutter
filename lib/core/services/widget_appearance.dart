import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_provider.dart';

class WidgetAppearance {
  final bool showAnalog;
  final bool showSchedule;

  const WidgetAppearance({this.showAnalog = true, this.showSchedule = true});
}

class WidgetAppearanceNotifier extends Notifier<WidgetAppearance> {
  @override
  WidgetAppearance build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return WidgetAppearance(
      showAnalog: prefs.getBool('widget_show_analog') ?? true,
      showSchedule: prefs.getBool('widget_show_schedule') ?? true,
    );
  }

  Future<void> setShowAnalog(bool value) async {
    state = WidgetAppearance(
      showAnalog: value,
      showSchedule: state.showSchedule,
    );
    await ref
        .read(sharedPreferencesProvider)
        .setBool('widget_show_analog', value);
  }

  Future<void> setShowSchedule(bool value) async {
    state = WidgetAppearance(showAnalog: state.showAnalog, showSchedule: value);
    await ref
        .read(sharedPreferencesProvider)
        .setBool('widget_show_schedule', value);
  }
}

final widgetAppearanceProvider =
    NotifierProvider<WidgetAppearanceNotifier, WidgetAppearance>(
      WidgetAppearanceNotifier.new,
    );
