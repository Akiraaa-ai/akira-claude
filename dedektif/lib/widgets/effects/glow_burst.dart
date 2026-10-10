import 'package:flutter/material.dart';

/// İpucu bulununca alanın üzerinde bir kez yanıp sönen sıcak parlama.
class GlowBurst extends StatefulWidget {
  const GlowBurst({
    super.key,
    this.onDone,
    this.color = const Color(0xFFFFE08A),
  });

  final VoidCallback? onDone;
  final Color color;

  @override
  State<GlowBurst> createState() => _GlowBurstState();
}

class _GlowBurstState extends State<GlowBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward().whenComplete(() => widget.onDone?.call());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // Hızlı parlayıp yavaş sönen opaklık, genişleyen hale.
          final opacity = t < 0.25 ? t / 0.25 : 1 - (t - 0.25) / 0.75;
          return Transform.scale(
            scale: 0.8 + t * 0.9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.color.withValues(alpha: 0.85 * opacity),
                    widget.color.withValues(alpha: 0.25 * opacity),
                    widget.color.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Ödüllü ipucunda bulunmamış alanı birkaç kez nabız gibi işaretler.
class HintPulse extends StatefulWidget {
  const HintPulse({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  State<HintPulse> createState() => _HintPulseState();
}

class _HintPulseState extends State<HintPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _c.reverse();
      } else if (s == AnimationStatus.dismissed) {
        if (++_count >= 4) {
          widget.onDone?.call();
        } else {
          _c.forward();
        }
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.amberAccent.withValues(alpha: 0.3 + 0.7 * _c.value),
              width: 2 + 2 * _c.value,
            ),
          ),
        ),
      ),
    );
  }
}
