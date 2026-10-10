import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../services/app_services.dart';
import '../../widgets/case_image.dart';
import '../../widgets/effects/ken_burns.dart';
import '../../widgets/effects/screen_shake.dart';
import '../../widgets/effects/typewriter_text.dart';
import '../game/game_controller.dart';

class ResultSounds {
  static const solved = 'cozuldu';
  static const wrong = 'yanlis_suclama';
}

/// Sonuç: doğruysa final sahnesi + istatistik + paylaş; yanlışsa yanlış cevap sahnesi.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final GameController _game = context.read<GameController>();
  late final bool _solved = _game.lastAccusation?.solved ?? false;

  /// Final paragrafları tek tek açılır; hepsi bitince özet gösterilir.
  int _paragraph = 0;

  List<String> get _paragraphs {
    if (_solved) return _game.data.solution.finale.paragraphs;
    final w = _game.data.wrongAnswer;
    final culpritRight = _game.lastAccusation?.culpritCorrect ?? false;
    if (culpritRight && w.wrongReasonText != null) return [w.wrongReasonText!];
    return w.paragraphs;
  }

  bool get _storyDone => _paragraph >= _paragraphs.length - 1;

  @override
  void initState() {
    super.initState();
    final audio = context.read<AppServices>().audio;
    if (_solved) {
      audio.playMusic(_game.data.music.finale);
      audio.playSfx(ResultSounds.solved);
    } else {
      audio.playSfx(ResultSounds.wrong);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ScreenShake.of(context)?.shake(intensity: 12),
      );
    }
  }

  void _next() {
    if (!_storyDone) setState(() => _paragraph++);
  }

  @override
  Widget build(BuildContext context) {
    final data = _game.data;
    final title = _solved
        ? (data.solution.finale.title.isNotEmpty
              ? data.solution.finale.title
              : 'Vaka çözüldü')
        : (data.wrongAnswer.title.isNotEmpty
              ? data.wrongAnswer.title
              : 'Yanlış suçlama');
    final image = _solved ? data.solution.finale.image : data.wrongAnswer.image;
    final paragraphs = _paragraphs;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          KenBurns(
            child: CaseImage(
              name: image,
              label: _solved ? 'Final görseli' : 'Yanlış cevap görseli',
            ),
          ),
          const ColoredBox(color: Color(0xB3000000)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _solved ? AppTheme.brass : AppTheme.blood,
                  ),
                ),
                const SizedBox(height: 20),
                for (var i = 0; i <= _paragraph && i < paragraphs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: i == _paragraph
                        ? TypewriterText(
                            paragraphs[i],
                            key: ValueKey('p$i'),
                            style: const TextStyle(fontSize: 17, height: 1.5),
                          )
                        : Text(
                            paragraphs[i],
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.5,
                              color: Colors.white70,
                            ),
                          ),
                  ),
                if (!_storyDone)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _next,
                      child: const Text('Devam ›'),
                    ),
                  )
                else if (_solved)
                  _SolvedSummary(game: _game)
                else
                  _WrongActions(game: _game),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SolvedSummary extends StatelessWidget {
  const _SolvedSummary({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    final s = game.data.solution;
    final p = game.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Stat(
                  'Bulunan ipucu',
                  '${game.foundClueCount}/${game.totalClueCount}',
                ),
                _Stat(
                  'Yakalanan çelişki',
                  '${p.contradictionIds.length}/${game.data.interrogations.where((q) => q.contradiction != null).length}',
                ),
                _Stat('Yanlış suçlama', '${p.wrongAttempts}'),
                if (p.hintsUsed > 0)
                  _Stat('Kullanılan ipucu yardımı', '${p.hintsUsed}'),
              ],
            ),
          ),
        ),
        if (s.explanation.isNotEmpty || s.deductionChain.isNotEmpty)
          Card(
            child: ExpansionTile(
              title: const Text('Çıkarım zinciri'),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s.explanation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      s.explanation,
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                for (final (i, step) in s.deductionChain.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${i + 1}. $step',
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () =>
              context.read<AppServices>().share.shareText(game.shareText()),
          icon: const Icon(Icons.share),
          label: const Text('Paylaş'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(
            context,
          ).popUntil((r) => r.settings.name == caseListRouteName || r.isFirst),
          child: const Text('Vakalara dön'),
        ),
      ],
    );
  }
}

class _WrongActions extends StatelessWidget {
  const _WrongActions({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Dosya henüz kapanmadı. İpuçlarını ve ifadeleri yeniden gözden geçir.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Soruşturmaya dön'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.brass,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
