import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../game/game_controller.dart';
import '../../widgets/clue_card.dart';

/// Dedektif defteri: olay özeti, toplanan ipuçları, yakalanan çelişkiler.
class NotebookScreen extends StatelessWidget {
  const NotebookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final clues = game.foundClues;
    final contradictions = game.foundContradictions;
    final h = Theme.of(context).textTheme.titleMedium
        ?.copyWith(color: AppTheme.brass);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (game.data.briefing.isNotEmpty) ...[
          Text('Olay', style: h),
          const SizedBox(height: 6),
          Text(game.data.briefing, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 20),
        ],
        Text(
          'İpuçları (${game.foundClueCount}/${game.totalClueCount})',
          style: h,
        ),
        const SizedBox(height: 6),
        if (clues.isEmpty)
          const Text(
            'Henüz ipucu yok. Sahneyi incele.',
            style: TextStyle(color: Colors.white54),
          ),
        for (final c in clues)
          ClueCard(
            key: ValueKey('note_${c.id}'),
            clue: c,
            suspectNames: [
              for (final id in c.suspectIds) game.data.suspect(id).name,
            ],
          ),
        const SizedBox(height: 20),
        Text('Çelişkiler (${contradictions.length})', style: h),
        const SizedBox(height: 6),
        if (contradictions.isEmpty)
          const Text(
            'Sorgularda ifadelere ipucu sunarak çelişki yakala.',
            style: TextStyle(color: Colors.white54),
          ),
        for (final q in contradictions)
          Card(
            child: ListTile(
              leading: const Icon(Icons.flash_on, color: AppTheme.blood),
              title: Text(game.data.suspect(q.suspectId).name),
              subtitle: Text(q.contradiction!.text),
            ),
          ),
      ],
    );
  }
}
