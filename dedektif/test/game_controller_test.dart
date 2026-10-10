import 'package:dedektif/features/game/game_controller.dart';
import 'package:dedektif/features/intro/intro_timeline.dart';
import 'package:dedektif/models/case_data.dart';
import 'package:dedektif/services/progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  late ProgressService progress;
  late GameController game;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    progress = ProgressService(await SharedPreferences.getInstance());
    game = GameController(fixtureCase(), progress);
  });

  test('ipucu toplama bir kez sayılır', () {
    expect(game.collectClue('kasa'), isTrue);
    expect(game.collectClue('kasa'), isFalse);
    expect(game.foundClueCount, 1);
    expect(game.foundInScene('dukkan'), 1);
  });

  test('gerekli ipucu bulunmadan soru açılmaz', () {
    final q = fixtureCase().interrogation('s2');
    expect(game.isAvailable(q), isFalse);
    game.collectClue('yedek_anahtar');
    expect(game.isAvailable(q), isTrue);
  });

  test('doğru ipucu çelişki açar ve yeni ipucu ekler', () {
    expect(game.presentClue('s2', 'kasa'), PresentResult.noEffect);
    expect(game.presentClue('s2', 'camur'), PresentResult.contradiction);
    expect(game.isFound('itiraf'), isTrue);
    expect(game.presentClue('s2', 'camur'), PresentResult.alreadyFound);
    expect(game.foundContradictions.map((q) => q.id), ['s2']);
  });

  test('suçlama: kişi ve gerekçe birlikte doğru olmalı', () {
    expect(game.accuse('sahip', 'r2').solved, isFalse);
    final half = game.accuse('cirak', 'r1');
    expect(half.culpritCorrect, isTrue);
    expect(half.solved, isFalse);
    game.collectClue('kasa');
    expect(game.accuse('cirak', 'r2').solved, isTrue);
    expect(game.progress.wrongAttempts, 2);
    expect(game.progress.bestClueCount, 1);
  });

  test('ilerleme kaydedilir ve yeniden yüklenir', () async {
    game.collectClue('fis');
    game.markIntroSeen();
    await progress.save('ornek_vaka');
    final again = ProgressService(await SharedPreferences.getInstance());
    final p = again.caseProgress('ornek_vaka');
    expect(p.foundClueIds, {'fis'});
    expect(p.introSeen, isTrue);
  });

  test('baştan oynama ilerlemeyi sıfırlar ama çözümü korur', () {
    game.collectClue('kasa');
    game.accuse('cirak', 'r2');
    game.restart();
    expect(game.foundClueCount, 0);
    expect(game.progress.solved, isTrue);
  });

  test('zaman çizelgesi olayları zamanında verir', () {
    final t = IntroTimeline(fixtureCase().intro!);
    expect(t.advance(0).map((e) => e.type), [
      IntroEventType.voice,
      IntroEventType.text,
    ]);
    expect(t.advance(1000), isEmpty);
    expect(t.advance(1600).map((e) => e.type), [
      IntroEventType.sfx,
      IntroEventType.flash,
      IntroEventType.shake,
    ]);
    expect(t.isOver(3000), isFalse);
    t.advance(3000);
    expect(t.isOver(6000), isTrue);
  });
}
