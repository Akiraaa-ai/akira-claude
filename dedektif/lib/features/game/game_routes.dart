import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes.dart';
import '../../models/case_data.dart';
import '../../services/app_services.dart';
import '../intro/intro_screen.dart';
import '../investigation/investigation_screen.dart';
import 'game_controller.dart';

/// Vaka ekranları arasında aynı GameController'ı taşıyan rota yardımcıları.
class GameRoutes {
  static Route<T> route<T>(GameController controller, Widget page) =>
      FadeRoute<T>(
        ChangeNotifierProvider.value(value: controller, child: page),
      );

  /// Vakayı açar: gerekiyorsa önce giriş sahnesi, sonra soruşturma.
  static Future<void> openCase(
    BuildContext context,
    CaseData data, {
    required bool playIntro,
  }) {
    final controller = GameController(
      data,
      context.read<AppServices>().progress,
    );
    final first = playIntro && data.intro != null
        ? const IntroScreen(continueToInvestigation: true)
        : const InvestigationScreen();
    return Navigator.of(context).push(route(controller, first));
  }

  static Future<T?> push<T>(BuildContext context, Widget page) =>
      Navigator.of(context)
          .push<T>(route(context.read<GameController>(), page));

  static Future<void> replace(BuildContext context, Widget page) =>
      Navigator.of(context)
          .pushReplacement(route(context.read<GameController>(), page));
}
