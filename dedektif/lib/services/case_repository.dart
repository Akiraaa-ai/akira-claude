import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/case_data.dart';
import 'asset_catalog.dart';

/// assets/cases altındaki tüm vaka JSON'larını okur. Yeni vaka için kod değişikliği gerekmez.
class CaseRepository {
  CaseRepository(this._catalog, [AssetBundle? bundle])
    : _bundle = bundle ?? rootBundle;

  final AssetCatalog _catalog;
  final AssetBundle _bundle;
  List<CaseData>? _cache;

  /// Hatalı dosyalar atlanır ve burada listelenir.
  final List<String> loadErrors = [];

  Future<List<CaseData>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final cases = <CaseData>[];
    for (final path in _catalog.listDir(AssetCatalog.caseDir)) {
      if (!path.endsWith('.json')) continue;
      try {
        final text = await _bundle.loadString(path);
        final data = parse(text);
        final errors = data.validate();
        if (errors.isNotEmpty) {
          loadErrors.add('$path: ${errors.join('; ')}');
          debugPrint('Vaka hatalı, atlandı: $path\n${errors.join('\n')}');
          continue;
        }
        cases.add(data);
      } catch (e) {
        loadErrors.add('$path: $e');
        debugPrint('Vaka okunamadı: $path → $e');
      }
    }
    cases.sort((a, b) => a.order.compareTo(b.order));
    return _cache = cases;
  }

  static CaseData parse(String jsonText) =>
      CaseData.fromJson(jsonDecode(jsonText) as Map<String, dynamic>);
}
