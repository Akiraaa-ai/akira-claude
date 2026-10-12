import 'package:flutter/widgets.dart';

import '../../models/case_data.dart';
import '../../models/progress.dart';
import '../../models/rank.dart';
import '../../services/progress_service.dart';

/// Bir ipucunu bir ifadeye sunmanın sonucu.
enum PresentResult { contradiction, alreadyFound, needsMore, noEffect }

/// Panoda iki ipucunu bağlamanın sonucu.
enum ConnectResult { linked, alreadyLinked, noLink }

/// Suçlama sonucunun ayrıntısı.
class AccusationResult {
  const AccusationResult({
    required this.culpritCorrect,
    required this.reasonCorrect,
    this.evidenceCorrect = true,
    this.stars = 0,
    this.rankUp,
  });

  final bool culpritCorrect;
  final bool reasonCorrect;
  final bool evidenceCorrect;

  /// Çözüldüyse bu oyunun yıldızı.
  final int stars;

  /// Bu çözümle yeni bir rütbeye çıkıldıysa o rütbe.
  final DetectiveRank? rankUp;

  bool get solved => culpritCorrect && reasonCorrect && evidenceCorrect;
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
    _autoUnlock();
    _changed();
    return true;
  }

  /// Koşulu sağlanan ipuçlarını (unlockedByClueIds) deftere ekler.
  void _autoUnlock() {
    var added = true;
    while (added) {
      added = false;
      for (final c in data.clues) {
        if (c.unlockedByClueIds.isNotEmpty &&
            c.unlockedByClueIds.every(isFound) &&
            progress.foundClueIds.add(c.id)) {
          added = true;
        }
      }
    }
  }

  // ---- İpucu hakkı ----

  /// Kalan reklamsız ipucu hakkı (yanlış suçlamalar hakkı eksiltir).
  int get freeHintsLeft {
    final left =
        data.freeHints -
        progress.freeHintsSpent -
        progress.wrongAttempts * data.wrongAnswer.hintPenalty;
    return left < 0 ? 0 : left;
  }

  /// Ücretsiz hak varsa harcar ve true döner; yoksa ipucu reklamla alınmalı.
  bool spendFreeHint() {
    if (freeHintsLeft <= 0) return false;
    progress.freeHintsSpent++;
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
    if (con == null || !con.clueIds.contains(clueId)) {
      return PresentResult.noEffect;
    }
    if (progress.contradictionIds.contains(questionId)) {
      return PresentResult.alreadyFound;
    }
    // Birden çok kanıt gerekiyorsa hepsi defterde olmalı.
    if (!con.clueIds.every(isFound)) return PresentResult.needsMore;
    progress.contradictionIds.add(questionId);
    final unlock = con.unlocksClueId;
    if (unlock != null) progress.foundClueIds.add(unlock);
    _autoUnlock();
    _changed();
    return PresentResult.contradiction;
  }

  /// Defterde gösterilecek açılmış çelişkiler.
  List<Interrogation> get foundContradictions => data.interrogations
      .where((q) => progress.contradictionIds.contains(q.id))
      .toList();

  // ---- Delil panosu ----

  /// Panoya iğnelenen ipuçları (bulunanlar).
  List<Clue> get boardClues => foundClues;

  List<BoardConnection> get foundConnections => data.connections
      .where((c) => progress.connectionIds.contains(c.id))
      .toList();

  /// Son kurulan bağlantı (ekranda çıkarımı göstermek için).
  BoardConnection? lastConnection;

  /// Oyuncu iki ipucunu iple bağladı.
  ConnectResult connect(String a, String b) {
    for (final c in data.connections) {
      if (!c.matches(a, b)) continue;
      if (!progress.connectionIds.add(c.id)) return ConnectResult.alreadyLinked;
      lastConnection = c;
      _changed();
      return ConnectResult.linked;
    }
    return ConnectResult.noLink;
  }

  /// Kartın panodaki yeri (0..1). Kayıt yoksa null.
  Offset? boardPosition(String clueId) {
    final p = progress.boardPositions[clueId];
    return p == null || p.length < 2 ? null : Offset(p[0], p[1]);
  }

  void moveBoardCard(String clueId, Offset pos) {
    progress.boardPositions[clueId] = [pos.dx, pos.dy];
    _changed();
  }

  // ---- Zaman çizelgesi ----

  /// Gerekli ipuçları bulunduğu için oyuncunun görebildiği olay kartları.
  List<TimelineEvent> get timelineEvents => [
    for (final e in data.timeline?.events ?? const <TimelineEvent>[])
      if (e.requiresClueIds.every(isFound)) e,
  ];

  int get lockedTimelineEvents =>
      (data.timeline?.events.length ?? 0) - timelineEvents.length;

  String? placementOf(String eventId) => progress.timelinePlacements[eventId];

  /// Kartı bir saate yerleştirir; [slot] null ise kartı geri alır.
  void placeEvent(String eventId, String? slot) {
    if (progress.timelineSolved) return;
    if (slot == null) {
      progress.timelinePlacements.remove(eventId);
    } else {
      progress.timelinePlacements[eventId] = slot;
    }
    _changed();
  }

  /// Yerleştirilen kartlardan kaç tanesi doğru saatte. Hepsi açık ve doğruysa çizelge çözülür.
  int checkTimeline() {
    final events = timelineEvents;
    final correct = events.where((e) => placementOf(e.id) == e.time).length;
    if (lockedTimelineEvents == 0 &&
        events.isNotEmpty &&
        correct == events.length) {
      progress.timelineSolved = true;
      _changed();
    }
    return correct;
  }

  // ---- Suçlama ----

  /// İpucu yardımı + yanlış suçlama cezası; yıldızı belirler.
  int get penaltyTotal => progress.hintsUsed + progress.penaltyPoints;

  int get currentStars => data.stars.starsFor(penaltyTotal);

  AccusationResult accuse(
    String suspectId,
    String? reasonId, [
    Set<String> evidence = const {},
  ]) {
    final s = data.solution;
    final culpritCorrect = suspectId == s.culpritId;
    final reasonCorrect =
        s.reasonOptions.isEmpty || reasonId == s.correctReasonId;
    final rule = s.evidence;
    final evidenceCorrect =
        rule == null ||
        (evidence.length == rule.pick && evidence.every(rule.clueIds.contains));
    var stars = 0;
    DetectiveRank? rankUp;
    if (culpritCorrect && reasonCorrect && evidenceCorrect) {
      final rankBefore = DetectiveRank.forStars(_progressService.totalStars);
      progress.solved = true;
      final best = progress.bestClueCount;
      if (best == null || foundClueCount < best) {
        progress.bestClueCount = foundClueCount;
      }
      stars = currentStars;
      if ((progress.bestStars ?? 0) < stars) progress.bestStars = stars;
      final rankAfter = DetectiveRank.forStars(_progressService.totalStars);
      if (rankAfter != rankBefore) rankUp = rankAfter;
    } else {
      progress.wrongAttempts++;
      progress.penaltyPoints += data.wrongAnswer.penaltyPoints;
    }
    final result = AccusationResult(
      culpritCorrect: culpritCorrect,
      reasonCorrect: reasonCorrect,
      evidenceCorrect: evidenceCorrect,
      stars: stars,
      rankUp: rankUp,
    );
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
    lastConnection = null;
    _changed();
  }

  /// Paylaşım metni.
  String shareText() {
    final stars = lastAccusation?.stars ?? progress.bestStars ?? 0;
    return '"${data.title}" vakasını $foundClueCount/$totalClueCount ipucuyla çözdüm! '
        '${'★' * stars}${'☆' * (3 - stars)} '
        '${progress.wrongAttempts == 0 ? 'İlk denemede. ' : ''}#Dedektif';
  }

  void _changed() {
    _progressService.save(data.id);
    notifyListeners();
  }
}
