import 'dart:convert';
import 'dart:io';

import 'package:dedektif/app.dart';
import 'package:dedektif/core/motion.dart';
import 'package:dedektif/models/case_data.dart';
import 'package:dedektif/services/ads_service.dart';
import 'package:dedektif/services/app_services.dart';
import 'package:dedektif/services/asset_catalog.dart';
import 'package:dedektif/services/audio_service.dart';
import 'package:dedektif/services/case_repository.dart';
import 'package:dedektif/services/progress_service.dart';
import 'package:dedektif/services/purchase_service.dart';
import 'package:dedektif/services/settings_service.dart';
import 'package:dedektif/services/share_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test vakasının ham metni.
String fixtureText() =>
    File('test/fixtures/ornek_vaka.json').readAsStringSync();

CaseData fixtureCase() => CaseRepository.parse(fixtureText());

/// Bellekteki dosyaları sunan sahte asset paketi.
class MemoryBundle extends CachingAssetBundle {
  MemoryBundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final text = files[key];
    if (text == null) throw FlutterError('Yok: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
  }
}

/// Sahte servislerle kurulmuş test uygulaması.
class TestApp {
  TestApp._(this.services, this.audio, this.share);

  final AppServices services;
  final SilentAudioService audio;
  final RecordingShareService share;

  static Future<TestApp> create({
    Map<String, Object> prefs = const {},
    Map<String, String>? caseFiles,
    bool adReward = true,
  }) async {
    Motion.enabled = false;
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    final files = caseFiles ?? {'assets/cases/ornek_vaka.json': fixtureText()};
    final catalog = AssetCatalog(files.keys);
    final progress = ProgressService(sp);
    final audio = SilentAudioService();
    final share = RecordingShareService();
    final services = AppServices(
      catalog: catalog,
      cases: CaseRepository(catalog, MemoryBundle(files)),
      progress: progress,
      settings: SettingsService(sp),
      audio: audio,
      purchases: LocalPurchaseService(progress, allowFakeBuy: true),
      ads: NoAdsService(grantReward: adReward),
      share: share,
    );
    return TestApp._(services, audio, share);
  }

  Widget get widget => DedektifApp(services: services);
}
