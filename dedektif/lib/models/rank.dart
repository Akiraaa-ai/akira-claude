// Dedektif rütbeleri: toplam yıldızla yükselir. Vakadan bağımsızdır.

class DetectiveRank {
  const DetectiveRank(this.title, this.minStars);

  final String title;
  final int minStars;

  static const all = [
    DetectiveRank('Çaylak', 0),
    DetectiveRank('Dedektif', 3),
    DetectiveRank('Komiser Yardımcısı', 7),
    DetectiveRank('Komiser', 12),
    DetectiveRank('Başkomiser', 18),
  ];

  static DetectiveRank forStars(int stars) =>
      all.lastWhere((r) => stars >= r.minStars);

  /// Bir sonraki rütbe; en üstteyse null.
  static DetectiveRank? nextAfter(DetectiveRank r) {
    final i = all.indexOf(r);
    return i + 1 < all.length ? all[i + 1] : null;
  }
}
