import 'dart:convert';
import 'dart:io';

import 'package:dedektif/models/case_data.dart';
import 'package:dedektif/services/case_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('örnek vaka okunur ve geçerlidir', () {
    final c = fixtureCase();
    expect(c.id, 'ornek_vaka');
    expect(c.suspects, hasLength(4));
    expect(c.sceneClues, hasLength(5));
    expect(c.intro!.events.first.type, IntroEventType.voice);
    expect(c.validate(), isEmpty);
  });

  test('hatalı referanslar yakalanır', () {
    final json = jsonDecode(fixtureText()) as Map<String, dynamic>;
    (json['clues'] as List).first['sceneId'] = 'olmayan_sahne';
    (json['solution'] as Map)['culpritId'] = 'kimse';
    final errors = CaseData.fromJson(json).validate();
    expect(errors.any((e) => e.contains('olmayan_sahne')), isTrue);
    expect(errors.any((e) => e.contains('kimse')), isTrue);
  });

  test('bilinmeyen giriş olayı türü hata verir', () {
    final json = jsonDecode(fixtureText()) as Map<String, dynamic>;
    ((json['intro'] as Map)['events'] as List).add({'atMs': 1, 'type': 'dans'});
    expect(() => CaseData.fromJson(json), throwsA(isA<CaseFormatException>()));
  });

  // Uygulamaya paketlenen tüm vakalar geçerli olmalı.
  test('assets/cases altındaki tüm vakalar geçerli', () {
    final dir = Directory('assets/cases');
    for (final f in dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json'),
    )) {
      final c = CaseRepository.parse(f.readAsStringSync());
      expect(c.validate(), isEmpty, reason: f.path);
    }
  });
}
