import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Sahne üzerinde sürüklenen büyüteç: altındaki bölgeyi [zoom] kat büyütür.
/// [child], sahnenin büyütülecek görselidir (sahne boyutunda çizilir).
class MagnifierLens extends StatelessWidget {
  const MagnifierLens({
    super.key,
    required this.sceneSize,
    required this.center,
    required this.radius,
    required this.child,
    this.zoom = 2,
  });

  final Size sceneSize;

  /// Merceğin merkezi (piksel, sahneye göre).
  final Offset center;
  final double radius;
  final double zoom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final d = radius * 2;
    return Positioned(
      left: center.dx - radius,
      top: center.dy - radius,
      width: d + radius * 0.9,
      height: d + radius * 0.9,
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Sap: merceğin sağ altından çıkan pirinç çubuk.
            Positioned(
              left: d * 0.82,
              top: d * 0.82,
              child: Transform.rotate(
                angle: -pi / 4,
                alignment: Alignment.centerLeft,
                child: Container(
                  width: radius * 1.1,
                  height: radius * 0.28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A2A1A),
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: AppTheme.brass, width: 1.5),
                  ),
                ),
              ),
            ),
            // Gölge mercekten önce çizilir ki camı karartmasın.
            SizedBox(
              width: d,
              height: d,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
                ),
              ),
            ),
            SizedBox(
              width: d,
              height: d,
              child: ClipOval(
                child: Stack(
                  children: [
                    Positioned(
                      left: -(center.dx * zoom - radius),
                      top: -(center.dy * zoom - radius),
                      width: sceneSize.width * zoom,
                      height: sceneSize.height * zoom,
                      child: child,
                    ),
                    // Camın parlaması.
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(-0.4, -0.5),
                            radius: 0.9,
                            colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: d,
              height: d,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.brass, width: 4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
