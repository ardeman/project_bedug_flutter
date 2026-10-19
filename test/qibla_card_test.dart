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

Widget _app(PrayerState state) => ProviderScope(
      overrides: [
        prayerProvider.overrideWith(() => _FakePrayerNotifier(state)),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: QiblaCard())),
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
    expect(find.text('295° from north (northwest)'), findsOneWidget);
    expect(
      find.text('Point the top of the screen north, then follow the arrow.'),
      findsOneWidget,
    );
  });

  testWidgets('asks for a location when none is available', (tester) async {
    await tester.pumpWidget(_app(const PrayerState(loading: false)));

    expect(
      find.text("Location isn't available yet. Set it in Settings."),
      findsOneWidget,
    );
  });
}
