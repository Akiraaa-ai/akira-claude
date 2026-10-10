import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Bir düğmeye dokunup animasyonların bitmesini bekler.
Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

/// Açık alt sayfa/diyalog varsa kapatır.
Future<void> closeSheet(WidgetTester t) async {
  await t.tapAt(const Offset(5, 5));
  await t.pumpAndSettle();
}

/// Sunma listesinde ipucunu bulup seçer (liste uzunsa kaydırır).
Future<void> present(WidgetTester t, String clueId) async {
  final f = find.byKey(ValueKey('present_$clueId'));
  await t.scrollUntilVisible(f, 80, scrollable: find.byType(Scrollable).last);
  await tap(t, f);
}

Future<void> collect(WidgetTester t, String clueId) async {
  await tap(t, find.byKey(ValueKey('hotspot_$clueId')));
  expect(find.text('YENİ İPUCU'), findsOneWidget);
  await closeSheet(t);
}

Future<void> openCaseFromMenu(WidgetTester t) async {
  await t.pumpAndSettle();
  await tap(t, find.text('Oyna'));
  // Giriş sahnesi kendi saatiyle aktığı için burada pumpAndSettle kullanılmaz.
  await t.tap(find.text('Örnek Vaka: Sahaftaki Boş Kasa'));
  await t.pump();
  await t.pump(const Duration(milliseconds: 600));
}

void main() {
  setUp(() {
    // Dikey telefon ekranı.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('vaka baştan sona oynanır ve doğru çözülür', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final app = await TestApp.create();
    await t.pumpWidget(app.widget);
    await openCaseFromMenu(t);

    // Giriş sahnesi: ilk satır görünür, atlanır.
    expect(find.text('Yağmur bütün gece durmadı.'), findsOneWidget);
    expect(app.audio.log, contains('voice:ornek_giris_seslendirme'));
    await t.tap(find.text('Atla'));
    await t.pumpAndSettle();

    // Sahne: dükkân ipuçları.
    expect(find.text('Bulunan ipucu: 0/3'), findsOneWidget);
    await collect(t, 'islak_semsiye');
    await collect(t, 'kasa');
    expect(find.text('Bulunan ipucu: 2/3'), findsOneWidget);
    expect(app.audio.log, contains('sfx:ipucu_bulundu'));

    // Ödüllü reklam ipucu: kalan ipucunu işaretler.
    await tap(t, find.byTooltip('İpucu (reklam izle)'));
    await collect(t, 'fis');

    // Depo sahnesi.
    await tap(t, find.textContaining('Arka depo'));
    await collect(t, 'yedek_anahtar');
    await collect(t, 'camur');

    // Defter.
    await tap(t, find.text('Defter'));
    expect(find.text('İpuçları (5/6)'), findsOneWidget);

    // Sorgu: Deniz.
    await tap(t, find.text('Şüpheliler'));
    await tap(t, find.byKey(const ValueKey('suspect_cirak')));
    expect(find.text('“Altıda çıktım, sonra hiç gelmedim.”'), findsOneWidget);

    final q1 = find.byKey(const ValueKey('question_s1'));
    await tap(t, find.descendant(of: q1, matching: find.text('Sor')));
    expect(find.text('Hayır, altıda çıktım ve eve gittim.'), findsOneWidget);

    // Yanlış ipucu çelişki açmaz.
    await tap(t, find.descendant(of: q1, matching: find.text('İpucu sun')));
    await present(t, 'kasa');
    expect(find.text('Bu ipucu bu ifadeyle çelişmiyor.'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();

    // Doğru ipucu çelişkiyi açar.
    await tap(t, find.descendant(of: q1, matching: find.text('İpucu sun')));
    await present(t, 'islak_semsiye');
    expect(find.text('ÇELİŞKİ!'), findsOneWidget);
    await tap(t, find.text('Devam'));

    final q2 = find.byKey(const ValueKey('question_s2'));
    await tap(t, find.descendant(of: q2, matching: find.text('Sor')));
    await tap(t, find.descendant(of: q2, matching: find.text('İpucu sun')));
    await present(t, 'camur');
    expect(
      find.text("Deftere eklendi: Deniz'in kaçamak cevabı"),
      findsOneWidget,
    );
    await tap(t, find.text('Devam'));
    await t.pageBack();
    await t.pumpAndSettle();

    // Suçlama.
    await tap(t, find.text('Suçluyu seç'));
    await tap(t, find.byKey(const ValueKey('accuse_cirak')));
    await tap(t, find.byKey(const ValueKey('reason_r2')));
    await tap(t, find.widgetWithText(FilledButton, 'Suçla'));
    await tap(
      t,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Suçla'),
      ),
    );

    // Final ve sonuç.
    expect(find.text('Dosya kapandı'), findsOneWidget);
    await tap(t, find.text('Devam ›'));
    expect(
      find.text('Para depodaki kolilerin arasından çıktı.'),
      findsOneWidget,
    );
    expect(find.text('6/6'), findsOneWidget);
    await tap(t, find.text('Paylaş'));
    expect(app.share.shared.single, contains('6/6 ipucuyla çözdüm'));

    // Vaka listesine dönünce çözüldü rozeti görünür.
    await tap(t, find.text('Vakalara dön'));
    expect(find.text('Çözüldü · 6 ipucu'), findsOneWidget);
  });

  testWidgets('yanlış suçlama yanlış cevap sahnesini gösterir', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    // Giriş daha önce izlendi: doğrudan soruşturmaya girer.
    final app = await TestApp.create(
      prefs: {'progress.ornek_vaka': '{"introSeen": true}'},
    );
    await t.pumpWidget(app.widget);
    await openCaseFromMenu(t);
    await t.pumpAndSettle();
    expect(find.text('Atla'), findsNothing);

    await tap(t, find.text('Suçluyu seç'));
    await tap(t, find.byKey(const ValueKey('accuse_komsu')));
    await tap(t, find.byKey(const ValueKey('reason_r1')));
    await tap(t, find.widgetWithText(FilledButton, 'Suçla'));
    await tap(
      t,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Suçla'),
      ),
    );

    expect(find.text('Yanlış kişi'), findsOneWidget);
    await tap(t, find.text('Devam ›'));
    await tap(t, find.text('Soruşturmaya dön'));
    expect(find.text('Suçluyu seç'), findsOneWidget);
    expect(app.services.progress.caseProgress('ornek_vaka').wrongAttempts, 1);
  });

  testWidgets('kilitli vaka satın alınınca açılır', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final locked = fixtureText().replaceFirst(
      '"access": { "free": true }',
      '"access": { "free": false, "packId": "vaka_paketi_1" }',
    );
    final app = await TestApp.create(
      caseFiles: {'assets/cases/ornek_vaka.json': locked},
    );
    await t.pumpWidget(app.widget);
    await t.pumpAndSettle();
    await tap(t, find.text('Oyna'));
    expect(find.text('Kilitli'), findsOneWidget);
    await tap(t, find.text('Örnek Vaka: Sahaftaki Boş Kasa'));
    await tap(t, find.text('Paketi aç'));
    expect(find.text('Paket açıldı. İyi soruşturmalar!'), findsOneWidget);
    expect(find.text('Yeni'), findsOneWidget);
  });
}
