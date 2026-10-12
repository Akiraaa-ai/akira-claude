import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 1–3 yıldız; [animate] açıksa yıldızlar sırayla belirir.
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.stars,
    this.size = 40,
    this.animate = false,
  });

  final int stars;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars yıldız',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: animate ? 0 : 1, end: 1),
              duration: Duration(milliseconds: animate ? 450 + i * 300 : 1),
              curve: Curves.easeOutBack,
              builder: (context, t, child) {
                // Her yıldız kendi sırası gelene kadar görünmez kalır.
                final local = animate
                    ? ((t * (450 + i * 300) - i * 300) / 450).clamp(0.0, 1.0)
                    : 1.0;
                return Transform.scale(scale: local, child: child);
              },
              child: Icon(
                i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: i < stars ? AppTheme.brass : Colors.white30,
              ),
            ),
        ],
      ),
    );
  }
}
