import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/case_data.dart';
import 'monetization_config.dart';
import 'progress_service.dart';

enum PurchaseOutcome { success, cancelled, unavailable, error }

/// Vaka paketlerinin satın alınması. Ekranlar yalnızca bu arayüzü bilir.
abstract class PurchaseService extends ChangeNotifier {
  Set<String> get ownedPacks;

  /// Mağaza bu cihazda kullanılabilir mi.
  bool get storeAvailable;

  bool isUnlocked(CaseAccess access) =>
      access.free ||
      (access.packId != null && ownedPacks.contains(access.packId));

  Future<void> init();
  Future<String?> priceFor(String packId);
  Future<PurchaseOutcome> buy(String packId);
  Future<void> restore();
}

/// Mağazasız ortam ve testler için: satın alma anında başarılı sayılır (yalnızca debug).
class LocalPurchaseService extends PurchaseService {
  LocalPurchaseService(this._progress, {this.allowFakeBuy = kDebugMode});

  final ProgressService _progress;
  final bool allowFakeBuy;

  @override
  Set<String> get ownedPacks => _progress.ownedPacks;
  @override
  bool get storeAvailable => allowFakeBuy;
  @override
  Future<void> init() async {}
  @override
  Future<String?> priceFor(String packId) async => null;

  @override
  Future<PurchaseOutcome> buy(String packId) async {
    if (!allowFakeBuy) return PurchaseOutcome.unavailable;
    await _progress.addOwnedPack(packId);
    notifyListeners();
    return PurchaseOutcome.success;
  }

  @override
  Future<void> restore() async {}
}

/// Google Play Faturalandırma ile çalışan uygulama (in_app_purchase).
class StorePurchaseService extends PurchaseService {
  StorePurchaseService(this._progress);

  final ProgressService _progress;
  final InAppPurchase _iap = InAppPurchase.instance;
  final Map<String, ProductDetails> _products = {};
  final Map<String, Completer<PurchaseOutcome>> _pending = {};
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _available = false;

  @override
  Set<String> get ownedPacks => _progress.ownedPacks;
  @override
  bool get storeAvailable => _available;

  @override
  Future<void> init() async {
    try {
      _available = await _iap.isAvailable();
      if (!_available) return;
      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) {
          debugPrint('Satın alma akışı hatası: $e');
        },
      );
    } catch (e) {
      _available = false;
      debugPrint('Mağaza başlatılamadı: $e');
    }
  }

  Future<ProductDetails?> _product(String packId) async {
    final id = MonetizationConfig.productIdForPack(packId);
    final cached = _products[id];
    if (cached != null) return cached;
    final resp = await _iap.queryProductDetails({id});
    for (final p in resp.productDetails) {
      _products[p.id] = p;
    }
    return _products[id];
  }

  @override
  Future<String?> priceFor(String packId) async {
    if (!_available) return null;
    try {
      return (await _product(packId))?.price;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PurchaseOutcome> buy(String packId) async {
    if (!_available) return PurchaseOutcome.unavailable;
    try {
      final product = await _product(packId);
      if (product == null) return PurchaseOutcome.unavailable;
      final completer = Completer<PurchaseOutcome>();
      _pending[product.id] = completer;
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      return await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => PurchaseOutcome.error,
      );
    } catch (e) {
      debugPrint('Satın alma hatası: $e');
      return PurchaseOutcome.error;
    }
  }

  @override
  Future<void> restore() async {
    if (!_available) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Geri yükleme hatası: $e');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      PurchaseOutcome? outcome;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Not: Gerçek yayında makbuz doğrulaması sunucuda yapılmalı (bkz. docs/yayin.md).
          await _progress.addOwnedPack(p.productID);
          outcome = PurchaseOutcome.success;
          notifyListeners();
        case PurchaseStatus.canceled:
          outcome = PurchaseOutcome.cancelled;
        case PurchaseStatus.error:
          outcome = PurchaseOutcome.error;
        case PurchaseStatus.pending:
          break;
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
      if (outcome != null) {
        _pending.remove(p.productID)?.complete(outcome);
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
