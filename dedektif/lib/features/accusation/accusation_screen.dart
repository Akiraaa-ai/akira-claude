import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../widgets/case_image.dart';
import '../game/game_controller.dart';
import '../game/game_routes.dart';
import '../result/result_screen.dart';

/// Suçlu seçimi: kim, neden ve (vakada istenirse) hangi kanıtla.
class AccusationScreen extends StatefulWidget {
  const AccusationScreen({super.key});

  @override
  State<AccusationScreen> createState() => _AccusationScreenState();
}

class _AccusationScreenState extends State<AccusationScreen> {
  String? _suspectId;
  String? _reasonId;
  final Set<String> _evidence = {};

  late final GameController _game = context.read<GameController>();
  late final AudioService _audio = context.read<AudioService>();

  @override
  void initState() {
    super.initState();
    _audio.playMusic(_game.data.music.tension);
  }

  @override
  void dispose() {
    // Gerilim müziğinden soruşturma müziğine geri dön (çözülünce sonuç ekranı kendi müziğini çalar).
    if (_game.lastAccusation?.solved != true) {
      _audio.playMusic(_game.data.music.investigation);
    }
    super.dispose();
  }

  Future<void> _confirm() async {
    final game = context.read<GameController>();
    final name = game.data.suspect(_suspectId!).name;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Emin misin?'),
        content: Text('$name kişisini suçlamak üzeresin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Suçla'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    game.accuse(_suspectId!, _reasonId, _evidence);
    await GameRoutes.replace(context, const ResultScreen());
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final reasons = game.data.solution.reasonOptions;
    final rule = game.data.solution.evidence;
    final ready =
        _suspectId != null &&
        (reasons.isEmpty || _reasonId != null) &&
        (rule == null || _evidence.length == rule.pick);

    return Scaffold(
      appBar: AppBar(title: const Text('Suçlu kim?')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '1. Şüpheliyi seç',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          // 4-6 şüpheli ekrana sığsın diye satır satır dizilir.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final s in game.data.suspects)
                GestureDetector(
                  key: ValueKey('accuse_${s.id}'),
                  onTap: () => setState(() => _suspectId = s.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 100,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _suspectId == s.id
                            ? AppTheme.blood
                            : Colors.white12,
                        width: _suspectId == s.id ? 3 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Expanded(
                          child: CaseImage(name: s.portrait, label: s.name),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            s.name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('2. Neden?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _reasonId,
              onChanged: (v) => setState(() => _reasonId = v),
              child: Column(
                children: [
                  for (final r in reasons)
                    Card(
                      child: RadioListTile<String>(
                        key: ValueKey('reason_${r.id}'),
                        value: r.id,
                        title: Text(r.text),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (rule != null) ...[
            const SizedBox(height: 20),
            Text(
              '${reasons.isEmpty ? 2 : 3}. Kanıtın ne?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Suçlamayı ispatlayan ${rule.pick} kanıt seç '
              '(${_evidence.length}/${rule.pick}).',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            for (final c in game.foundClues)
              Card(
                child: CheckboxListTile(
                  key: ValueKey('evidence_${c.id}'),
                  value: _evidence.contains(c.id),
                  onChanged:
                      _evidence.contains(c.id) || _evidence.length < rule.pick
                      ? (v) => setState(
                          () => v == true
                              ? _evidence.add(c.id)
                              : _evidence.remove(c.id),
                        )
                      : null,
                  title: Text(c.title),
                ),
              ),
          ],
          const SizedBox(height: 12),
          Text(
            'Yanlış suçlama ceza puanı verir ve yıldızını düşürür.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.blood),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: ready ? _confirm : null,
            icon: const Icon(Icons.gavel),
            label: const Text('Suçla'),
          ),
          const SizedBox(height: 8),
          Text(
            'Bulduğun ipucu: ${game.foundClueCount}/${game.totalClueCount}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
