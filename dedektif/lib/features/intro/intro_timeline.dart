import '../../models/case_data.dart';

/// Basit zaman çizelgesi: geçen süreye göre zamanı gelen olayları sırayla verir.
/// Sesten bağımsız kendi saatiyle ilerler; ses dosyası olmasa da sahne akar.
class IntroTimeline {
  IntroTimeline(this.intro);

  final IntroData intro;
  int _next = 0;

  bool get finished => _next >= intro.events.length;

  /// [elapsedMs] anına kadar tetiklenmemiş olayları döner.
  List<IntroEvent> advance(int elapsedMs) {
    final due = <IntroEvent>[];
    while (_next < intro.events.length &&
        intro.events[_next].atMs <= elapsedMs) {
      due.add(intro.events[_next++]);
    }
    return due;
  }

  bool isOver(int elapsedMs) => finished && elapsedMs >= intro.durationMs;
}
