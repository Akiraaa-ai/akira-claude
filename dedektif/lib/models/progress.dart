// Bir vakadaki oyuncu ilerlemesi; cihazda JSON olarak saklanır.

class CaseProgress {
  CaseProgress({
    Set<String>? foundClueIds,
    Set<String>? askedQuestionIds,
    Set<String>? contradictionIds,
    this.wrongAttempts = 0,
    this.hintsUsed = 0,
    this.solved = false,
    this.bestClueCount,
    this.introSeen = false,
  }) : foundClueIds = foundClueIds ?? <String>{},
       askedQuestionIds = askedQuestionIds ?? <String>{},
       contradictionIds = contradictionIds ?? <String>{};

  factory CaseProgress.fromJson(Map<String, dynamic> json) {
    Set<String> set(String k) =>
        ((json[k] as List?) ?? const []).cast<String>().toSet();
    return CaseProgress(
      foundClueIds: set('foundClueIds'),
      askedQuestionIds: set('askedQuestionIds'),
      contradictionIds: set('contradictionIds'),
      wrongAttempts: (json['wrongAttempts'] as num?)?.toInt() ?? 0,
      hintsUsed: (json['hintsUsed'] as num?)?.toInt() ?? 0,
      solved: json['solved'] as bool? ?? false,
      bestClueCount: (json['bestClueCount'] as num?)?.toInt(),
      introSeen: json['introSeen'] as bool? ?? false,
    );
  }

  final Set<String> foundClueIds;
  final Set<String> askedQuestionIds;

  /// Açılan çelişkilerin sorgu kimlikleri.
  final Set<String> contradictionIds;
  int wrongAttempts;
  int hintsUsed;
  bool solved;

  /// Vakanın en az kaç ipucuyla çözüldüğü.
  int? bestClueCount;
  bool introSeen;

  bool get started =>
      foundClueIds.isNotEmpty ||
      askedQuestionIds.isNotEmpty ||
      wrongAttempts > 0;

  /// Yeniden oynamak için soruşturmayı sıfırlar; çözüm ve en iyi skor kalır.
  void resetInvestigation() {
    foundClueIds.clear();
    askedQuestionIds.clear();
    contradictionIds.clear();
    wrongAttempts = 0;
    hintsUsed = 0;
  }

  Map<String, dynamic> toJson() => {
    'foundClueIds': foundClueIds.toList(),
    'askedQuestionIds': askedQuestionIds.toList(),
    'contradictionIds': contradictionIds.toList(),
    'wrongAttempts': wrongAttempts,
    'hintsUsed': hintsUsed,
    'solved': solved,
    'bestClueCount': bestClueCount,
    'introSeen': introSeen,
  };
}
