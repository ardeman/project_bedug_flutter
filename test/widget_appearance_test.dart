import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/services/widget_appearance.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'widget defaults retain existing layouts and choices survive restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      ProviderContainer create() => ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      final container = create();
      expect(container.read(widgetAppearanceProvider).showAnalog, isTrue);
      expect(container.read(widgetAppearanceProvider).showSchedule, isTrue);
      expect(container.read(widgetAppearanceProvider).showCurrent, isFalse);
      await container
          .read(widgetAppearanceProvider.notifier)
          .setShowCurrent(true);
      await container
          .read(widgetAppearanceProvider.notifier)
          .setShowAnalog(false);
      await container
          .read(widgetAppearanceProvider.notifier)
          .setShowSchedule(false);
      await container
          .read(widgetAppearanceProvider.notifier)
          .setShowAnalog(true);
      container.dispose();
      final reopened = create();
      addTearDown(reopened.dispose);
      expect(reopened.read(widgetAppearanceProvider).showAnalog, isTrue);
      expect(reopened.read(widgetAppearanceProvider).showCurrent, isTrue);
      expect(reopened.read(widgetAppearanceProvider).showSchedule, isFalse);
    },
  );
}
