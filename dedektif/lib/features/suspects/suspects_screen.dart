import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../widgets/case_image.dart';
import '../game/game_controller.dart';
import '../game/game_routes.dart';
import 'interrogation_screen.dart';

/// Şüpheli listesi. Yeni sorusu olan şüpheli işaretlenir.
class SuspectsScreen extends StatelessWidget {
  const SuspectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: game.data.suspects.length,
      itemBuilder: (context, i) {
        final s = game.data.suspects[i];
        return Card(
          key: ValueKey('suspect_${s.id}'),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () =>
                GameRoutes.push(context, InterrogationScreen(suspectId: s.id)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CaseImage(name: s.portrait, label: s.name),
                      if (game.hasNewQuestions(s.id))
                        const Positioned(
                          top: 6,
                          right: 6,
                          child: Badge(label: Text('Yeni soru')),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        s.role,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.brass,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
