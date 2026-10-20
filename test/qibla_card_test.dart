import 'package:adhan/adhan.dart';
import 'package:bedug/core/services/prayer_service.dart';
import 'package:bedug/features/qibla/widgets/qibla_card.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePrayerNotifier extends PrayerNotifier {
  _FakePrayerNotifier(this._state);

  final PrayerState _state;

  @override
  PrayerState build() => _state;
}

Widget _app(
  PrayerState state, {
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) =>
    ProviderScope(
      overrides: [
        prayerProvider.overrideWith(() => _FakePrayerNotifier(state)),
      ],
      child: MaterialApp(
        locale: locale,
        theme: ThemeData(brightness: brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SingleChildScrollView(child: QiblaCard())),
      ),
    );

void main() {
  testWidgets('shows the bearing and north-up guidance without a compass',
      (tester) async {
    final times = PrayerTimes.today(
      Coordinates(-6.2088, 106.8456),
      CalculationMethod.singapore.getParameters(),
    );
    await tester.pumpWidget(_app(PrayerState(
      times: times,
      locationLabel: 'Jakarta',
      loading: false,
    )));

    expect(find.text('Jakarta'), findsOneWidget);
    expect(find.text('295°'), findsOneWidget);
    // Jakarta's destination is northwest of the device. The marker must
    // follow the bearing even in an RTL layout, rather than mirror it.
    final kaaba = find.byKey(const ValueKey('qibla-kaaba-marker'));
    final device = find.byKey(const ValueKey('qibla-device-marker'));
    expect(tester.getCenter(kaaba).dx, lessThan(tester.getCenter(device).dx));
    expect(tester.getCenter(kaaba).dy, lessThan(tester.getCenter(device).dy));
    expect(find.text('295° from north (northwest)'), findsOneWidget);
    expect(
      find.text('Point the top of the screen north, then follow the arrow.'),
      findsOneWidget,
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits a narrow RTL layout with large text in $brightness',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final times = PrayerTimes.today(
        Coordinates(-6.2088, 106.8456),
        CalculationMethod.singapore.getParameters(),
      );
      await tester.pumpWidget(_app(
        PrayerState(
          times: times,
          locationLabel: 'Jakarta · Daerah Khusus Ibukota Jakarta',
          loading: false,
        ),
        locale: const Locale('ar'),
        brightness: brightness,
        textScale: 2,
      ));

      final context = tester.element(find.byType(QiblaCard));
      final l10n = AppLocalizations.of(context);
      expect(Directionality.of(context), TextDirection.rtl);
      expect(tester.takeException(), isNull);
      final kaaba = find.byKey(const ValueKey('qibla-kaaba-marker'));
      final device = find.byKey(const ValueKey('qibla-device-marker'));
      expect(tester.getCenter(kaaba).dx, lessThan(tester.getCenter(device).dx));
      expect(tester.getCenter(kaaba).dy, lessThan(tester.getCenter(device).dy));
      await tester.ensureVisible(find.text(l10n.qiblaFindNorthHint));
      await tester.pumpAndSettle();
      expect(find.text(l10n.qiblaFindNorthHint).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('asks for a location when none is available', (tester) async {
    await tester.pumpWidget(_app(const PrayerState(loading: false)));

    expect(
      find.text("Location isn't available yet. Set it in Settings."),
      findsOneWidget,
    );
  });
}
