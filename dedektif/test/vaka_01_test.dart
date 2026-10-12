import 'dart:io';

import 'package:dedektif/features/game/game_controller.dart';
import 'package:dedektif/services/case_repository.dart';
import 'package:dedektif/services/progress_service.dart';
import 'package:dedektif/widgets/star_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';
import 'playthrough_test.dart' show tap, collect, present;

const _path = 'assets/cases/vaka_01.json';
String _text() => File(_path).readAsStringSync();

void main() {
  test('Vaka 1 kurgusu: ipuçları zinciri ve çözüm', () async {
    SharedPreferences.setMockInitialValues({});
    final data = CaseRepository.parse(_text());
    expect(data.validate(), isEmpty);
    expect(data.suspects.map((s) => s.name), [
      'Selma Aksoy',
      'Kerem Aksoy',
      'Dr. Aylin Demirtaş',
      'Hasan Usta',
    ]);
    expect(data.clues, hasLength(10));

    // Bahçe ifadesi iki kanıtla çöker; tek kanıt yetmez.
    final partial = GameController(
      data,
      ProgressService(await SharedPreferences.getInstance()),
    )..collectClue('bahce_kamerasi');
    expect(
      partial.presentClue('kerem_1', 'bahce_kamerasi'),
      PresentResult.needsMore,
    );
    partial.restart();

    final game = GameController(
      data,
      ProgressService(await SharedPreferences.getInstance()),
    );
    for (final c in data.sceneClues) {
      game.collectClue(c.id);
    }
    expect(game.foundClueCount, 8);

    expect(
      game.presentClue('kerem_1', 'telefon_kaydi'),
      PresentResult.contradiction,
    );
    // Ceket cebi açılınca şişe analizi kendiliğinden gelir.
    expect(game.isFound('ceket_cebi'), isTrue);
    expect(game.isFound('sise_analizi'), isTrue);
    expect(game.foundClueCount, 10);

    // Panoda doğru bağlantı çıkarım zincirinden metin açar.
    expect(data.connections, hasLength(5));
    expect(
      game.connect('kapi_kaydi', 'kahve_tepsisi'),
      ConnectResult.noLink,
    );
    expect(
      game.connect('mutfak_defteri', 'kahve_fincani'),
      ConnectResult.linked,
    );
    expect(
      data.connectionText(game.lastConnection!),
      data.solution.deductionChain[1],
    );
    expect(
      game.connect('kahve_fincani', 'mutfak_defteri'),
      ConnectResult.alreadyLinked,
    );

    // Zaman çizelgesi: tüm kartlar doğru saatte olunca çözülür.
    expect(game.lockedTimelineEvents, 0);
    for (final e in game.timelineEvents) {
      game.placeEvent(e.id, '21:40');
    }
    expect(game.checkTimeline(), 1);
    expect(game.progress.timelineSolved, isFalse);
    for (final e in game.timelineEvents) {
      game.placeEvent(e.id, e.time);
    }
    expect(game.checkTimeline(), 7);
    expect(game.progress.timelineSolved, isTrue);

    // Yanlış suçlama ipucu hakkını bir eksiltir ve ceza puanı verir.
    const proof = {'koridor_kamerasi', 'telefon_kaydi', 'sise_analizi'};
    expect(game.freeHintsLeft, 3);
    expect(game.accuse('selma', 'miras', proof).solved, isFalse);
    expect(game.freeHintsLeft, 2);
    expect(game.progress.penaltyPoints, 1);
    expect(game.accuse('kerem', 'borc', proof).solved, isFalse);
    // Kişi ve neden doğru ama kanıt zayıf.
    final weak = game.accuse('kerem', 'seker', {
      'koridor_kamerasi',
      'kapi_kaydi',
      'sise_analizi',
    });
    expect(weak.evidenceCorrect, isFalse);
    expect(weak.solved, isFalse);
    final win = game.accuse('kerem', 'seker', proof);
    expect(win.solved, isTrue);
    // Üç ceza puanı: tek yıldız.
    expect(win.stars, 1);
    expect(game.progress.bestStars, 1);
  });

  test('Vaka 1: temiz çözüm üç yıldız ve rütbe atlatır', () async {
    SharedPreferences.setMockInitialValues({});
    final data = CaseRepository.parse(_text());
    final game = GameController(
      data,
      ProgressService(await SharedPreferences.getInstance()),
    );
    for (final c in data.sceneClues) {
      game.collectClue(c.id);
    }
    game.presentClue('kerem_1', 'telefon_kaydi');
    final win = game.accuse('kerem', 'seker', {
      'bahce_kamerasi',
      'ceket_cebi',
      'koridor_kamerasi',
    });
    expect(win.stars, 3);
    expect(win.rankUp?.title, 'Dedektif');
  });

  testWidgets('Vaka 1 baştan sona oynanır', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final app = await TestApp.create(caseFiles: {_path: _text()});
    await t.pumpWidget(app.widget);
    await t.pumpAndSettle();
    await tap(t, find.text('Oyna'));
    await t.tap(find.text('Şekersiz Kahve'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 800));
    expect(find.text('Yağmurlu bir ekim akşamı.'), findsOneWidget);
    await t.tap(find.text('Atla'));
    await t.pumpAndSettle();

    // Çalışma odası: bir ipucu reklamsız hakla işaretlenir.
    await tap(t, find.byTooltip('İpucu (3 hak)'));
    // Fincandaki şeker taneleri ancak büyüteç üstündeyken görülür.
    await tap(t, find.byKey(const ValueKey('hotspot_kahve_fincani')));
    expect(
      find.text('Burada bir şey var gibi. Büyüteçle yakından bak.'),
      findsOneWidget,
    );
    await collect(t, 'kahve_fincani');
    await collect(t, 'kahve_tepsisi');
    await collect(t, 'ilac_dolabi');
    await tap(t, find.textContaining('Mutfak'));
    await collect(t, 'mutfak_defteri');
    await tap(t, find.textContaining('Güvenlik kayıtları'));
    for (final id in [
      'kapi_kaydi',
      'koridor_kamerasi',
      'bahce_kamerasi',
      'telefon_kaydi',
    ]) {
      await collect(t, id);
    }

    await tap(t, find.text('Şüpheliler'));
    await tap(t, find.byKey(const ValueKey('suspect_kerem')));
    Future<void> askAndPresent(String q, String clue) async {
      final card = find.byKey(ValueKey('question_$q'));
      await tap(t, find.descendant(of: card, matching: find.text('Sor')));
      await tap(t, find.descendant(of: card, matching: find.text('İpucu sun')));
      await present(t, clue);
      expect(find.text('YALAN SÖYLÜYORSUN!'), findsOneWidget);
      await tap(t, find.text('Devam'));
    }

    await askAndPresent('kerem_1', 'bahce_kamerasi');
    await askAndPresent('kerem_2', 'ceket_cebi');
    await askAndPresent('kerem_3', 'koridor_kamerasi');
    await t.tap(find.byType(BackButton));
    await t.pumpAndSettle();

    // Delil panosu: iki karta sırayla dokununca ip gerilir.
    await tap(t, find.text('Pano'));
    await tap(t, find.byKey(const ValueKey('board_kahve_fincani')));
    await tap(t, find.byKey(const ValueKey('board_sise_analizi')));
    expect(find.text('BAĞLANTI KURULDU'), findsOneWidget);
    expect(find.text('Zehir kahveye konmuş.'), findsOneWidget);
    await tap(t, find.text('Devam'));
    expect(find.text('Çıkarımlar 1/5'), findsOneWidget);

    // Zaman çizelgesi: kartı seçip saate dokunarak yerleştir.
    await tap(t, find.text('Zaman'));
    const times = {
      't_arama': '21:05',
      't_kahve': '21:10',
      't_tepsi': '21:15',
      't_doktor': '21:15',
      't_giris': '21:22',
      't_cikis': '21:25',
      't_ceset': '21:40',
    };
    for (final MapEntry(key: id, value: time) in times.entries) {
      await tap(t, find.byKey(ValueKey('tl_card_$id')));
      await tap(t, find.byKey(ValueKey('tl_slot_$time')));
    }
    await tap(t, find.text('Kontrol et'));
    expect(
      find.text('Zaman çizelgesi doğru! Olaylar yerine oturdu.'),
      findsOneWidget,
    );

    await tap(t, find.text('Suçluyu seç'));
    await tap(t, find.byKey(const ValueKey('accuse_kerem')));
    await tap(t, find.byKey(const ValueKey('reason_seker')));
    for (final id in ['bahce_kamerasi', 'ceket_cebi', 'sise_analizi']) {
      final f = find.byKey(ValueKey('evidence_$id'));
      await t.scrollUntilVisible(
        f,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tap(t, f);
    }
    await t.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Suçla'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tap(t, find.widgetWithText(FilledButton, 'Suçla'));
    await tap(
      t,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Suçla'),
      ),
    );

    expect(
      find.text(
        'Dedektif yalının salonunda herkesi topluyor. Yağmur camlara vuruyor.',
      ),
      findsOneWidget,
    );
    // Uzun final metninde düğmeler ekranın altında kalabilir: kaydırarak bul.
    Future<void> scrollTo(Finder f) =>
        t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
    for (var i = 0; i < 3; i++) {
      await scrollTo(find.text('Devam ›'));
      await tap(t, find.text('Devam ›'));
    }
    await scrollTo(find.text('Paylaş'));
    expect(find.text('10/10'), findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);
    // Bir ipucu yardımı kullanıldı: iki yıldız.
    expect(
      find.byWidgetPredicate((w) => w is StarRow && w.stars == 2),
      findsOneWidget,
    );
    expect(find.text('Rütbe atladın: Dedektif!'), findsNothing);
    expect(find.text('Rütben: Çaylak'), findsOneWidget);
  });
}
