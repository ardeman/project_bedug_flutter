import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/theme/app_theme_scope.dart';
import 'package:bedug/features/zakat/zakat.dart';
import 'package:bedug/features/zakat/zakat_screen.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

TextEditingValue _type(
  AmountInputFormatter formatter,
  String text, [
  int? cursor,
]) => formatter.formatEditUpdate(
  TextEditingValue.empty,
  TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: cursor ?? text.length),
  ),
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final shared = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(shared)],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ZakatScreen(),
        builder: (context, child) => AppThemeScope(child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Apple (Cupertino fields), Material (Expressive) and Windows (text fields).
final _platforms = TargetPlatformVariant({
  TargetPlatform.iOS,
  TargetPlatform.android,
  TargetPlatform.windows,
});

Finder _field(String key) => find.descendant(
  of: find.byKey(ValueKey('zakat-$key')),
  matching: find.byType(EditableText),
);

void main() {
  group('ZakatMaal', () {
    test('is 2.5% of net wealth at or above the nisab', () {
      const maal = ZakatMaal(
        goldPricePerGram: 1000000,
        assets: 100000000,
        debts: 10000000,
      );
      expect(maal.nisab, 85000000);
      expect(maal.netWealth, 90000000);
      expect(maal.reachesNisab, isTrue);
      expect(maal.zakat, 2250000);
    });

    test('is due exactly at the nisab and rounds up', () {
      const maal = ZakatMaal(goldPricePerGram: 1, assets: 85, debts: 0);
      expect(maal.reachesNisab, isTrue);
      expect(maal.zakat, 3);
    });

    test('is not due below the nisab or without a gold price', () {
      const below = ZakatMaal(
        goldPricePerGram: 1000000,
        assets: 90000000,
        debts: 10000000,
      );
      expect(below.reachesNisab, isFalse);
      expect(below.zakat, 0);

      const noPrice = ZakatMaal(goldPricePerGram: 0, assets: 5, debts: 0);
      expect(noPrice.hasNisab, isFalse);
      expect(noPrice.zakat, 0);
    });

    test('never counts debts beyond the assets', () {
      const maal = ZakatMaal(goldPricePerGram: 1, assets: 10, debts: 50);
      expect(maal.netWealth, 0);
      expect(maal.zakat, 0);
    });
  });

  test('zakat fitrah counts each person', () {
    expect(zakatFitrah(people: 4, perPerson: 47000), 188000);
    expect(fitrahStapleKg(4), 10);
    expect(zakatFitrah(people: -1, perPerson: 47000), 0);
  });

  group('AmountInputFormatter', () {
    test('groups digits as the locale does', () {
      expect(_type(AmountInputFormatter('en'), '1234567').text, '1,234,567');
      expect(_type(AmountInputFormatter('id'), '1234567').text, '1.234.567');
      expect(_type(AmountInputFormatter('en'), 'abc').text, '');
      expect(parseAmount('1.234.567'), 1234567);
      expect(parseAmount(''), 0);
    });

    test('keeps the cursor after the same digit', () {
      // Typing "9" before "1,234".
      final value = _type(AmountInputFormatter('en'), '91,234', 1);
      expect(value.text, '91,234');
      expect(value.selection.extentOffset, 1);
      // Typing "5" at the end regroups the digits.
      final end = _type(AmountInputFormatter('en'), '1,2345');
      expect(end.text, '12,345');
      expect(end.selection.extentOffset, 6);
    });
  });

  testWidgets('works out zakat maal and keeps only the gold price', (
    tester,
  ) async {
    final container = await _pump(tester);
    expect(
      find.text('Enter the gold price to find the nisab.'),
      findsOneWidget,
    );

    await tester.enterText(_field('gold-price'), '1000000');
    await tester.enterText(_field('cash'), '100000000');
    await tester.enterText(_field('debts'), '10000000');
    await tester.pumpAndSettle();

    expect(find.text('Nisab (85 g of gold): 85,000,000'), findsOneWidget);
    expect(find.text('Net wealth: 90,000,000'), findsOneWidget);
    expect(find.text('2,250,000'), findsOneWidget);
    expect(container.read(zakatPricesProvider).goldPricePerGram, 1000000);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getKeys(), {'zakat_gold_price_per_gram'});
  }, variant: _platforms);

  testWidgets('works out zakat fitrah from the saved amount', (tester) async {
    await _pump(tester, prefs: {'zakat_fitrah_per_person': 47000});
    await tester.tap(find.text('Fitrah'));
    await tester.pumpAndSettle();

    expect(find.text('47,000'), findsWidgets);
    await tester.enterText(_field('people'), '4');
    await tester.pumpAndSettle();
    expect(find.text('188,000'), findsOneWidget);
    expect(find.text('Or 10 kg of staple food'), findsOneWidget);
  }, variant: _platforms);
}
