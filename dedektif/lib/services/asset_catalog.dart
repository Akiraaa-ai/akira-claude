import 'package:flutter/services.dart';

/// Uygulamaya paketlenmiş dosyaların listesi. Görsel/ses var mı diye bakmak için kullanılır,
/// böylece eksik dosya hata vermeden yer tutucuya ya da sessizliğe düşer.
class AssetCatalog {
  AssetCatalog(Iterable<String> assets) : _assets = assets.toSet();

  static const imageDir = 'assets/images/';
  static const audioDir = 'assets/audio/';
  static const caseDir = 'assets/cases/';
  static const imageExtensions = ['png', 'jpg', 'jpeg', 'webp'];
  static const audioExtensions = ['mp3', 'ogg', 'm4a', 'wav'];

  final Set<String> _assets;

  static Future<AssetCatalog> load([AssetBundle? bundle]) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(
        bundle ?? rootBundle,
      );
      return AssetCatalog(manifest.listAssets());
    } catch (_) {
      return AssetCatalog(const []);
    }
  }

  List<String> listDir(String dir) =>
      _assets.where((a) => a.startsWith(dir)).toList()..sort();

  /// `assets/images/<isim>.<uzantı>` varsa yolunu döner.
  String? image(String? name) => _find(imageDir, name, imageExtensions);

  /// `assets/audio/<isim>.<uzantı>` varsa yolunu döner.
  String? audio(String? name) => _find(audioDir, name, audioExtensions);

  String? _find(String dir, String? name, List<String> exts) {
    if (name == null || name.isEmpty) return null;
    for (final ext in exts) {
      final path = '$dir$name.$ext';
      if (_assets.contains(path)) return path;
    }
    return null;
  }
}
