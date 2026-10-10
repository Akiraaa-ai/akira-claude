import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'monetization_config.dart';

/// Ödüllü reklam. Ekranlar yalnızca bu arayüzü bilir.
abstract class AdsService {
  Future<void> init();

  /// Ödül kazanıldıysa true döner. Reklam yoksa false.
  Future<bool> showRewarded();
}

/// Reklamsız ortam ve testler için. [grantReward] true ise reklam izlenmiş sayılır.
class NoAdsService implements AdsService {
  NoAdsService({this.grantReward = false});

  final bool grantReward;

  @override
  Future<void> init() async {}

  @override
  Future<bool> showRewarded() async => grantReward;
}

/// google_mobile_ads ile ödüllü reklam (şu an test kimlikleriyle).
class AdMobAdsService implements AdsService {
  RewardedAd? _ad;
  bool _loading = false;

  @override
  Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      _load();
    } catch (e) {
      debugPrint('Reklam başlatılamadı: $e');
    }
  }

  void _load() {
    if (_loading || _ad != null) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: MonetizationConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          debugPrint('Ödüllü reklam yüklenemedi: $error');
        },
      ),
    );
  }

  @override
  Future<bool> showRewarded() async {
    final ad = _ad;
    if (ad == null) {
      _load();
      return false;
    }
    _ad = null;
    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _load();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _load();
        if (!done.isCompleted) done.complete(false);
      },
    );
    try {
      await ad.show(onUserEarnedReward: (_, _) => earned = true);
    } catch (e) {
      if (!done.isCompleted) done.complete(false);
    }
    return done.future;
  }
}
