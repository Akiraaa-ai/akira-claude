import 'dart:io';

import 'package:dedektif/features/game/game_controller.dart';
import 'package:dedektif/services/case_repository.dart';
import 'package:dedektif/services/progress_service.dart';
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

    // Yanlış suçlama ipucu hakkını bir eksiltir.
    expect(game.freeHintsLeft, 3);
    expect(game.accuse('selma', 'miras').solved, isFalse);
    expect(game.freeHintsLeft, 2);
    expect(game.accuse('kerem', 'borc').solved, isFalse);
    expect(game.accuse('kerem', 'seker').solved, isTrue);
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
      expect(find.text('ÇELİŞKİ!'), findsOneWidget);
      await tap(t, find.text('Devam'));
    }

    await askAndPresent('kerem_1', 'bahce_kamerasi');
    await askAndPresent('kerem_2', 'ceket_cebi');
    await askAndPresent('kerem_3', 'koridor_kamerasi');
    await t.pageBack();
    await t.pumpAndSettle();

    await tap(t, find.text('Suçluyu seç'));
    await tap(t, find.byKey(const ValueKey('accuse_kerem')));
    await tap(t, find.byKey(const ValueKey('reason_seker')));
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
  });
}
