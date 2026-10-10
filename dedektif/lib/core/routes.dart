import 'package:flutter/material.dart';

/// Ekranlar arası yumuşak kararma geçişi (fade).
class FadeRoute<T> extends PageRouteBuilder<T> {
  FadeRoute(
    Widget page, {
    Duration duration = const Duration(milliseconds: 450),
    super.settings,
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         pageBuilder: (_, _, _) => page,
         transitionsBuilder: (_, animation, _, child) {
           // Önce karart, sonra yeni ekranı aç: siyah üzerinden geçiş hissi.
           final curved = CurvedAnimation(
             parent: animation,
             curve: Curves.easeInOut,
           );
           return ColoredBox(
             color: Colors.black,
             child: FadeTransition(opacity: curved, child: child),
           );
         },
       );
}

/// Vaka listesi rotasının adı; sonuç ekranından buraya dönülür.
const caseListRouteName = 'vakalar';
