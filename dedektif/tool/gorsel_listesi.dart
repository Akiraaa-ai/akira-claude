// assets/cases altındaki vakalardan docs/gorsel_listesi.md dosyasını üretir.
// Çalıştırma: dart run tool/gorsel_listesi.dart

import 'dart:convert';
import 'dart:io';

import 'package:dedektif/models/case_data.dart';

/// Görsel türü → önerilen boyut.
const sizes = {
  'Arka plan (dikey)': '1080×1920 px (9:16)',
  'Sahne (dikey)': '1080×1920 px (9:16)',
  'Kapak': '1280×720 px (16:9)',
  'Portre': '600×800 px (3:4)',
  'Yakın çekim': '800×600 px (4:3)',
};

/// Genel ses adları (koddaki sabitlerle aynı).
const generalAudio = {
  'menu_muzik': 'Ana menü müziği (döngü)',
  'dokunma': 'Düğme dokunma efekti',
  'ipucu_bulundu': 'İpucu bulununca',
  'celiski': 'Çelişki yakalanınca',
  'yanlis': 'Sunulan ipucu çelişmeyince',
  'cozuldu': 'Vaka çözülünce',
  'yanlis_suclama': 'Yanlış suçlamada',
};

void main() {
  final rows = <List<String>>[];
  final audio = <List<String>>[];
  void img(String? name, String kind, String where) {
    if (name == null) return;
    if (rows.any((r) => r[0] == name)) return;
    rows.add([name, kind, sizes[kind]!, where]);
  }

  void snd(String? name, String where) {
    if (name == null || audio.any((r) => r[0] == name)) return;
    audio.add([name, where]);
  }

  img('menu_arkaplan', 'Arka plan (dikey)', 'Ana menü');
  generalAudio.forEach((k, v) => snd(k, 'Genel: $v'));

  final files =
      Directory('assets/cases')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final f in files) {
    final c = CaseData.fromJson(
      jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
    );
    final v = c.id;
    img(c.coverImage, 'Kapak', '$v: vaka seçimi kartı');
    final intro = c.intro;
    if (intro != null) {
      img(intro.background, 'Arka plan (dikey)', '$v: giriş sahnesi');
      for (final e in intro.events) {
        if (e.type == IntroEventType.background) {
          img(e.image, 'Arka plan (dikey)', '$v: giriş sahnesi (${e.atMs} ms)');
        }
        if (e.sound != null) {
          snd(e.sound, '$v: giriş ${e.type.name} (${e.atMs} ms)');
        }
      }
    }
    for (final s in c.scenes) {
      img(s.image, 'Sahne (dikey)', '$v: sahne "${s.title}"');
    }
    for (final s in c.suspects) {
      img(s.portrait, 'Portre', '$v: ${s.name} (${s.role})');
    }
    for (final cl in c.clues) {
      img(cl.image, 'Yakın çekim', '$v: ipucu "${cl.title}"');
    }
    img(c.solution.finale.image, 'Arka plan (dikey)', '$v: final sahnesi');
    img(c.wrongAnswer.image, 'Arka plan (dikey)', '$v: yanlış cevap sahnesi');
    snd(c.music.investigation, '$v: soruşturma müziği (döngü)');
    snd(c.music.tension, '$v: suçlama gerilim müziği (döngü)');
    snd(c.music.finale, '$v: final müziği');
  }

  final out = StringBuffer()
    ..writeln('# Görsel ve ses listesi')
    ..writeln()
    ..writeln(
      '> Bu dosya `dart run tool/gorsel_listesi.dart` ile vaka JSON\'larından üretilir. Elle düzenleme.',
    )
    ..writeln()
    ..writeln(
      'Görselleri `assets/images/` altına, tabloda yazan **ad** ile koy. Uzantı `.png`, `.jpg` ya da `.webp` olabilir '
      '(ör. `assets/images/menu_arkaplan.jpg`). Dosya bulunursa yer tutucu yerine otomatik kullanılır, kod değişmez.',
    )
    ..writeln()
    ..writeln(
      'Sahne görsellerinde ipucu dokunma alanları görselin oranına göre (0–1) tanımlıdır; bu yüzden sahneler **tam 9:16** olmalı.',
    )
    ..writeln()
    ..writeln('| Ad | Tür | Boyut | Nerede |')
    ..writeln('|---|---|---|---|');
  for (final r in rows) {
    out.writeln('| `${r[0]}` | ${r[1]} | ${r[2]} | ${r[3]} |');
  }
  out
    ..writeln()
    ..writeln('## Sesler')
    ..writeln()
    ..writeln(
      '`assets/audio/` altına `.mp3`, `.ogg`, `.m4a` ya da `.wav` olarak koy. Eksik ses hata vermez, sessizce atlanır.',
    )
    ..writeln()
    ..writeln('| Ad | Nerede |')
    ..writeln('|---|---|');
  for (final r in audio) {
    out.writeln('| `${r[0]}` | ${r[1]} |');
  }
  File('docs/gorsel_listesi.md').writeAsStringSync(out.toString());
  stdout.writeln(
    'docs/gorsel_listesi.md yazıldı: ${rows.length} görsel, ${audio.length} ses.',
  );
}
