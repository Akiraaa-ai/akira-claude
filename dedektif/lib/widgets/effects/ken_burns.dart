import 'package:flutter/material.dart';

import '../../core/motion.dart';

/// Arka planda yavaş yakınlaşma ve kayma (Ken Burns efekti).
class KenBurns extends StatefulWidget {
  const KenBurns({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 24),
    this.maxScale = 1.12,
    this.drift = const Offset(-0.03, -0.02),
  });

  final Widget child;
  final Duration duration;
  final double maxScale;

  /// Kayma miktarı (genişliğin/yüksekliğin oranı olarak).
  final Offset drift;

  @override
  State<KenBurns> createState() => _KenBurnsState();
}

class _KenBurnsState extends State<KenBurns>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.of(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_c.value);
          final scale = 1 + (widget.maxScale - 1) * t;
          return FractionalTranslation(
            translation: widget.drift * t,
            child: Transform.scale(scale: scale, child: child),
          );
        },
      ),
    );
  }
}
