import 'package:flutter/foundation.dart';

import '../../models/case_data.dart';
import '../../models/progress.dart';
import '../../services/progress_service.dart';

/// Bir ipucunu bir ifadeye sunmanın sonucu.
enum PresentResult { contradiction, alreadyFound, noEffect }

/// Suçlama sonucunun ayrıntısı.
class AccusationResult {
  const AccusationResult({
    required this.culpritCorrect,
    required this.reasonCorrect,
  });

  final bool culpritCorrect;
  final bool reasonCorrect;
  bool get solved => culpritCorrect && reasonCorrect;
}

/// Bir vakanın oyun mantığı. Ekranlar yalnızca bunu okur ve olayları buraya iletir.
class GameController extends ChangeNotifier {
  GameController(this.data, this._progressService)
    : progress = _progressService.caseProgress(data.id);

  final CaseData data;
  final ProgressService _progressService;
  final CaseProgress progress;

  /// Son suçlamanın sonucu (sonuç ekranı için).
  AccusationResult? lastAccusation;

  // ---- İpuçları ----

  bool isFound(String clueId) => progress.foundClueIds.contains(clueId);

  List<Clue> cluesInScene(String sceneId) =>
      data.clues.where((c) => c.sceneId == sceneId).toList();

  int foundInScene(String sceneId) =>
      cluesInScene(sceneId).where((c) => isFound(c.id)).length;

  /// Defterde görünen ipuçları (bulunma sırasıyla değil, vaka sırasıyla).
  List<Clue> get foundClues => data.clues.where((c) => isFound(c.id)).toList();

  int get foundClueCount => progress.foundClueIds.length;
  int get totalClueCount => data.clues.length;

  /// Sahnede ipucuna dokunuldu. Yeni bulunduysa true döner.
  bool collectClue(String clueId) {
    if (!progress.foundClueIds.add(clueId)) return false;
    _changed();
    return true;
  }

  /// Ödüllü reklam sonrası ipucu: sahnede bulunmamış ilk ipucunu döner (işaretlemez).
  Clue? hintFor(String sceneId) {
    for (final c in cluesInScene(sceneId)) {
      if (!isFound(c.id)) {
        progress.hintsUsed++;
        _changed();
        return c;
      }
    }
    return null;
  }

  // ---- Sorgu ----

  List<Interrogation> questionsFor(String suspectId) =>
      data.interrogations.where((q) => q.suspectId == suspectId).toList();

  /// Gerekli ipuçları bulunduysa soru sorulabilir.
  bool isAvailable(Interrogation q) => q.requiresClueIds.every(isFound);

  bool isAsked(String questionId) =>
      progress.askedQuestionIds.contains(questionId);

  bool hasContradiction(String questionId) =>
      progress.contradictionIds.contains(questionId);

  /// Bu şüpheliye sorulabilecek ama henüz sorulmamış soru var mı.
  bool hasNewQuestions(String suspectId) =>
      questionsFor(suspectId).any((q) => isAvailable(q) && !isAsked(q.id));

  void ask(String questionId) {
    if (progress.askedQuestionIds.add(questionId)) _changed();
  }

  /// Oyuncu bir ifadeye karşı defterinden ipucu sundu.
  PresentResult presentClue(String questionId, String clueId) {
    final q = data.interrogation(questionId);
    final con = q.contradiction;
    if (con == null || con.clueId != clueId) return PresentResult.noEffect;
    if (!progress.contradictionIds.add(questionId)) {
      return PresentResult.alreadyFound;
    }
    final unlock = con.unlocksClueId;
    if (unlock != null) progress.foundClueIds.add(unlock);
    _changed();
    return PresentResult.contradiction;
  }

  /// Defterde gösterilecek açılmış çelişkiler.
  List<Interrogation> get foundContradictions => data.interrogations
      .where((q) => progress.contradictionIds.contains(q.id))
      .toList();

  // ---- Suçlama ----

  AccusationResult accuse(String suspectId, String? reasonId) {
    final s = data.solution;
    final culpritCorrect = suspectId == s.culpritId;
    final reasonCorrect =
        s.reasonOptions.isEmpty || reasonId == s.correctReasonId;
    final result = AccusationResult(
      culpritCorrect: culpritCorrect,
      reasonCorrect: reasonCorrect,
    );
    if (result.solved) {
      progress.solved = true;
      final best = progress.bestClueCount;
      if (best == null || foundClueCount < best) {
        progress.bestClueCount = foundClueCount;
      }
    } else {
      progress.wrongAttempts++;
    }
    lastAccusation = result;
    _changed();
    return result;
  }

  void markIntroSeen() {
    if (progress.introSeen) return;
    progress.introSeen = true;
    _changed();
  }

  /// Vakayı baştan oynamak için soruşturmayı sıfırlar.
  void restart() {
    progress.resetInvestigation();
    lastAccusation = null;
    _changed();
  }

  /// Paylaşım metni.
  String shareText() =>
      '"${data.title}" vakasını $foundClueCount/$totalClueCount ipucuyla çözdüm! '
      '${progress.wrongAttempts == 0 ? 'İlk denemede. ' : ''}#Dedektif';

  void _changed() {
    _progressService.save(data.id);
    notifyListeners();
  }
}
