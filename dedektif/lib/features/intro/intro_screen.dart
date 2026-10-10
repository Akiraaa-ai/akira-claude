import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/case_data.dart';
import '../../services/audio_service.dart';
import '../../widgets/case_image.dart';
import '../../widgets/effects/ken_burns.dart';
import '../../widgets/effects/rain_overlay.dart';
import '../../widgets/effects/screen_shake.dart';
import '../../widgets/effects/typewriter_text.dart';
import '../game/game_controller.dart';
import '../game/game_routes.dart';
import '../investigation/investigation_screen.dart';
import 'intro_timeline.dart';

/// Giriş sahnesi: JSON'daki zaman çizelgesini oynatır, atlanabilir.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.continueToInvestigation});

  /// true: bitince soruşturmaya geçer. false: tekrar izleme, bitince geri döner.
  final bool continueToInvestigation;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late final GameController _game = context.read<GameController>();
  late final AudioService _audio = context.read<AudioService>();
  late final IntroData _intro = _game.data.intro!;
  late final IntroTimeline _timeline = IntroTimeline(_intro);
  late final Ticker _ticker = createTicker(_onTick);

  String? _background;
  bool _rain = false;
  final List<IntroEvent> _lines = [];
  double _flash = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _background = _intro.background;
    _rain = _intro.rain;
    _audio.stopMusic();
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final ms = elapsed.inMilliseconds;
    for (final e in _timeline.advance(ms)) {
      _fire(e);
    }
    if (_flash > 0) setState(() => _flash = (_flash - 0.05).clamp(0, 1));
    if (_timeline.isOver(ms)) _finish();
  }

  void _fire(IntroEvent e) {
    switch (e.type) {
      case IntroEventType.text:
        // Ekranda son üç satır kalır.
        setState(() {
          _lines.add(e);
          if (_lines.length > 3) _lines.removeAt(0);
        });
      case IntroEventType.voice:
        _audio.playVoice(e.sound);
      case IntroEventType.sfx:
        _audio.playSfx(e.sound);
      case IntroEventType.music:
        _audio.playMusic(e.sound);
      case IntroEventType.stopMusic:
        _audio.stopMusic();
      case IntroEventType.shake:
        ScreenShake.of(context)?.shake(intensity: e.value ?? 8);
      case IntroEventType.flash:
        setState(() => _flash = 1);
      case IntroEventType.background:
        setState(() => _background = e.image);
      case IntroEventType.rain:
        setState(() => _rain = (e.value ?? 1) > 0);
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _ticker.stop();
    _audio.stopVoice();
    _game.markIntroSeen();
    if (widget.continueToInvestigation) {
      GameRoutes.replace(context, const InvestigationScreen());
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 900),
            child: KenBurns(
              key: ValueKey(_background),
              child: CaseImage(name: _background, label: 'Giriş arka planı'),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0xDD000000)],
              ),
            ),
          ),
          if (_rain) const RainOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, line) in _lines.indexed)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: i == _lines.length - 1 ? 1 : 0.45,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (line.speaker != null)
                              Text(
                                line.speaker!,
                                style: const TextStyle(
                                  color: AppTheme.brass,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            TypewriterText(
                              line.text ?? '',
                              key: ObjectKey(line),
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.4,
                                color: AppTheme.paper,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_flash > 0)
            IgnorePointer(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: _flash * 0.8),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: TextButton.icon(
                onPressed: _finish,
                icon: const Icon(Icons.skip_next),
                label: const Text('Atla'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
