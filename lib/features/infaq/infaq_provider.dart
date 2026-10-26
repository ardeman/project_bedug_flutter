import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/services/distribution_channel.dart';

/// Store product IDs, set up in App Store Connect and Play Console as
/// non-consumables (US\$0.99, \$2.99 and \$4.99; Rp 5,000, 19,000 and
/// 49,000), as in Coba Lagi. Any of them turns the ads off, and the store
/// restores it on a new device, so the small one is the ad-free price.
abstract final class InfaqProducts {
  static const small = 'infaq_small';
  static const medium = 'infaq_medium';
  static const large = 'infaq_large';

  static const all = {small, medium, large};
}

/// External infaq pages for builds without store billing.
abstract final class InfaqLinks {
  static final trakteer = Uri.parse('https://trakteer.id/bedug');
  static final kofi = Uri.parse('https://ko-fi.com/bedug');
}

enum InfaqError {
  /// The store can't be reached or has no infaq products.
  storeUnavailable,

  /// A purchase or restore failed in the store.
  purchaseFailed,
}

class InfaqState {
  /// Set by any infaq, bought or restored; hides the ads.
  final bool adFree;

  /// The store's products, cheapest first; empty until [InfaqNotifier.load].
  final List<ProductDetails> products;
  final bool loading;

  /// A purchase is open in the store sheet or awaits payment.
  final bool pending;

  /// The last purchase went through; the page says thank you.
  final bool thanked;
  final InfaqError? error;

  const InfaqState({
    this.adFree = false,
    this.products = const [],
    this.loading = false,
    this.pending = false,
    this.thanked = false,
    this.error,
  });

  InfaqState copyWith({
    bool? adFree,
    List<ProductDetails>? products,
    bool? loading,
    bool? pending,
    bool? thanked,
    InfaqError? Function()? error,
  }) => InfaqState(
    adFree: adFree ?? this.adFree,
    products: products ?? this.products,
    loading: loading ?? this.loading,
    pending: pending ?? this.pending,
    thanked: thanked ?? this.thanked,
    error: error != null ? error() : this.error,
  );
}

final distributionChannelProvider = Provider<DistributionChannel>(
  (ref) => DistributionChannel.current,
);

/// The store, or null when this build's channel has no store billing.
/// Tests override it with a fake.
final infaqStoreProvider = Provider<InAppPurchase?>(
  (ref) => ref.watch(distributionChannelProvider).usesStoreBilling
      ? InAppPurchase.instance
      : null,
);

const _adFreeKey = 'infaq_ad_free';

class InfaqNotifier extends Notifier<InfaqState> {
  StreamSubscription<List<PurchaseDetails>>? _purchases;

  @override
  InfaqState build() {
    ref.onDispose(() => _purchases?.cancel());
    return InfaqState(
      adFree: ref.read(sharedPreferencesProvider).getBool(_adFreeKey) ?? false,
    );
  }

  InAppPurchase? get _store => ref.read(infaqStoreProvider);

  /// Starts listening for purchases. Call it at launch: the store
  /// re-delivers unfinished transactions until they're completed.
  void listen() {
    final store = _store;
    if (store == null || _purchases != null) return;
    _purchases = store.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        debugPrint('Infaq purchase stream failed: $e');
        state = state.copyWith(
          pending: false,
          error: () => InfaqError.purchaseFailed,
        );
      },
    );
  }

  /// Loads the products for the infaq page.
  Future<void> load() async {
    final store = _store;
    if (store == null || state.loading) return;
    listen();
    state = state.copyWith(loading: true, error: () => null);
    try {
      final available = await store.isAvailable();
      final response = available
          ? await store.queryProductDetails(InfaqProducts.all)
          : null;
      final products = [...?response?.productDetails]
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      state = state.copyWith(
        loading: false,
        products: products,
        error: () => products.isEmpty ? InfaqError.storeUnavailable : null,
      );
    } catch (e) {
      debugPrint('Infaq products failed to load: $e');
      state = state.copyWith(
        loading: false,
        error: () => InfaqError.storeUnavailable,
      );
    }
  }

  Future<void> buy(ProductDetails product) async {
    final store = _store;
    if (store == null || state.pending) return;
    listen();
    state = state.copyWith(pending: true, thanked: false, error: () => null);
    final param = PurchaseParam(productDetails: product);
    try {
      final started = await store.buyNonConsumable(purchaseParam: param);
      if (!started) state = state.copyWith(pending: false);
    } catch (e) {
      debugPrint('Infaq purchase failed to start: $e');
      state = state.copyWith(
        pending: false,
        error: () => InfaqError.purchaseFailed,
      );
    }
  }

  /// Asks the store to re-deliver any infaq bought on this account.
  Future<void> restore() async {
    final store = _store;
    if (store == null) return;
    listen();
    state = state.copyWith(error: () => null);
    try {
      await store.restorePurchases();
    } catch (e) {
      debugPrint('Infaq restore failed: $e');
      state = state.copyWith(error: () => InfaqError.purchaseFailed);
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(pending: true);
        case PurchaseStatus.purchased:
          await _setAdFree();
          state = state.copyWith(pending: false, thanked: true);
        case PurchaseStatus.restored:
          await _setAdFree();
          state = state.copyWith(pending: false);
        case PurchaseStatus.error:
          state = state.copyWith(
            pending: false,
            error: () => InfaqError.purchaseFailed,
          );
        case PurchaseStatus.canceled:
          state = state.copyWith(pending: false);
      }
      if (purchase.pendingCompletePurchase) {
        await _store?.completePurchase(purchase);
      }
    }
  }

  Future<void> _setAdFree() async {
    state = state.copyWith(adFree: true);
    await ref.read(sharedPreferencesProvider).setBool(_adFreeKey, true);
  }
}

final infaqProvider = NotifierProvider<InfaqNotifier, InfaqState>(
  InfaqNotifier.new,
);

/// Watched by the app so purchases are heard from launch.
final infaqListenerProvider = Provider<void>((ref) {
  ref.read(infaqProvider.notifier).listen();
});
