import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress.dart';

/// Vaka ilerlemesini ve satın alınan paketleri cihazda saklar.
/// Her kayıtta dinleyenlere (ör. vaka listesi) haber verir.
class ProgressService extends ChangeNotifier {
  ProgressService(this._prefs);

  static Future<ProgressService> create() async =>
      ProgressService(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;
  final Map<String, CaseProgress> _cache = {};

  static String _key(String caseId) => 'progress.$caseId';
  static const _packsKey = 'owned_packs';

  CaseProgress caseProgress(String caseId) => _cache.putIfAbsent(caseId, () {
    final raw = _prefs.getString(_key(caseId));
    if (raw == null) return CaseProgress();
    try {
      return CaseProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return CaseProgress();
    }
  });

  Future<void> save(String caseId) async {
    final p = _cache[caseId];
    if (p == null) return;
    await _prefs.setString(_key(caseId), jsonEncode(p.toJson()));
    notifyListeners();
  }

  /// Tüm vakalarda kazanılan en iyi yıldızların toplamı (rütbe için).
  int get totalStars {
    final ids = {
      ..._cache.keys,
      for (final k in _prefs.getKeys())
        if (k.startsWith('progress.')) k.substring('progress.'.length),
    };
    return ids.fold(0, (sum, id) => sum + (caseProgress(id).bestStars ?? 0));
  }

  Set<String> get ownedPacks =>
      (_prefs.getStringList(_packsKey) ?? const []).toSet();

  Future<void> addOwnedPack(String packId) async {
    final packs = ownedPacks..add(packId);
    await _prefs.setStringList(_packsKey, packs.toList());
  }

  /// Tüm vaka ilerlemesini siler (satın alımlar ve ayarlar kalır).
  Future<void> resetAll() async {
    _cache.clear();
    for (final k in _prefs.getKeys().where((k) => k.startsWith('progress.'))) {
      await _prefs.remove(k);
    }
    notifyListeners();
  }
}
