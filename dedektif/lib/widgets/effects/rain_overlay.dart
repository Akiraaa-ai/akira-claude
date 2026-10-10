import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/motion.dart';

/// Kodla çizilen yağmur parçacıkları. Dokunmaları engellemez.
class RainOverlay extends StatefulWidget {
  const RainOverlay({super.key, this.density = 140, this.wind = 0.18});

  /// Ekrandaki damla sayısı.
  final int density;

  /// Yatay eğim (0 = dik).
  final double wind;

  @override
  State<RainOverlay> createState() => _RainOverlayState();
}

class _Drop {
  _Drop(Random r) {
    reset(r, initial: true);
  }

  late double x, y, speed, length, opacity;

  void reset(Random r, {bool initial = false}) {
    x = r.nextDouble() * 1.2 - 0.1;
    y = initial ? r.nextDouble() : -r.nextDouble() * 0.2;
    speed = 0.9 + r.nextDouble() * 0.8; // ekran yüksekliği / saniye
    length = 0.025 + r.nextDouble() * 0.035;
    opacity = 0.15 + r.nextDouble() * 0.35;
  }
}

class _RainOverlayState extends State<RainOverlay>
    with SingleTickerProviderStateMixin {
  final _random = Random(7);
  late final List<_Drop> _drops = List.generate(
    widget.density,
    (_) => _Drop(_random),
  );
  late final Ticker _ticker = createTicker(_tick);
  final _repaint = ValueNotifier<int>(0);
  Duration _last = Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = Motion.of(context);
    if (on && !_ticker.isActive) _ticker.start();
    if (!on && _ticker.isActive) _ticker.stop();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    for (final d in _drops) {
      d.y += d.speed * dt;
      d.x += widget.wind * d.speed * dt;
      if (d.y - d.length > 1) d.reset(_random);
    }
    _repaint.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _RainPainter(_drops, widget.wind, _repaint),
        ),
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter(this.drops, this.wind, Listenable repaint)
    : super(repaint: repaint);

  final List<_Drop> drops;
  final double wind;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final d in drops) {
      paint.color = Colors.white.withValues(alpha: d.opacity);
      final x = d.x * size.width;
      final y = d.y * size.height;
      final len = d.length * size.height;
      canvas.drawLine(Offset(x, y), Offset(x - wind * len, y - len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => false;
}
