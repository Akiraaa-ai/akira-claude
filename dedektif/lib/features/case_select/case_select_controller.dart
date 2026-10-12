import 'package:flutter/foundation.dart';

import '../../models/case_data.dart';
import '../../services/progress_service.dart';
import '../../services/purchase_service.dart';

enum CaseStatus { locked, fresh, inProgress, solved }

/// Vaka listesindeki bir satırın ekran için hazır hali.
class CaseEntry {
  const CaseEntry(this.data, this.status, this.bestClueCount, [this.bestStars]);

  final CaseData data;
  final CaseStatus status;
  final int? bestClueCount;
  final int? bestStars;
}

/// Vaka listesini yükler, kilit/ilerleme durumunu hesaplar, satın almayı başlatır.
class CaseSelectController extends ChangeNotifier {
  CaseSelectController(this._load, this._progress, this._purchases) {
    _purchases.addListener(notifyListeners);
    _progress.addListener(notifyListeners);
  }

  final Future<List<CaseData>> Function() _load;
  final ProgressService _progress;
  final PurchaseService _purchases;

  List<CaseData>? _cases;
  bool get loading => _cases == null;

  Future<void> load() async {
    _cases = await _load();
    notifyListeners();
  }

  List<CaseEntry> get entries => (_cases ?? const <CaseData>[]).map((c) {
    final p = _progress.caseProgress(c.id);
    final CaseStatus status;
    if (!_purchases.isUnlocked(c.access)) {
      status = CaseStatus.locked;
    } else if (p.solved) {
      status = CaseStatus.solved;
    } else if (p.started) {
      status = CaseStatus.inProgress;
    } else {
      status = CaseStatus.fresh;
    }
    return CaseEntry(c, status, p.bestClueCount, p.bestStars);
  }).toList();

  bool shouldPlayIntro(CaseData c) =>
      c.intro != null && !_progress.caseProgress(c.id).introSeen;

  Future<String?> priceFor(CaseData c) async {
    final pack = c.access.packId;
    return pack == null ? null : _purchases.priceFor(pack);
  }

  Future<PurchaseOutcome> buy(CaseData c) async {
    final pack = c.access.packId;
    if (pack == null) return PurchaseOutcome.unavailable;
    return _purchases.buy(pack);
  }

  @override
  void dispose() {
    _purchases.removeListener(notifyListeners);
    _progress.removeListener(notifyListeners);
    super.dispose();
  }
}
