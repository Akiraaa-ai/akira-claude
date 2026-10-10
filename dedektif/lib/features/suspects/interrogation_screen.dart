import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/case_data.dart';
import '../../services/audio_service.dart';
import '../../widgets/case_image.dart';
import '../../widgets/effects/screen_shake.dart';
import '../../widgets/effects/typewriter_text.dart';
import '../game/game_controller.dart';

class InterrogationSounds {
  static const contradiction = 'celiski';
  static const wrong = 'yanlis';
}

/// Sorgu ekranı: şüphelinin ifadesi, sorular ve ipucu sunarak çelişki yakalama.
class InterrogationScreen extends StatefulWidget {
  const InterrogationScreen({super.key, required this.suspectId});

  final String suspectId;

  @override
  State<InterrogationScreen> createState() => _InterrogationScreenState();
}

class _InterrogationScreenState extends State<InterrogationScreen> {
  String? _justAsked;

  void _ask(Interrogation q) {
    context.read<GameController>().ask(q.id);
    setState(() => _justAsked = q.id);
  }

  Future<void> _present(Interrogation q) async {
    final game = context.read<GameController>();
    final clue = await showModalBottomSheet<Clue>(
      context: context,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (c, scroll) => ListView(
          controller: scroll,
          children: [
            const ListTile(
              title: Text('Hangi ipucunu sunacaksın?'),
              subtitle: Text('İfadeyle çelişen kanıtı seç.'),
            ),
            for (final clue in game.foundClues)
              ListTile(
                key: ValueKey('present_${clue.id}'),
                leading: const Icon(Icons.description_outlined),
                title: Text(clue.title),
                subtitle: Text(
                  clue.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(c, clue),
              ),
          ],
        ),
      ),
    );
    if (clue == null || !mounted) return;
    final result = game.presentClue(q.id, clue.id);
    final audio = context.read<AudioService>();
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case PresentResult.contradiction:
        audio.playSfx(InterrogationSounds.contradiction);
        ScreenShake.of(context)?.shake(intensity: 10);
        await _showContradiction(q);
      case PresentResult.alreadyFound:
        messenger.showSnackBar(
          const SnackBar(content: Text('Bu çelişkiyi zaten yakaladın.')),
        );
      case PresentResult.needsMore:
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Bu kanıt işe yarıyor ama tek başına yetmiyor. Destekleyen bir kanıt daha bul.',
            ),
          ),
        );
      case PresentResult.noEffect:
        audio.playSfx(InterrogationSounds.wrong);
        messenger.showSnackBar(
          const SnackBar(content: Text('Bu ipucu bu ifadeyle çelişmiyor.')),
        );
    }
  }

  Future<void> _showContradiction(Interrogation q) {
    final game = context.read<GameController>();
    final con = q.contradiction!;
    final unlocked = con.unlocksClueId == null
        ? null
        : game.data.clue(con.unlocksClueId!);
    return showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text(
          'ÇELİŞKİ!',
          style: TextStyle(color: AppTheme.blood, letterSpacing: 3),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TypewriterText(con.text, style: const TextStyle(height: 1.4)),
            if (unlocked != null) ...[
              const SizedBox(height: 12),
              Text(
                'Deftere eklendi: ${unlocked.title}',
                style: const TextStyle(color: AppTheme.brass),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Devam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final s = game.data.suspect(widget.suspectId);
    final questions = game.questionsFor(s.id);
    final available = questions.where(game.isAvailable).toList();
    final lockedCount = questions.length - available.length;

    return Scaffold(
      appBar: AppBar(title: Text(s.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                height: 146,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CaseImage(name: s.portrait, label: s.name),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: Theme.of(context).textTheme.titleLarge),
                    Text(s.role, style: const TextStyle(color: AppTheme.brass)),
                    if (s.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        s.description,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'İFADE',
                    style: TextStyle(
                      color: AppTheme.brass,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '“${s.statement}”',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Sorular', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          for (final q in available)
            _QuestionCard(
              key: ValueKey('question_${q.id}'),
              q: q,
              asked: game.isAsked(q.id),
              animate: _justAsked == q.id,
              contradiction: game.hasContradiction(q.id),
              canPresent: game.foundClues.isNotEmpty,
              onAsk: () => _ask(q),
              onPresent: () => _present(q),
            ),
          if (lockedCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Yeni ipuçları buldukça $lockedCount soru daha açılacak.',
                style: const TextStyle(color: Colors.white54),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.q,
    required this.asked,
    required this.animate,
    required this.contradiction,
    required this.canPresent,
    required this.onAsk,
    required this.onPresent,
  });

  final Interrogation q;
  final bool asked;
  final bool animate;
  final bool contradiction;
  final bool canPresent;
  final VoidCallback onAsk;
  final VoidCallback onPresent;

  @override
  Widget build(BuildContext context) {
    const answerStyle = TextStyle(height: 1.4, color: AppTheme.paper);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, size: 18, color: AppTheme.brass),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    q.question,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (contradiction)
                  const Icon(Icons.flash_on, color: AppTheme.blood),
              ],
            ),
            const SizedBox(height: 8),
            if (!asked)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: onAsk,
                  child: const Text('Sor'),
                ),
              )
            else ...[
              animate
                  ? TypewriterText(q.answer, style: answerStyle)
                  : Text(q.answer, style: answerStyle),
              if (contradiction)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    q.contradiction!.text,
                    style: const TextStyle(color: AppTheme.blood),
                  ),
                )
              else if (canPresent)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onPresent,
                    icon: const Icon(Icons.front_hand_outlined),
                    label: const Text('İpucu sun'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
