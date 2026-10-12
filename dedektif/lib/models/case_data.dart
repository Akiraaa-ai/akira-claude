// Vaka verisinin Dart karşılığı. Tüm metinler JSON'dan gelir, burada vakaya özel hiçbir şey yok.

/// JSON okunurken hatalı alan bulunursa fırlatılır.
class CaseFormatException implements Exception {
  CaseFormatException(this.message);
  final String message;

  @override
  String toString() => 'CaseFormatException: $message';
}

T _req<T>(Map<String, dynamic> json, String key, String where) {
  final value = json[key];
  if (value is T) return value;
  throw CaseFormatException('$where: "$key" alanı eksik ya da hatalı');
}

String? _optStr(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  throw CaseFormatException('"$key" metin olmalı');
}

List<Map<String, dynamic>> _list(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return const [];
  if (value is List) return value.cast<Map<String, dynamic>>();
  throw CaseFormatException('"$key" liste olmalı');
}

List<String> _strList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return const [];
  if (value is List) return value.cast<String>();
  throw CaseFormatException('"$key" metin listesi olmalı');
}

/// Bir vakanın tamamı.
class CaseData {
  CaseData({
    required this.id,
    required this.order,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.briefing,
    required this.coverImage,
    required this.access,
    required this.music,
    required this.intro,
    required this.scenes,
    required this.suspects,
    required this.clues,
    required this.interrogations,
    required this.solution,
    required this.wrongAnswer,
    this.freeHints = 0,
    this.connections = const [],
    this.timeline,
    this.stars = const StarRule(),
  });

  factory CaseData.fromJson(Map<String, dynamic> json) {
    final id = _req<String>(json, 'id', 'vaka');
    final introJson = json['intro'];
    return CaseData(
      id: id,
      order: (json['order'] as num?)?.toInt() ?? 0,
      title: _req<String>(json, 'title', id),
      subtitle: _optStr(json, 'subtitle') ?? '',
      summary: _optStr(json, 'summary') ?? '',
      briefing: _optStr(json, 'briefing') ?? '',
      coverImage: _optStr(json, 'coverImage') ?? '${id}_kapak',
      access: CaseAccess.fromJson(
        (json['access'] as Map<String, dynamic>?) ?? const {'free': true},
      ),
      music: CaseMusic.fromJson(
        (json['music'] as Map<String, dynamic>?) ?? const {},
      ),
      intro: introJson is Map<String, dynamic>
          ? IntroData.fromJson(introJson)
          : null,
      scenes: _list(json, 'scenes').map(Scene.fromJson).toList(),
      suspects: _list(json, 'suspects').map(Suspect.fromJson).toList(),
      clues: _list(json, 'clues').map(Clue.fromJson).toList(),
      interrogations: _list(
        json,
        'interrogations',
      ).map(Interrogation.fromJson).toList(),
      solution: Solution.fromJson(
        _req<Map<String, dynamic>>(json, 'solution', id),
      ),
      freeHints: (json['freeHints'] as num?)?.toInt() ?? 0,
      wrongAnswer: WrongAnswer.fromJson(
        _req<Map<String, dynamic>>(json, 'wrongAnswer', id),
      ),
      connections: _list(
        json,
        'connections',
      ).map(BoardConnection.fromJson).toList(),
      timeline: json['timeline'] is Map<String, dynamic>
          ? TimelineData.fromJson(json['timeline'] as Map<String, dynamic>)
          : null,
      stars: json['stars'] is Map<String, dynamic>
          ? StarRule.fromJson(json['stars'] as Map<String, dynamic>)
          : const StarRule(),
    );
  }

  final String id;
  final int order;
  final String title;
  final String subtitle;
  final String summary;
  final String briefing;
  final String coverImage;
  final CaseAccess access;
  final CaseMusic music;
  final IntroData? intro;
  final List<Scene> scenes;
  final List<Suspect> suspects;
  final List<Clue> clues;
  final List<Interrogation> interrogations;
  final Solution solution;
  final WrongAnswer wrongAnswer;

  /// Reklamsız kullanılabilen ipucu hakkı. Bitince ipucu ödüllü reklamla alınır.
  final int freeHints;

  /// Delil panosunda iple bağlanınca çıkarım açan ipucu çiftleri.
  final List<BoardConnection> connections;

  /// Oyuncunun kurduğu zaman çizelgesi (isteğe bağlı).
  final TimelineData? timeline;

  /// Yıldız eşikleri.
  final StarRule stars;

  /// Bağlantının panoda gösterilen çıkarım metni.
  String connectionText(BoardConnection c) {
    final step = c.deductionStep;
    if (c.text != null) return c.text!;
    if (step != null && step >= 1 && step <= solution.deductionChain.length) {
      return solution.deductionChain[step - 1];
    }
    return '';
  }

  Suspect suspect(String id) => suspects.firstWhere((s) => s.id == id);
  Clue clue(String id) => clues.firstWhere((c) => c.id == id);
  Scene scene(String id) => scenes.firstWhere((s) => s.id == id);
  Interrogation interrogation(String id) =>
      interrogations.firstWhere((q) => q.id == id);

  /// Sahnede dokunularak bulunabilen ipuçları.
  List<Clue> get sceneClues => clues.where((c) => c.sceneId != null).toList();

  /// Oyuncunun tüm yolları deneyerek ulaşabileceği ipuçları
  /// (sahne + otomatik açılan + çelişkiyle açılan).
  Set<String> reachableClueIds() {
    final found = {
      for (final c in clues)
        if (c.sceneId != null) c.id,
    };
    var changed = true;
    while (changed) {
      changed = false;
      for (final c in clues) {
        if (!found.contains(c.id) &&
            c.unlockedByClueIds.isNotEmpty &&
            c.unlockedByClueIds.every(found.contains)) {
          changed |= found.add(c.id);
        }
      }
      for (final q in interrogations) {
        final con = q.contradiction;
        final unlock = con?.unlocksClueId;
        if (con == null || unlock == null) continue;
        if (q.requiresClueIds.every(found.contains) &&
            con.clueIds.every(found.contains)) {
          changed |= found.add(unlock);
        }
      }
    }
    return found;
  }

  /// Veri tutarlılığını kontrol eder; hata listesini döner (boşsa vaka geçerli).
  List<String> validate() {
    final errors = <String>[];
    final sceneIds = scenes.map((s) => s.id).toSet();
    final suspectIds = suspects.map((s) => s.id).toSet();
    final clueIds = clues.map((c) => c.id).toSet();
    final reasonIds = solution.reasonOptions.map((r) => r.id).toSet();

    void dup(String kind, Iterable<String> ids) {
      final seen = <String>{};
      for (final i in ids) {
        if (!seen.add(i)) errors.add('Tekrarlanan $kind kimliği: $i');
      }
    }

    dup('sahne', scenes.map((s) => s.id));
    dup('şüpheli', suspects.map((s) => s.id));
    dup('ipucu', clues.map((c) => c.id));
    dup('sorgu', interrogations.map((q) => q.id));

    if (scenes.isEmpty) errors.add('En az bir sahne olmalı');
    if (suspects.isEmpty) errors.add('En az bir şüpheli olmalı');

    for (final c in clues) {
      if (c.sceneId != null && !sceneIds.contains(c.sceneId)) {
        errors.add('İpucu ${c.id}: bilinmeyen sahne ${c.sceneId}');
      }
      if (c.sceneId != null && c.area == null) {
        errors.add('İpucu ${c.id}: sahnedeki ipucunun dokunma alanı yok');
      }
      for (final u in c.unlockedByClueIds) {
        if (!clueIds.contains(u)) {
          errors.add('İpucu ${c.id}: açılması için bilinmeyen ipucu $u');
        }
      }
      for (final s in c.suspectIds) {
        if (!suspectIds.contains(s)) {
          errors.add('İpucu ${c.id}: bilinmeyen şüpheli $s');
        }
      }
    }
    for (final q in interrogations) {
      if (!suspectIds.contains(q.suspectId)) {
        errors.add('Sorgu ${q.id}: bilinmeyen şüpheli ${q.suspectId}');
      }
      for (final r in q.requiresClueIds) {
        if (!clueIds.contains(r)) {
          errors.add('Sorgu ${q.id}: bilinmeyen gerekli ipucu $r');
        }
      }
      final con = q.contradiction;
      if (con != null) {
        for (final id in con.clueIds) {
          if (!clueIds.contains(id)) {
            errors.add('Sorgu ${q.id}: çelişki için bilinmeyen ipucu $id');
          }
        }
        final unlock = con.unlocksClueId;
        if (unlock != null && !clueIds.contains(unlock)) {
          errors.add(
            'Sorgu ${q.id}: çelişkinin açtığı bilinmeyen ipucu $unlock',
          );
        }
      }
    }
    // Her ipucu oyunda bir yolla elde edilebilmeli.
    final reachable = reachableClueIds();
    for (final c in clues) {
      if (!reachable.contains(c.id)) {
        errors.add('İpucu ${c.id}: oyunda hiçbir yolla bulunamıyor');
      }
    }
    dup('bağlantı', connections.map((c) => c.id));
    for (final c in connections) {
      if (c.clueIds.length != 2) {
        errors.add('Bağlantı ${c.id}: tam iki ipucu olmalı');
      }
      for (final id in c.clueIds) {
        if (!clueIds.contains(id)) {
          errors.add('Bağlantı ${c.id}: bilinmeyen ipucu $id');
        }
      }
      if (connectionText(c).isEmpty) {
        errors.add('Bağlantı ${c.id}: metni ya da geçerli deductionStep yok');
      }
    }
    final tl = timeline;
    if (tl != null) {
      dup('zaman çizelgesi olayı', tl.events.map((e) => e.id));
      for (final e in tl.events) {
        if (!tl.slots.contains(e.time)) {
          errors.add('Zaman olayı ${e.id}: ${e.time} saati slotlarda yok');
        }
        final sid = e.suspectId;
        if (sid != null && !suspectIds.contains(sid)) {
          errors.add('Zaman olayı ${e.id}: bilinmeyen şüpheli $sid');
        }
        for (final r in e.requiresClueIds) {
          if (!clueIds.contains(r)) {
            errors.add('Zaman olayı ${e.id}: bilinmeyen ipucu $r');
          }
        }
      }
    }
    final ev = solution.evidence;
    if (ev != null) {
      for (final id in ev.clueIds) {
        if (!clueIds.contains(id)) {
          errors.add('Çözüm kanıtı: bilinmeyen ipucu $id');
        }
      }
      if (ev.pick < 1 || ev.pick > ev.clueIds.length) {
        errors.add(
          'Çözüm kanıtı: pick 1 ile ${ev.clueIds.length} arasında olmalı',
        );
      }
    }
    if (!suspectIds.contains(solution.culpritId)) {
      errors.add('Çözüm: bilinmeyen suçlu ${solution.culpritId}');
    }
    if (solution.reasonOptions.isNotEmpty &&
        !reasonIds.contains(solution.correctReasonId)) {
      errors.add(
        'Çözüm: doğru gerekçe ${solution.correctReasonId} seçenekler arasında yok',
      );
    }
    return errors;
  }
}

/// Vakanın ücretsiz mi yoksa bir paketle mi açıldığı.
class CaseAccess {
  const CaseAccess({required this.free, this.packId});

  factory CaseAccess.fromJson(Map<String, dynamic> json) => CaseAccess(
    free: json['free'] as bool? ?? false,
    packId: _optStr(json, 'packId'),
  );

  final bool free;
  final String? packId;
}

/// Vaka boyunca çalan müzik dosyalarının adları (uzantısız, assets/audio altında).
class CaseMusic {
  const CaseMusic({this.investigation, this.finale, this.tension});

  factory CaseMusic.fromJson(Map<String, dynamic> json) => CaseMusic(
    investigation: _optStr(json, 'investigation'),
    finale: _optStr(json, 'finale'),
    tension: _optStr(json, 'tension'),
  );

  final String? investigation;
  final String? finale;
  final String? tension;
}

class Scene {
  const Scene({
    required this.id,
    required this.title,
    required this.image,
    required this.description,
    this.rain = false,
  });

  factory Scene.fromJson(Map<String, dynamic> json) {
    final id = _req<String>(json, 'id', 'sahne');
    return Scene(
      id: id,
      title: _req<String>(json, 'title', 'sahne $id'),
      image: _optStr(json, 'image') ?? id,
      description: _optStr(json, 'description') ?? '',
      rain: json['rain'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final String image;
  final String description;

  /// Sahnenin üzerine yağmur efekti çizilsin mi.
  final bool rain;
}

class Suspect {
  const Suspect({
    required this.id,
    required this.name,
    required this.role,
    required this.statement,
    required this.portrait,
    this.description = '',
  });

  factory Suspect.fromJson(Map<String, dynamic> json) {
    final id = _req<String>(json, 'id', 'şüpheli');
    return Suspect(
      id: id,
      name: _req<String>(json, 'name', 'şüpheli $id'),
      role: _optStr(json, 'role') ?? '',
      statement: _optStr(json, 'statement') ?? '',
      portrait: _optStr(json, 'portrait') ?? id,
      description: _optStr(json, 'description') ?? '',
    );
  }

  final String id;
  final String name;
  final String role;

  /// Şüphelinin ilk ifadesi.
  final String statement;
  final String portrait;
  final String description;
}

/// Sahne görseli üzerinde 0..1 aralığında normalize edilmiş dokunma alanı.
class HotArea {
  const HotArea(this.x, this.y, this.w, this.h);

  factory HotArea.fromJson(Map<String, dynamic> json) {
    double v(String k) => (json[k] as num).toDouble();
    return HotArea(v('x'), v('y'), v('w'), v('h'));
  }

  final double x;
  final double y;
  final double w;
  final double h;
}

class Clue {
  const Clue({
    required this.id,
    required this.title,
    required this.description,
    this.sceneId,
    this.area,
    this.suspectIds = const [],
    this.image,
    this.unlockedByClueIds = const [],
    this.needsMagnifier = false,
  });

  factory Clue.fromJson(Map<String, dynamic> json) {
    final id = _req<String>(json, 'id', 'ipucu');
    final area = json['area'];
    return Clue(
      id: id,
      title: _req<String>(json, 'title', 'ipucu $id'),
      description: _optStr(json, 'description') ?? '',
      sceneId: _optStr(json, 'sceneId'),
      area: area is Map<String, dynamic> ? HotArea.fromJson(area) : null,
      suspectIds: _strList(json, 'suspectIds'),
      image: _optStr(json, 'image'),
      unlockedByClueIds: _strList(json, 'unlockedByClueIds'),
      needsMagnifier: json['needsMagnifier'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final String description;

  /// Null ise ipucu sahnede değildir: bir çelişkiyle ya da [unlockedByClueIds] ile açılır.
  final String? sceneId;
  final HotArea? area;
  final List<String> suspectIds;

  /// İsteğe bağlı yakın çekim görseli.
  final String? image;

  /// Bu ipuçlarının hepsi bulununca kendiliğinden deftere eklenir (ör. laboratuvar sonucu).
  final List<String> unlockedByClueIds;

  /// true ise ipucu ancak büyüteç üzerindeyken alınabilir (küçük ayrıntı).
  final bool needsMagnifier;
}

/// Şüpheliye sorulabilecek bir soru.
class Interrogation {
  const Interrogation({
    required this.id,
    required this.suspectId,
    required this.question,
    required this.answer,
    this.requiresClueIds = const [],
    this.contradiction,
  });

  factory Interrogation.fromJson(Map<String, dynamic> json) {
    final id = _req<String>(json, 'id', 'sorgu');
    final con = json['contradiction'];
    return Interrogation(
      id: id,
      suspectId: _req<String>(json, 'suspectId', 'sorgu $id'),
      question: _req<String>(json, 'question', 'sorgu $id'),
      answer: _req<String>(json, 'answer', 'sorgu $id'),
      requiresClueIds: _strList(json, 'requiresClueIds'),
      contradiction: con is Map<String, dynamic>
          ? Contradiction.fromJson(con)
          : null,
    );
  }

  final String id;
  final String suspectId;
  final String question;
  final String answer;

  /// Soru ancak bu ipuçları bulunduysa sorulabilir.
  final List<String> requiresClueIds;
  final Contradiction? contradiction;
}

/// Belirli ipucu sunulunca açılan çelişki.
class Contradiction {
  const Contradiction({
    required this.clueIds,
    required this.text,
    this.unlocksClueId,
  });

  /// Tek kanıt için "clueId", birden çok kanıt için "clueIds" yazılabilir.
  factory Contradiction.fromJson(Map<String, dynamic> json) {
    final ids = json['clueIds'] != null
        ? _strList(json, 'clueIds')
        : [_req<String>(json, 'clueId', 'çelişki')];
    if (ids.isEmpty) throw CaseFormatException('Çelişkinin kanıtı yok');
    return Contradiction(
      clueIds: ids,
      text: _req<String>(json, 'text', 'çelişki'),
      unlocksClueId: _optStr(json, 'unlocksClueId'),
    );
  }

  /// Çelişkiyi açan kanıtlar. Hepsi defterde olmalı; biri sunulunca çelişki açılır.
  final List<String> clueIds;

  /// Çelişki açılınca gösterilen metin (şüphelinin tepkisi).
  final String text;

  /// Çelişkiyle deftere eklenen yeni ipucu (isteğe bağlı).
  final String? unlocksClueId;
}

class ReasonOption {
  const ReasonOption({required this.id, required this.text});

  factory ReasonOption.fromJson(Map<String, dynamic> json) => ReasonOption(
    id: _req<String>(json, 'id', 'gerekçe'),
    text: _req<String>(json, 'text', 'gerekçe'),
  );

  final String id;
  final String text;
}

class Solution {
  const Solution({
    required this.culpritId,
    required this.correctReasonId,
    required this.reasonOptions,
    required this.explanation,
    required this.deductionChain,
    required this.finale,
    this.evidence,
  });

  factory Solution.fromJson(Map<String, dynamic> json) => Solution(
    culpritId: _req<String>(json, 'culpritId', 'çözüm'),
    correctReasonId: _optStr(json, 'correctReasonId') ?? '',
    reasonOptions: _list(
      json,
      'reasonOptions',
    ).map(ReasonOption.fromJson).toList(),
    explanation: _optStr(json, 'explanation') ?? '',
    deductionChain: _strList(json, 'deductionChain'),
    finale: Finale.fromJson(
      (json['finale'] as Map<String, dynamic>?) ?? const {},
    ),
    evidence: json['evidence'] is Map<String, dynamic>
        ? EvidenceRule.fromJson(json['evidence'] as Map<String, dynamic>)
        : null,
  );

  final String culpritId;
  final String correctReasonId;
  final List<ReasonOption> reasonOptions;

  /// Suçlunun neden o kişi olduğunun açıklaması.
  final String explanation;

  /// Çıkarım zinciri adımları.
  final List<String> deductionChain;
  final Finale finale;

  /// Suçlamada seçilmesi gereken kanıtlar (isteğe bağlı).
  final EvidenceRule? evidence;
}

/// Suçlamanın kanıt adımı: oyuncu [pick] kanıt seçer, hepsi [clueIds] içinde olmalı.
class EvidenceRule {
  const EvidenceRule({required this.clueIds, required this.pick});

  factory EvidenceRule.fromJson(Map<String, dynamic> json) {
    final ids = _strList(json, 'clueIds');
    return EvidenceRule(
      clueIds: ids,
      pick: (json['pick'] as num?)?.toInt() ?? ids.length,
    );
  }

  final List<String> clueIds;
  final int pick;
}

/// Delil panosunda iki ipucu arasındaki doğru bağlantı.
class BoardConnection {
  const BoardConnection({
    required this.id,
    required this.clueIds,
    this.text,
    this.deductionStep,
  });

  factory BoardConnection.fromJson(Map<String, dynamic> json) {
    final id = _req<String>(json, 'id', 'bağlantı');
    return BoardConnection(
      id: id,
      clueIds: _strList(json, 'clueIds'),
      text: _optStr(json, 'text'),
      deductionStep: (json['deductionStep'] as num?)?.toInt(),
    );
  }

  final String id;
  final List<String> clueIds;

  /// Bağlantı kurulunca açılan çıkarım; yoksa [deductionStep] kullanılır.
  final String? text;

  /// Çıkarım zincirindeki adım numarası (1'den başlar).
  final int? deductionStep;

  bool matches(String a, String b) =>
      clueIds.length == 2 &&
      clueIds.contains(a) &&
      clueIds.contains(b) &&
      a != b;
}

/// Oyuncunun olay kartlarını saatlere yerleştirdiği zaman çizelgesi.
class TimelineData {
  const TimelineData({required this.slots, required this.events});

  factory TimelineData.fromJson(Map<String, dynamic> json) => TimelineData(
    slots: _strList(json, 'slots'),
    events: _list(json, 'events').map(TimelineEvent.fromJson).toList(),
  );

  /// Saatler, sırasıyla (ör. "21:05").
  final List<String> slots;
  final List<TimelineEvent> events;
}

class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.text,
    required this.time,
    this.suspectId,
    this.place,
    this.requiresClueIds = const [],
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    final id = _req<String>(json, 'id', 'zaman olayı');
    return TimelineEvent(
      id: id,
      text: _req<String>(json, 'text', 'zaman olayı $id'),
      time: _req<String>(json, 'time', 'zaman olayı $id'),
      suspectId: _optStr(json, 'suspectId'),
      place: _optStr(json, 'place'),
      requiresClueIds: _strList(json, 'requiresClueIds'),
    );
  }

  final String id;
  final String text;

  /// Doğru saat; [TimelineData.slots] içinden biri.
  final String time;
  final String? suspectId;
  final String? place;

  /// Kart ancak bu ipuçları bulununca çizelgeye gelir.
  final List<String> requiresClueIds;
}

/// Yıldız eşikleri: ceza (ipucu yardımı + yanlış suçlama puanı) bu sınırları aşmazsa o kadar yıldız.
class StarRule {
  const StarRule({this.three = 0, this.two = 2});

  factory StarRule.fromJson(Map<String, dynamic> json) => StarRule(
    three: (json['three'] as num?)?.toInt() ?? 0,
    two: (json['two'] as num?)?.toInt() ?? 2,
  );

  final int three;
  final int two;

  int starsFor(int penalty) => penalty <= three ? 3 : (penalty <= two ? 2 : 1);
}

class Finale {
  const Finale({this.title = '', this.paragraphs = const [], this.image});

  factory Finale.fromJson(Map<String, dynamic> json) => Finale(
    title: _optStr(json, 'title') ?? '',
    paragraphs: _strList(json, 'paragraphs'),
    image: _optStr(json, 'image'),
  );

  final String title;
  final List<String> paragraphs;
  final String? image;
}

class WrongAnswer {
  const WrongAnswer({
    required this.title,
    required this.paragraphs,
    this.wrongReasonText,
    this.image,
    this.hintPenalty = 0,
    this.penaltyPoints = 1,
    this.wrongEvidenceText,
  });

  factory WrongAnswer.fromJson(Map<String, dynamic> json) => WrongAnswer(
    title: _optStr(json, 'title') ?? '',
    paragraphs: _strList(json, 'paragraphs'),
    wrongReasonText: _optStr(json, 'wrongReasonText'),
    image: _optStr(json, 'image'),
    hintPenalty: (json['hintPenalty'] as num?)?.toInt() ?? 0,
    penaltyPoints: (json['penaltyPoints'] as num?)?.toInt() ?? 1,
    wrongEvidenceText: _optStr(json, 'wrongEvidenceText'),
  );

  /// Her yanlış suçlamada eksilen ipucu hakkı.
  final int hintPenalty;

  /// Her yanlış suçlamada eklenen ceza puanı (yıldızı düşürür).
  final int penaltyPoints;

  /// Kişi ve gerekçe doğru ama kanıtlar yanlışsa gösterilen metin (isteğe bağlı).
  final String? wrongEvidenceText;

  final String title;

  /// Yanlış kişi suçlandığında gösterilen sahne metni.
  final List<String> paragraphs;

  /// Kişi doğru ama gerekçe yanlışsa gösterilen metin (isteğe bağlı).
  final String? wrongReasonText;
  final String? image;
}

/// Giriş sahnesi: zaman çizelgesindeki olaylar.
class IntroData {
  const IntroData({
    required this.durationMs,
    required this.background,
    required this.events,
    this.rain = false,
  });

  factory IntroData.fromJson(Map<String, dynamic> json) {
    final events = _list(json, 'events').map(IntroEvent.fromJson).toList()
      ..sort((a, b) => a.atMs.compareTo(b.atMs));
    final lastAt = events.isEmpty ? 0 : events.last.atMs;
    return IntroData(
      durationMs: (json['durationMs'] as num?)?.toInt() ?? lastAt + 4000,
      background: _optStr(json, 'background'),
      events: events,
      rain: json['rain'] as bool? ?? false,
    );
  }

  final int durationMs;
  final String? background;
  final List<IntroEvent> events;
  final bool rain;
}

/// Zaman çizelgesindeki olay türleri.
enum IntroEventType {
  text,
  voice,
  sfx,
  music,
  stopMusic,
  shake,
  flash,
  background,
  rain,
}

class IntroEvent {
  const IntroEvent({
    required this.atMs,
    required this.type,
    this.text,
    this.sound,
    this.image,
    this.speaker,
    this.value,
  });

  factory IntroEvent.fromJson(Map<String, dynamic> json) {
    final typeName = _req<String>(json, 'type', 'giriş olayı');
    final type = IntroEventType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () =>
          throw CaseFormatException('Bilinmeyen giriş olayı türü: $typeName'),
    );
    return IntroEvent(
      atMs: (json['atMs'] as num).toInt(),
      type: type,
      text: _optStr(json, 'text'),
      sound: _optStr(json, 'sound'),
      image: _optStr(json, 'image'),
      speaker: _optStr(json, 'speaker'),
      value: (json['value'] as num?)?.toDouble(),
    );
  }

  final int atMs;
  final IntroEventType type;

  /// text: ekranda yazılacak satır.
  final String? text;

  /// voice/sfx/music: assets/audio altındaki dosya adı (uzantısız).
  final String? sound;

  /// background: assets/images altındaki görsel adı.
  final String? image;
  final String? speaker;

  /// shake: şiddet, rain: 0 kapalı / 1 açık.
  final double? value;
}
