import 'dart:async';

import 'package:bedug/core/providers/locale_provider.dart';
import 'package:bedug/core/services/distribution_channel.dart';
import 'package:bedug/core/theme/app_theme.dart';
import 'package:bedug/core/theme/app_theme_scope.dart';
import 'package:bedug/features/infaq/infaq_provider.dart';
import 'package:bedug/features/infaq/infaq_screen.dart';
import 'package:bedug/generated/l10n/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProductDetails _product(String id, double price) => ProductDetails(
  id: id,
  title: id,
  description: '',
  price: 'Rp ${price.toStringAsFixed(0)}',
  rawPrice: price,
  currencyCode: 'IDR',
);

final _products = [
  _product(InfaqProducts.large, 49000),
  _product(InfaqProducts.small, 5000),
  _product(InfaqProducts.medium, 19000),
];

class _FakeStore implements InAppPurchase {
  final purchases = StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  final bought = <String>[];
  final completed = <String>[];
  int restores = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => purchases.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: available ? _products : [],
    notFoundIDs: [],
  );

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    bought.add('consumable:${purchaseParam.productDetails.id}');
    return true;
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    bought.add('non-consumable:${purchaseParam.productDetails.id}');
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase.productID);

  @override
  Future<void> restorePurchases({String? applicationUserName}) async =>
      restores++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PurchaseDetails _purchase(String id, PurchaseStatus status) =>
    PurchaseDetails(
        productID: id,
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: 'test',
        ),
        transactionDate: null,
        status: status,
      )
      ..pendingCompletePurchase =
          status == PurchaseStatus.purchased ||
          status == PurchaseStatus.restored;

Future<ProviderContainer> _container({
  _FakeStore? store,
  DistributionChannel channel = DistributionChannel.play,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final shared = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(shared),
      distributionChannelProvider.overrideWithValue(channel),
      infaqStoreProvider.overrideWithValue(store),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _pumpInfaq(
  WidgetTester tester,
  ProviderContainer container,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        locale: container.read(localeProvider),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const InfaqScreen(),
        builder: (context, child) => AppThemeScope(child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('build channel defaults to the platform store', () {
    expect(
      DistributionChannel.parse('', TargetPlatform.android),
      DistributionChannel.play,
    );
    expect(
      DistributionChannel.parse('', TargetPlatform.macOS),
      DistributionChannel.appStore,
    );
    expect(
      DistributionChannel.parse('', TargetPlatform.windows),
      DistributionChannel.direct,
    );
    expect(
      DistributionChannel.parse('fdroid', TargetPlatform.android),
      DistributionChannel.fdroid,
    );
    expect(
      DistributionChannel.fdroid.showsAdsOn(TargetPlatform.android),
      isFalse,
    );
    expect(
      DistributionChannel.appStore.showsAdsOn(TargetPlatform.macOS),
      isFalse,
    );
    expect(DistributionChannel.appStore.showsAdsOn(TargetPlatform.iOS), isTrue);
  });

  test('loads products cheapest first', () async {
    final container = await _container(store: _FakeStore());
    await container.read(infaqProvider.notifier).load();
    final state = container.read(infaqProvider);
    expect(state.products.map((p) => p.id), [
      InfaqProducts.small,
      InfaqProducts.medium,
      InfaqProducts.large,
    ]);
    expect(state.error, isNull);
  });

  test('an unavailable store reports an error', () async {
    final container = await _container(store: _FakeStore()..available = false);
    await container.read(infaqProvider.notifier).load();
    expect(container.read(infaqProvider).error, InfaqError.storeUnavailable);
  });

  test('a purchase thanks, removes ads and survives a restart', () async {
    final store = _FakeStore();
    final container = await _container(store: store);
    final notifier = container.read(infaqProvider.notifier);
    await notifier.load();
    await notifier.buy(_products[1]);
    expect(store.bought, ['non-consumable:${InfaqProducts.small}']);
    expect(container.read(infaqProvider).pending, isTrue);

    store.purchases.add([
      _purchase(InfaqProducts.small, PurchaseStatus.purchased),
    ]);
    await pumpEventQueue();
    final state = container.read(infaqProvider);
    expect(state.pending, isFalse);
    expect(state.thanked, isTrue);
    expect(state.adFree, isTrue);
    expect(store.completed, [InfaqProducts.small]);

    final prefs = container.read(sharedPreferencesProvider);
    final reopened = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        infaqStoreProvider.overrideWithValue(null),
      ],
    );
    addTearDown(reopened.dispose);
    expect(reopened.read(infaqProvider).adFree, isTrue);
  });

  test(
    'a cancelled infaq leaves ads on; a restored one turns them off',
    () async {
      final store = _FakeStore();
      final container = await _container(store: store);
      final notifier = container.read(infaqProvider.notifier);
      await notifier.buy(_products[2]);
      expect(store.bought, ['non-consumable:${InfaqProducts.medium}']);
      store.purchases.add([
        _purchase(InfaqProducts.medium, PurchaseStatus.canceled),
      ]);
      await pumpEventQueue();
      expect(container.read(infaqProvider).pending, isFalse);
      expect(container.read(infaqProvider).adFree, isFalse);

      await notifier.restore();
      expect(store.restores, 1);
      store.purchases.add([
        _purchase(InfaqProducts.small, PurchaseStatus.restored),
      ]);
      await pumpEventQueue();
      expect(container.read(infaqProvider).adFree, isTrue);
      expect(container.read(infaqProvider).thanked, isFalse);
    },
  );

  test('a failed purchase reports an error', () async {
    final store = _FakeStore();
    final container = await _container(store: store);
    final notifier = container.read(infaqProvider.notifier);
    await notifier.buy(_products[0]);
    store.purchases.add([_purchase(InfaqProducts.large, PurchaseStatus.error)]);
    await pumpEventQueue();
    final state = container.read(infaqProvider);
    expect(state.error, InfaqError.purchaseFailed);
    expect(state.pending, isFalse);
    expect(state.adFree, isFalse);
  });

  testWidgets('store builds list the tiers and buy on tap', (tester) async {
    final store = _FakeStore();
    final container = await _container(
      store: store,
      prefs: {'app_locale': 'en'},
    );
    await _pumpInfaq(tester, container);
    expect(find.text('Small infaq'), findsOneWidget);
    expect(find.text('Large infaq'), findsOneWidget);
    expect(find.text('Rp 49000'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);

    await tester.tap(find.text('Medium infaq'));
    await tester.pumpAndSettle();
    expect(store.bought, ['non-consumable:${InfaqProducts.medium}']);
  });

  for (final (locale, first) in [('id', 'Trakteer'), ('en', 'Ko-fi')]) {
    testWidgets('direct builds link $first first in $locale', (tester) async {
      final container = await _container(
        channel: DistributionChannel.direct,
        prefs: {'app_locale': locale},
      );
      await _pumpInfaq(tester, container);
      final trakteer = tester.getTopLeft(find.text('Trakteer')).dy;
      final kofi = tester.getTopLeft(find.text('Ko-fi')).dy;
      expect(first == 'Trakteer' ? trakteer < kofi : kofi < trakteer, isTrue);
      expect(find.text('Restore purchases'), findsNothing);
    });
  }
}
