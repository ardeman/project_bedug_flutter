import 'package:adhan/adhan.dart';
import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/services/extra_prayer_times.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:bedug/features/prayer_times/prayer_times_screen.dart';
import 'package:bedug/features/prayer_times/widgets/prayer_day_picker.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePrayerNotifier extends PrayerNotifier {
  final PrayerTimes times;
  _FakePrayerNotifier(this.times);

  @override
  PrayerState build() => PrayerState(times: times, loading: false);
}

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'extra times in $locale, $brightness',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = const Size(375, 2600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final times = PrayerTimes.today(
            Coordinates(-6.2088, 106.8456),
            CalculationMethod.singapore.getParameters(),
          );
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                prayerProvider.overrideWith(() => _FakePrayerNotifier(times)),
              ],
              child: MaterialApp(
                locale: locale,
                theme: ThemeData(brightness: brightness),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  ...AppLocalizations.localizationsDelegates,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: const PrayerTimesScreen(),
              ),
            ),
          );
          await tester.pump();
          final context = tester.element(find.byType(PrayerTimesScreen));
          final l10n = AppLocalizations.of(context);
          for (final label in [
            l10n.imsak,
            l10n.dhuha,
            l10n.lastThirdOfNight,
            l10n.imsakDescription,
            l10n.sunriseDescription,
            l10n.dhuhaDescription,
            l10n.lastThirdOfNightDescription,
          ]) {
            expect(find.text(label), findsOneWidget);
          }
          // Categories remain explicit on glass and Material cards in every
          // language, independent of the next-prayer highlight.
          expect(find.text(l10n.prayerCategoryObligatory), findsNWidgets(5));
          expect(find.text(l10n.prayerCategorySunnah), findsNWidgets(2));
          expect(find.text(l10n.prayerCategoryOther), findsNWidgets(2));
          Color? labelColor(String label) =>
              tester.widget<Text>(find.text(label).first).style?.color;
          expect(
            labelColor(l10n.prayerCategorySunnah),
            Theme.of(context).colorScheme.tertiary,
          );
          expect(
            labelColor(l10n.prayerCategoryOther),
            Theme.of(context).colorScheme.onSurfaceVariant,
          );
          // Choosing another date must recalculate the additional times too.
          final picker = tester.widget<PrayerDayPicker>(
            find.byType(PrayerDayPicker),
          );
          final selected = DateTime(2027, 1, 1);
          picker.onSelected(selected);
          await tester.pump();
          final extra = ExtraPrayerTimes(prayerTimesOn(times, selected));
          String formatted(DateTime time) =>
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          for (final time in [
            extra.imsak,
            extra.dhuha,
            extra.lastThirdOfNight,
          ]) {
            expect(find.text(formatted(time)), findsAtLeastNWidgets(1));
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
        variant: TargetPlatformVariant({
          TargetPlatform.macOS,
          TargetPlatform.android,
        }),
      );
    }
  }
}
