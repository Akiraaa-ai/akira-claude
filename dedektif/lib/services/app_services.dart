import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads_service.dart';
import 'asset_catalog.dart';
import 'audio_service.dart';
import 'case_repository.dart';
import 'progress_service.dart';
import 'purchase_service.dart';
import 'settings_service.dart';
import 'share_service.dart';

/// Uygulamanın tüm servisleri tek yerde. Testlerde sahte servislerle kurulur.
class AppServices {
  AppServices({
    required this.catalog,
    required this.cases,
    required this.progress,
    required this.settings,
    required this.audio,
    required this.purchases,
    required this.ads,
    required this.share,
  });

  final AssetCatalog catalog;
  final CaseRepository cases;
  final ProgressService progress;
  final SettingsService settings;
  final AudioService audio;
  final PurchaseService purchases;
  final AdsService ads;
  final ShareService share;

  /// Gerçek cihaz kurulumu.
  static Future<AppServices> createDefault() async {
    final prefs = await SharedPreferences.getInstance();
    final catalog = await AssetCatalog.load();
    final progress = ProgressService(prefs);
    final settings = SettingsService(prefs);
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final services = AppServices(
      catalog: catalog,
      cases: CaseRepository(catalog),
      progress: progress,
      settings: settings,
      audio: AudioPlayersService(catalog, settings),
      purchases: isAndroid
          ? StorePurchaseService(progress)
          : LocalPurchaseService(progress),
      ads: isAndroid
          ? AdMobAdsService()
          : NoAdsService(grantReward: kDebugMode),
      share: SystemShareService(),
    );
    // Mağaza ve reklam açılışı bekletmesin.
    services.purchases.init();
    services.ads.init();
    return services;
  }
}
