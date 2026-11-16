import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/services/distribution_channel.dart';
import 'dahlunas_client.dart';
import 'dahlunas_config.dart';
import 'dahlunas_unlock.dart';

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
  static Uri get dahlunas => DahlunasConfig.shopUri;
}

enum InfaqError {
  /// The store can't be reached or has no infaq products.
  storeUnavailable,

  /// A purchase or restore failed in the store.
  purchaseFailed,

  /// The typed code is not a valid Bedug unlock code.
  codeInvalid,

  /// Dahlunas rejected the code or activation.
  codeRejected,

  /// The code has moved too often; show [DahlunasConfig.supportEmail].
  codeMoveLimit,

  /// Dahlunas is busy; keep the current state and try later.
  codeBusy,
}

class InfaqState {
  /// Set by any infaq, bought, restored or activated; the app thanks the giver.
  final bool given;

  /// The store's products, cheapest first; empty until [InfaqNotifier.load].
  final List<ProductDetails> products;
  final bool loading;

  /// A purchase is open in the store sheet or awaits payment.
  final bool pending;

  /// A Dahlunas code is being submitted.
  final bool redeeming;

  /// The last purchase went through; the page says thank you.
  final bool thanked;

  /// Moves still allowed for the stored Dahlunas code, when known.
  final int? movesLeft;

  /// True after a weekly check found the code on another device.
  final bool codeMovedAway;

  final InfaqError? error;

  const InfaqState({
    this.given = false,
    this.products = const [],
    this.loading = false,
    this.pending = false,
    this.redeeming = false,
    this.thanked = false,
    this.movesLeft,
    this.codeMovedAway = false,
    this.error,
  });

  InfaqState copyWith({
    bool? given,
    List<ProductDetails>? products,
    bool? loading,
    bool? pending,
    bool? redeeming,
    bool? thanked,
    int? Function()? movesLeft,
    bool? codeMovedAway,
    InfaqError? Function()? error,
  }) => InfaqState(
    given: given ?? this.given,
    products: products ?? this.products,
    loading: loading ?? this.loading,
    pending: pending ?? this.pending,
    redeeming: redeeming ?? this.redeeming,
    thanked: thanked ?? this.thanked,
    movesLeft: movesLeft != null ? movesLeft() : this.movesLeft,
    codeMovedAway: codeMovedAway ?? this.codeMovedAway,
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

/// Override in tests to fake Dahlunas HTTP.
final dahlunasClientProvider = Provider<DahlunasClient>(
  (ref) => DahlunasConfig.client(),
);

// Named when an infaq turned ads off; kept so givers stay recognised.
const _givenKey = 'infaq_ad_free';
const _installIdKey = 'infaq_install_id';
const _codeKey = 'infaq_dahlunas_code';
const _activationKey = 'infaq_dahlunas_activation';
const _movesKey = 'infaq_dahlunas_moves_left';
const _lastCheckKey = 'infaq_dahlunas_last_check';

const _week = Duration(days: 7);

class InfaqNotifier extends Notifier<InfaqState> {
  StreamSubscription<List<PurchaseDetails>>? _purchases;

  @override
  InfaqState build() {
    ref.onDispose(() => _purchases?.cancel());
    final prefs = ref.read(sharedPreferencesProvider);
    return InfaqState(
      given: prefs.getBool(_givenKey) ?? false,
      movesLeft: prefs.getInt(_movesKey),
    );
  }

  InAppPurchase? get _store => ref.read(infaqStoreProvider);

  bool get _usesCodes {
    final channel = ref.read(distributionChannelProvider);
    return !channel.usesStoreBilling && DahlunasConfig.codesEnabled;
  }

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

  /// Offline activation check and a weekly online check for Dahlunas codes.
  Future<void> syncDahlunas() async {
    if (!_usesCodes) return;
    await _installId();
    final prefs = ref.read(sharedPreferencesProvider);
    final code = prefs.getString(_codeKey);
    final activation = prefs.getString(_activationKey);
    if (code == null || activation == null) return;

    final codeId = DahlunasUnlock.codeIdOf(code);
    if (codeId == null) {
      await _clearCode();
      return;
    }
    final installId = await _installId();
    final ok = await DahlunasConfig.activation.verify(
      input: activation,
      installId: installId,
      codeId: codeId,
    );
    if (ok == null) {
      await _clearCode();
      return;
    }

    final last = prefs.getInt(_lastCheckKey);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    if (last != null && now - last < _week.inMilliseconds) return;

    final result = await ref
        .read(dahlunasClientProvider)
        .activate(code: code, installId: installId, move: false);
    switch (result) {
      case DahlunasActivationOk(:final activation, :final movesLeft):
        final verified = await DahlunasConfig.activation.verify(
          input: activation,
          installId: installId,
          codeId: codeId,
        );
        if (verified == null) return;
        await prefs.setString(_activationKey, verified);
        await prefs.setInt(_movesKey, movesLeft);
        await prefs.setInt(_lastCheckKey, now);
        state = state.copyWith(
          movesLeft: () => movesLeft,
          codeMovedAway: false,
        );
      case DahlunasActivationError(:final code, :final movesLeft):
        if (code == 'moved') {
          await _clearCode(movedAway: true);
          if (movesLeft != null) {
            state = state.copyWith(movesLeft: () => movesLeft);
          }
        }
      // busy / network / invalid: keep the current offline state.
    }
  }

  /// Loads the products for the infaq page.
  Future<void> load() async {
    final store = _store;
    if (store == null) {
      await syncDahlunas();
      return;
    }
    if (state.loading) return;
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

  /// Redeems a Dahlunas unlock code on a direct build (`move: true`).
  Future<void> redeemCode(String input) async {
    if (!_usesCodes || state.redeeming) return;
    state = state.copyWith(
      redeeming: true,
      error: () => null,
      codeMovedAway: false,
    );
    final canonical = await DahlunasConfig.unlock.verify(input);
    if (canonical == null) {
      state = state.copyWith(
        redeeming: false,
        error: () => InfaqError.codeInvalid,
      );
      return;
    }
    final codeId = DahlunasUnlock.codeIdOf(canonical);
    if (codeId == null) {
      state = state.copyWith(
        redeeming: false,
        error: () => InfaqError.codeInvalid,
      );
      return;
    }
    final installId = await _installId();
    final result = await ref
        .read(dahlunasClientProvider)
        .activate(code: canonical, installId: installId, move: true);
    switch (result) {
      case DahlunasActivationOk(:final activation, :final movesLeft):
        final verified = await DahlunasConfig.activation.verify(
          input: activation,
          installId: installId,
          codeId: codeId,
        );
        if (verified == null) {
          state = state.copyWith(
            redeeming: false,
            error: () => InfaqError.codeRejected,
          );
          return;
        }
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setString(_codeKey, canonical);
        await prefs.setString(_activationKey, verified);
        await prefs.setInt(_movesKey, movesLeft);
        await prefs.setInt(
          _lastCheckKey,
          DateTime.now().toUtc().millisecondsSinceEpoch,
        );
        await _setGiven();
        state = state.copyWith(
          redeeming: false,
          thanked: true,
          movesLeft: () => movesLeft,
          codeMovedAway: false,
          error: () => null,
        );
      case DahlunasActivationError(:final code, :final movesLeft):
        state = state.copyWith(
          redeeming: false,
          movesLeft: movesLeft != null ? () => movesLeft : null,
          error: () => switch (code) {
            'move_limit' => InfaqError.codeMoveLimit,
            'busy' || 'network' => InfaqError.codeBusy,
            _ => InfaqError.codeRejected,
          },
        );
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(pending: true);
        case PurchaseStatus.purchased:
          await _setGiven();
          state = state.copyWith(pending: false, thanked: true);
        case PurchaseStatus.restored:
          await _setGiven();
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

  Future<String> _installId() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final existing = prefs.getString(_installIdKey);
    if (existing != null && RegExp(r'^[0-9a-f]{32}$').hasMatch(existing)) {
      return existing;
    }
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final id = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')]
        .join();
    await prefs.setString(_installIdKey, id);
    return id;
  }

  Future<void> _setGiven() async {
    state = state.copyWith(given: true);
    await ref.read(sharedPreferencesProvider).setBool(_givenKey, true);
  }

  Future<void> _clearCode({bool movedAway = false}) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_codeKey);
    await prefs.remove(_activationKey);
    await prefs.remove(_movesKey);
    await prefs.remove(_lastCheckKey);
    await prefs.setBool(_givenKey, false);
    state = state.copyWith(
      given: false,
      thanked: false,
      movesLeft: () => null,
      codeMovedAway: movedAway,
    );
  }
}

final infaqProvider = NotifierProvider<InfaqNotifier, InfaqState>(
  InfaqNotifier.new,
);

/// Watched by the app so purchases are heard from launch, and Dahlunas
/// codes are checked offline (and weekly while online) on direct builds.
final infaqListenerProvider = Provider<void>((ref) {
  ref.read(infaqProvider.notifier).listen();
  unawaited(ref.read(infaqProvider.notifier).syncDahlunas());
});
