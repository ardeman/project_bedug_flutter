import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/features/dzikir/dzikir.dart';
import 'package:bedug/core/design/liquid_glass.dart';
import 'package:bedug/core/design/platform_capabilities.dart';
import 'package:bedug/core/services/kemenag_method.dart';
import 'package:bedug/core/services/notification_preferences.dart';
import 'package:bedug/core/services/notification_sound_preview.dart';
import 'package:bedug/core/services/phone_sound_picker.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:bedug/core/widgets/calculation_method_picker.dart';
import 'package:bedug/features/settings/settings_screen.dart';
import 'package:bedug/core/services/widget_appearance.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/theme/app_theme_scope.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pumpSettings(
  WidgetTester tester, {
  Size size = const Size(800, 2400),
  Locale locale = const Locale('en'),
  double textScale = 1,
  Brightness brightness = Brightness.light,
  Widget home = const SettingsScreen(),
}) async {
  SharedPreferences.setMockInitialValues({'use_auto_location': false});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationSchedulerProvider.overrideWithValue((_, _, _) async {}),
      // Asset loading never completes in the fake-async widget tests.
      dzikirCollectionsProvider.overrideWith((ref) async => [_dzikir]),
    ],
  );
  addTearDown(container.dispose);
  // Tall enough that every row is built.
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(brightness),
        locale: locale,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
        builder: (context, child) => AppThemeScope(
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.macOS,
    TargetPlatform.android,
    TargetPlatform.windows,
    TargetPlatform.linux,
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'method picker fits large text and saves on $platform $brightness',
        (tester) async {
          final locale = brightness == Brightness.dark
              ? const Locale('ar')
              : const Locale('en');
          final container = await _pumpSettings(
            tester,
            size: const Size(390, 844),
            locale: locale,
            textScale: 1.5,
            brightness: brightness,
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: Center(
                  child: GestureDetector(
                    onTap: () => showCalculationMethodPicker(
                      context,
                      ref,
                      current: ref.read(settingsProvider).method,
                    ),
                    child: const Text('Open methods'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open methods'));
          await tester.pumpAndSettle();
          final l10n = AppLocalizations.of(
            tester.element(find.text('Open methods')),
          );
          expect(find.text(l10n.recommended), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.text(l10n.methodMWL),
            150,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.tap(find.text(l10n.methodMWL));
          await tester.pumpAndSettle();
          expect(
            container.read(settingsProvider).method,
            AppCalculationMethod.muslimWorldLeague,
          );
          expect(find.text(l10n.methodMWL), findsNothing);
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant.only(platform),
      );
    }
  }

  testWidgets(
    'widget appearance opens and saves both display options',
    (tester) async {
      final container = await _pumpSettings(tester);
      await tester.ensureVisible(find.text('Widget Style'));
      await tester.tap(find.text('Widget Style'));
      await tester.pumpAndSettle();
      expect(find.byType(WidgetAppearanceScreen), findsOneWidget);
      // Each preview features Dhuhr once, and lists only the four after it.
      expect(find.textContaining('Dhuhr'), findsNWidgets(3));
      expect(find.text('Asr'), findsNWidgets(2));
      final currentSwitch = find.byKey(const ValueKey('widget_current_switch'));
      if (PlatformCapabilities.isIOS) {
        await tester.tap(currentSwitch);
        await tester.pumpAndSettle();
        expect(container.read(widgetAppearanceProvider).showCurrent, isTrue);
        expect(find.text('Now'), findsNWidgets(3));
        expect(find.textContaining('Asr ·'), findsNWidgets(3));
        expect(find.byIcon(Icons.wb_cloudy_outlined), findsNWidgets(3));
        await tester.tap(currentSwitch);
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.wb_sunny_outlined), findsNWidgets(3));
      } else {
        expect(currentSwitch, findsNothing);
      }

      expect(
        tester.getTopLeft(find.text('Analog countdown')).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.byType(GlassTopBar)).dy),
      );
      await tester.tap(find.byKey(const ValueKey('widget_analog_switch')));
      await tester.pumpAndSettle();
      expect(container.read(widgetAppearanceProvider).showAnalog, isFalse);
      expect(container.read(widgetAppearanceProvider).showSchedule, isTrue);
      await tester.tap(find.byKey(const ValueKey('widget_schedule_switch')));
      await tester.pumpAndSettle();
      expect(container.read(widgetAppearanceProvider).showSchedule, isFalse);
      expect(find.text('Asr'), findsNothing);
      expect(find.text('01:30:00'), findsNWidgets(3));
      // Re-enable the dial while keeping the schedule hidden, then inspect the
      // large preview at the bottom of the page for layout overflow.
      await tester.tap(find.byKey(const ValueKey('widget_analog_switch')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Large'));
      await tester.pumpAndSettle();
      expect(container.read(widgetAppearanceProvider).showAnalog, isTrue);
      expect(container.read(widgetAppearanceProvider).showSchedule, isFalse);
      expect(tester.takeException(), isNull);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
      TargetPlatform.windows,
    }),
  );

  for (final brightness in Brightness.values) {
    testWidgets('Apple preview edges remain visible in $brightness', (
      tester,
    ) async {
      await _pumpSettings(
        tester,
        brightness: brightness,
        home: const WidgetAppearanceScreen(),
      );
      for (var size = 0; size < 3; size++) {
        final canvas = find.descendant(
          of: find.byKey(ValueKey('widget_preview_apple_$size')),
          matching: find.byType(DecoratedBox),
        );
        final decoration =
            tester.widget<DecoratedBox>(canvas).decoration as BoxDecoration;
        final border = decoration.border! as Border;
        expect(border.top.color, isNot(decoration.color));
        expect(border.top.color.a, greaterThan(0));
        expect(border.top.width, greaterThan(0));
      }
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }

  testWidgets(
    'Apple previews keep WidgetKit proportions and evenly spaced schedule columns',
    (tester) async {
      final container = await _pumpSettings(
        tester,
        home: const WidgetAppearanceScreen(),
      );
      Finder preview(int size) =>
          find.byKey(ValueKey('widget_preview_apple_$size'));
      final small = tester.getSize(preview(0));
      final medium = tester.getSize(preview(1));
      final large = tester.getSize(preview(2));
      expect(small.aspectRatio, 1);
      expect(medium.aspectRatio, closeTo(364 / 170, 0.001));
      expect(large.aspectRatio, closeTo(364 / 382, 0.001));
      final prayerName = tester.widget<Text>(
        find.descendant(of: preview(0), matching: find.text('Dhuhr')),
      );
      expect(prayerName.style?.fontSize, 28);
      expect(prayerName.style?.fontWeight, FontWeight.bold);
      for (final size in [1, 2]) {
        for (final icon in [
          Icons.wb_cloudy_outlined,
          Icons.nights_stay_outlined,
          Icons.dark_mode_outlined,
          Icons.bedtime_outlined,
        ]) {
          expect(
            find.descendant(of: preview(size), matching: find.byIcon(icon)),
            findsOneWidget,
          );
        }
      }
      final columns = [1, 2, 3, 4]
          .map(
            (index) => tester
                .getCenter(
                  find.byKey(ValueKey('widget_preview_schedule_1_$index')),
                )
                .dx,
          )
          .toList();
      final spacing = columns[1] - columns[0];
      for (var index = 2; index < columns.length; index++) {
        expect(columns[index] - columns[index - 1], closeTo(spacing, 0.01));
      }
      await container
          .read(widgetAppearanceProvider.notifier)
          .setShowSchedule(false);
      await container
          .read(widgetAppearanceProvider.notifier)
          .setShowAnalog(false);
      await tester.pumpAndSettle();
      expect(tester.getSize(preview(1)), medium);
      expect(tester.getSize(preview(2)), large);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'widget appearance supports narrow Arabic and large text',
    (tester) async {
      await _pumpSettings(
        tester,
        home: const WidgetAppearanceScreen(),
        locale: const Locale('ar'),
        size: const Size(320, 1000),
        textScale: 1.5,
        brightness: Brightness.dark,
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).first, const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).first, const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );

  testWidgets('uses glass switches and menus on Apple platforms', (
    tester,
  ) async {
    final container = await _pumpSettings(tester);

    expect(find.byType(LiquidGlassSwitch), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(DropdownButton<int>), findsNothing);
    expect(find.byType(ToggleButtons), findsNothing);

    // The theme row opens a glass menu; picking an option saves it.
    await tester.tap(find.text('System Default'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).themeMode, 2);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  for (final brightness in Brightness.values) {
    testWidgets('Windows madhab selection saves in $brightness', (
      tester,
    ) async {
      final container = await _pumpSettings(tester, brightness: brightness);
      expect(find.byType(ToggleButtons), findsOneWidget);
      await tester.tap(find.text('Hanafi'));
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).isHanafi, isTrue);
      await tester.tap(
        find
            .descendant(
              of: find.byType(ToggleButtons),
              matching: find.byType(Text),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).isHanafi, isFalse);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  }

  testWidgets('Expressive controls save settings', (tester) async {
    final container = await _pumpSettings(tester);

    expect(find.byType(M3ESwitch), findsOneWidget);
    expect(find.byType(M3ESegmentedButton<bool>), findsOneWidget);
    expect(find.byType(M3EDropdownMenu<int>), findsOneWidget);
    expect(find.byType(LiquidGlassSwitch), findsNothing);
    final before = container.read(settingsProvider).useAutoLocation;
    await tester.tap(find.byType(M3ESwitch).last);
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).useAutoLocation, !before);
    await tester.tap(find.text('Hanafi'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).isHanafi, isTrue);
    await tester.tap(find.byType(M3EDropdownMenu<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).themeMode, 2);
  });

  testWidgets(
    'notification controls save per-prayer, reminder and sound choices',
    (tester) async {
      final previewed = <PrayerNotificationSound>[];
      NotificationSoundPreview.debugOverride = previewed.add;
      addTearDown(() => NotificationSoundPreview.debugOverride = null);
      final container = await _pumpSettings(tester);
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('notification-fajr')));
      await tester.pumpAndSettle();
      expect(
        container.read(settingsProvider).notifications.alerts,
        isNot(contains(PrayerAlert.fajr)),
      );

      // An off time has no summary and turns on when tapped.
      final fajrRow = find.byKey(const ValueKey('notification-row-fajr'));
      expect(
        find.descendant(of: fajrRow, matching: find.text('System sound')),
        findsNothing,
      );
      await tester.tap(find.text('Fajr'));
      await tester.pumpAndSettle();
      expect(
        container.read(settingsProvider).notifications.alerts,
        contains(PrayerAlert.fajr),
      );
      expect(find.byType(NotificationSettingsScreen), findsOneWidget);

      // An on time opens its own reminder and sound.
      final dhuhrRow = find.byKey(const ValueKey('notification-row-dhuhr'));
      await tester.ensureVisible(dhuhrRow);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dhuhr'));
      await tester.pumpAndSettle();
      final reminder = find.byKey(
        const ValueKey('notification-reminder-dhuhr'),
      );
      final sound = find.byKey(const ValueKey('notification-sound-dhuhr'));
      if (PlatformCapabilities.isApple) {
        await tester.tap(
          find.descendant(of: reminder, matching: find.text('Off')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('10 minutes before').last);
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: sound, matching: find.text('System sound')),
        );
      } else {
        await tester.tap(
          find.descendant(
            of: reminder,
            matching: find.byType(M3EDropdownMenu<int>),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('10 minutes before').last);
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: sound,
            matching: find.byType(M3EDropdownMenu<PrayerNotificationSound>),
          ),
        );
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bedug').last);
      await tester.pumpAndSettle();
      final notifications = container.read(settingsProvider).notifications;
      expect(notifications.reminders, {PrayerAlert.dhuhr: 10});
      expect(
        notifications.soundOf(PrayerAlert.dhuhr),
        PrayerNotificationSound.bedug,
      );
      expect(previewed, [PrayerNotificationSound.bedug]);
      Navigator.of(tester.element(reminder)).pop();
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: dhuhrRow,
          matching: find.text('Bedug · 10 minutes before'),
        ),
        findsOneWidget,
      );
      final evening = find.byKey(const ValueKey('dzikir-reminder-evening'));
      await tester.scrollUntilVisible(
        evening,
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('15 minutes after Asr'), findsOneWidget);
      await tester.tap(evening);
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).notifications.dzikirReminders, {
        DzikirReminder.evening,
      });
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('notification_dzikir'), ['evening']);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('notifications-enabled')),
        -100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const ValueKey('notifications-enabled')));
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).notifications.enabled, isFalse);
      expect(find.byKey(const ValueKey('notification-fajr')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.invalidate(prayerProvider);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    }),
  );

  testWidgets(
    'Android offers the phone sound picker and names the picked tone',
    (tester) async {
      NotificationSoundPreview.debugOverride = (_) {};
      const tone = PhoneSound(uri: 'content://tone/1', title: 'Chime');
      final asked = <PhoneSound?>[];
      PhoneSoundPicker.debugOverride = (current) async {
        asked.add(current);
        return tone;
      };
      addTearDown(() {
        NotificationSoundPreview.debugOverride = null;
        PhoneSoundPicker.debugOverride = null;
      });
      final container = await _pumpSettings(tester);
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('notification-row-dhuhr')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dhuhr'));
      await tester.pumpAndSettle();
      final dhuhr = find.byKey(const ValueKey('notification-sound-dhuhr'));
      await tester.tap(
        find.descendant(
          of: dhuhr,
          matching: find.byType(M3EDropdownMenu<PrayerNotificationSound>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phone sound…').last);
      await tester.pumpAndSettle();
      final notifications = container.read(settingsProvider).notifications;
      expect(asked, [null]);
      expect(
        notifications.soundOf(PrayerAlert.dhuhr),
        PrayerNotificationSound.phone,
      );
      expect(notifications.phoneSounds[PrayerAlert.dhuhr]?.uri, tone.uri);
      expect(
        find.descendant(of: dhuhr, matching: find.text('Chime')),
        findsWidgets,
      );
      // Tapping the selected tone again reopens the picker.
      await tester.tap(
        find.descendant(
          of: dhuhr,
          matching: find.byType(M3EDropdownMenu<PrayerNotificationSound>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chime').last);
      await tester.pumpAndSettle();
      expect(asked, [null, tone]);
      expect(
        find.descendant(of: dhuhr, matching: find.text('Chime')),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.invalidate(prayerProvider);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'narrow Arabic settings support large text in $brightness',
      (tester) async {
        await _pumpSettings(
          tester,
          size: const Size(320, 932),
          locale: const Locale('ar'),
          textScale: 1.6,
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView).first, const Offset(0, -650));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }),
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'narrow Arabic notification settings support large text in $brightness',
      (tester) async {
        final container = await _pumpSettings(
          tester,
          size: const Size(320, 932),
          locale: const Locale('ar'),
          textScale: 1.6,
          brightness: brightness,
        );
        final context = tester.element(find.byType(SettingsScreen));
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const NotificationSettingsScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 4; i++) {
          await tester.drag(find.byType(ListView).last, const Offset(0, -550));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        container.invalidate(prayerProvider);
      },
      variant: TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }),
    );
  }

  testWidgets(
    'the calculation method opens as a page that saves the pick',
    (tester) async {
      final container = await _pumpSettings(tester);

      await tester.tap(find.text('Calculation Method'));
      await tester.pumpAndSettle();
      // A pushed page, not a sheet, so the edge swipe takes it back.
      expect(find.byType(CalculationMethodScreen), findsOneWidget);

      final screenContext = tester.element(
        find.byType(CalculationMethodScreen),
      );
      final description = find.text(
        AppLocalizations.of(screenContext).calculationMethodDesc,
      );
      expect(
        tester.getTopLeft(description).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.byType(GlassTopBar)).dy),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Umm Al-Qura (Saudi Arabia)'));
      await tester.pumpAndSettle();
      expect(find.byType(CalculationMethodScreen), findsNothing);
      expect(
        container.read(settingsProvider).method,
        AppCalculationMethod.ummAlQura,
      );
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );
}

/// A collection with a morning session, so dzikir reminders are offered.
const _dzikir = DzikirCollection(
  id: 'hisnul_muslim',
  name: {'en': 'Hisnul Muslim'},
  source: {'en': 'Test'},
  items: [
    DzikirItem(
      sessions: {DzikirSession.morning},
      arabic: 'ذكر',
      transliteration: 'dhikr',
      translation: {'en': 'Dhikr'},
      repeat: 1,
      reference: 'Test',
    ),
  ],
);
