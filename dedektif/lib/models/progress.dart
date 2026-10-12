// Bir vakadaki oyuncu ilerlemesi; cihazda JSON olarak saklanır.

class CaseProgress {
  CaseProgress({
    Set<String>? foundClueIds,
    Set<String>? askedQuestionIds,
    Set<String>? contradictionIds,
    Set<String>? connectionIds,
    Map<String, List<double>>? boardPositions,
    Map<String, String>? timelinePlacements,
    this.timelineSolved = false,
    this.penaltyPoints = 0,
    this.bestStars,
    this.wrongAttempts = 0,
    this.hintsUsed = 0,
    this.freeHintsSpent = 0,
    this.solved = false,
    this.bestClueCount,
    this.introSeen = false,
  }) : foundClueIds = foundClueIds ?? <String>{},
       askedQuestionIds = askedQuestionIds ?? <String>{},
       contradictionIds = contradictionIds ?? <String>{},
       connectionIds = connectionIds ?? <String>{},
       boardPositions = boardPositions ?? <String, List<double>>{},
       timelinePlacements = timelinePlacements ?? <String, String>{};

  factory CaseProgress.fromJson(Map<String, dynamic> json) {
    Set<String> set(String k) =>
        ((json[k] as List?) ?? const []).cast<String>().toSet();
    return CaseProgress(
      foundClueIds: set('foundClueIds'),
      askedQuestionIds: set('askedQuestionIds'),
      contradictionIds: set('contradictionIds'),
      connectionIds: set('connectionIds'),
      boardPositions: {
        for (final e in ((json['boardPositions'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as List)
              .map((v) => (v as num).toDouble())
              .toList(),
      },
      timelinePlacements: ((json['timelinePlacements'] as Map?) ?? const {})
          .cast<String, String>(),
      timelineSolved: json['timelineSolved'] as bool? ?? false,
      penaltyPoints: (json['penaltyPoints'] as num?)?.toInt() ?? 0,
      bestStars: (json['bestStars'] as num?)?.toInt(),
      wrongAttempts: (json['wrongAttempts'] as num?)?.toInt() ?? 0,
      hintsUsed: (json['hintsUsed'] as num?)?.toInt() ?? 0,
      freeHintsSpent: (json['freeHintsSpent'] as num?)?.toInt() ?? 0,
      solved: json['solved'] as bool? ?? false,
      bestClueCount: (json['bestClueCount'] as num?)?.toInt(),
      introSeen: json['introSeen'] as bool? ?? false,
    );
  }

  final Set<String> foundClueIds;
  final Set<String> askedQuestionIds;

  /// Açılan çelişkilerin sorgu kimlikleri.
  final Set<String> contradictionIds;

  /// Delil panosunda kurulan doğru bağlantılar.
  final Set<String> connectionIds;

  /// Panodaki kartların konumu (0..1, sol üst köşe).
  final Map<String, List<double>> boardPositions;

  /// Zaman çizelgesi: olay kimliği → oyuncunun seçtiği saat.
  final Map<String, String> timelinePlacements;
  bool timelineSolved;

  /// Yanlış suçlamalardan gelen ceza puanı.
  int penaltyPoints;

  /// Vakanın en iyi yıldızı (1–3).
  int? bestStars;
  int wrongAttempts;
  int hintsUsed;

  /// Harcanan reklamsız ipucu hakkı.
  int freeHintsSpent;
  bool solved;

  /// Vakanın en az kaç ipucuyla çözüldüğü.
  int? bestClueCount;
  bool introSeen;

  bool get started =>
      foundClueIds.isNotEmpty ||
      askedQuestionIds.isNotEmpty ||
      wrongAttempts > 0 ||
      connectionIds.isNotEmpty;

  /// Yeniden oynamak için soruşturmayı sıfırlar; çözüm ve en iyi skor kalır.
  void resetInvestigation() {
    foundClueIds.clear();
    askedQuestionIds.clear();
    contradictionIds.clear();
    connectionIds.clear();
    boardPositions.clear();
    timelinePlacements.clear();
    timelineSolved = false;
    penaltyPoints = 0;
    wrongAttempts = 0;
    hintsUsed = 0;
    freeHintsSpent = 0;
  }

  Map<String, dynamic> toJson() => {
    'foundClueIds': foundClueIds.toList(),
    'askedQuestionIds': askedQuestionIds.toList(),
    'contradictionIds': contradictionIds.toList(),
    'connectionIds': connectionIds.toList(),
    'boardPositions': boardPositions,
    'timelinePlacements': timelinePlacements,
    'timelineSolved': timelineSolved,
    'penaltyPoints': penaltyPoints,
    'bestStars': bestStars,
    'wrongAttempts': wrongAttempts,
    'hintsUsed': hintsUsed,
    'freeHintsSpent': freeHintsSpent,
    'solved': solved,
    'bestClueCount': bestClueCount,
    'introSeen': introSeen,
  };
}
