import 'dart:math';

import 'package:flutter/material.dart';

/// Gerilimli anlarda alt ağacı kısa süre titretir.
/// Kullanım: `ScreenShake.of(context)?.shake();`
class ScreenShake extends StatefulWidget {
  const ScreenShake({super.key, required this.child});

  final Widget child;

  static ScreenShakeState? of(BuildContext context) =>
      context.findAncestorStateOfType<ScreenShakeState>();

  @override
  State<ScreenShake> createState() => ScreenShakeState();
}

class ScreenShakeState extends State<ScreenShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  double _intensity = 8;

  /// [intensity] piksel cinsinden en büyük sapma.
  void shake({double intensity = 8}) {
    _intensity = intensity;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        if (!_c.isAnimating) return child!;
        final t = _c.value;
        final decay = 1 - t;
        final dx = sin(t * pi * 10) * _intensity * decay;
        final dy = cos(t * pi * 7) * _intensity * 0.4 * decay;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
    );
  }
}
