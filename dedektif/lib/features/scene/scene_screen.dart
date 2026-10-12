import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/case_data.dart';
import '../../services/app_services.dart';
import '../../services/asset_catalog.dart';
import '../../widgets/case_image.dart';
import '../../widgets/clue_card.dart';
import '../../widgets/effects/glow_burst.dart';
import '../../widgets/effects/rain_overlay.dart';
import '../../widgets/magnifier_lens.dart';
import '../game/game_controller.dart';

/// Ses efekti adları (assets/audio altında).
class SceneSounds {
  static const clueFound = 'ipucu_bulundu';
  static const tap = 'dokunma';
}

/// Sahne gezme: büyüteçle sahne taranır, görseldeki alanlara dokunarak ipucu toplanır.
class SceneScreen extends StatefulWidget {
  const SceneScreen({super.key});

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> {
  int _sceneIndex = 0;
  final Set<String> _glowing = {};
  String? _hintClueId;

  /// Büyütecin merkezi, sahnenin oranı olarak (0..1).
  Offset _lens = const Offset(0.5, 0.45);

  static const _lensRadiusRatio = 0.17;

  void _moveLens(Offset local, Size box) => setState(
    () => _lens = Offset(
      (local.dx / box.width).clamp(0.0, 1.0),
      (local.dy / box.height).clamp(0.0, 1.0),
    ),
  );

  /// İpucu alanının merkezi büyüteç camının içinde mi.
  bool _underLens(HotArea a, Size box) {
    final c = Offset((a.x + a.w / 2) * box.width, (a.y + a.h / 2) * box.height);
    final lens = Offset(_lens.dx * box.width, _lens.dy * box.height);
    return (c - lens).distance <= box.width * _lensRadiusRatio;
  }

  List<String> _suspectNames(GameController g, Clue c) => [
    for (final id in c.suspectIds) g.data.suspect(id).name,
  ];

  void _onClueTap(Clue clue, Size box) {
    final game = context.read<GameController>();
    // Küçük ayrıntılar ancak büyüteç üzerindeyken görülür.
    if (clue.needsMagnifier &&
        !game.isFound(clue.id) &&
        !_underLens(clue.area!, box)) {
      final a = clue.area!;
      _moveLens(
        Offset((a.x + a.w / 2) * box.width, (a.y + a.h / 2) * box.height),
        box,
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Burada bir şey var gibi. Büyüteçle yakından bak.'),
          ),
        );
      return;
    }
    final isNew = game.collectClue(clue.id);
    if (isNew) {
      context.read<AppServices>().audio.playSfx(SceneSounds.clueFound);
      setState(() {
        _glowing.add(clue.id);
        if (_hintClueId == clue.id) _hintClueId = null;
      });
    }
    showClueSheet(context, clue, _suspectNames(game, clue), isNew: isNew);
  }

  Future<void> _askHint(Scene scene) async {
    final s = context.read<AppServices>();
    final game = context.read<GameController>();
    final messenger = ScaffoldMessenger.of(context);
    if (game.foundInScene(scene.id) == game.cluesInScene(scene.id).length) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Bu sahnedeki tüm ipuçlarını buldun.')),
      );
      return;
    }
    // Önce reklamsız ipucu hakkı harcanır, bitince ödüllü reklam istenir.
    final earned = game.spendFreeHint() || await s.ads.showRewarded();
    if (!mounted) return;
    if (!earned) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Reklam şu an hazır değil, biraz sonra tekrar dene.'),
        ),
      );
      return;
    }
    setState(() => _hintClueId = game.hintFor(scene.id)?.id);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final scenes = game.data.scenes;
    final scene = scenes[_sceneIndex.clamp(0, scenes.length - 1)];
    // Görsel yoksa (yer tutucu) büyüteç altındaki alanlar daha belirgin çizilir.
    final placeholderMode =
        context.read<AssetCatalog>().image(scene.image) == null;
    final clues = game.cluesInScene(scene.id);

    return Column(
      children: [
        if (scenes.length > 1)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final (i, s) in scenes.indexed)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${s.title} ${game.foundInScene(s.id)}/${game.cluesInScene(s.id).length}',
                      ),
                      selected: i == _sceneIndex,
                      onSelected: (_) => setState(() {
                        _sceneIndex = i;
                        _hintClueId = null;
                      }),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: LayoutBuilder(
                builder: (context, box) {
                  final size = box.biggest;
                  Rect rectOf(HotArea a) => Rect.fromLTWH(
                    a.x * size.width,
                    a.y * size.height,
                    a.w * size.width,
                    a.h * size.height,
                  );
                  final image = CaseImage(
                    name: scene.image,
                    label: scene.title,
                  );
                  return GestureDetector(
                    key: const ValueKey('scene_area'),
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) => _moveLens(d.localPosition, size),
                    onPanUpdate: (d) => _moveLens(d.localPosition, size),
                    onTapUp: (d) => _moveLens(d.localPosition, size),
                    child: ClipRect(
                      child: Stack(
                        children: [
                          Positioned.fill(child: image),
                          if (scene.rain)
                            const Positioned.fill(
                              child: RainOverlay(density: 90),
                            ),
                          MagnifierLens(
                            sceneSize: size,
                            center: Offset(
                              _lens.dx * size.width,
                              _lens.dy * size.height,
                            ),
                            radius: size.width * _lensRadiusRatio,
                            child: image,
                          ),
                          for (final clue in clues)
                            Positioned.fromRect(
                              rect: rectOf(clue.area!),
                              child: _HotSpot(
                                key: ValueKey('hotspot_${clue.id}'),
                                found: game.isFound(clue.id),
                                revealed: _underLens(clue.area!, size),
                                strong: placeholderMode,
                                label: game.isFound(clue.id) ? clue.title : '?',
                                onTap: () => _onClueTap(clue, size),
                              ),
                            ),
                          for (final clue in clues.where(
                            (c) => c.id == _hintClueId,
                          ))
                            Positioned.fromRect(
                              rect: rectOf(clue.area!).inflate(6),
                              child: HintPulse(
                                onDone: () =>
                                    setState(() => _hintClueId = null),
                              ),
                            ),
                          for (final clue in clues.where(
                            (c) => _glowing.contains(c.id),
                          ))
                            Positioned.fromRect(
                              rect: Rect.fromCenter(
                                center: rectOf(clue.area!).center,
                                width: 160,
                                height: 160,
                              ),
                              child: GlowBurst(
                                onDone: () =>
                                    setState(() => _glowing.remove(clue.id)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (scene.description.isNotEmpty)
                      Text(
                        scene.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    Text(
                      'Bulunan ipucu: ${game.foundInScene(scene.id)}/${clues.length}',
                      style: const TextStyle(color: AppTheme.brass),
                    ),
                  ],
                ),
              ),
              Badge.count(
                count: game.freeHintsLeft,
                isLabelVisible: game.freeHintsLeft > 0,
                child: IconButton.filledTonal(
                  tooltip: game.freeHintsLeft > 0
                      ? 'İpucu (${game.freeHintsLeft} hak)'
                      : 'İpucu (reklam izle)',
                  onPressed: () => _askHint(scene),
                  icon: const Icon(Icons.lightbulb_outline),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HotSpot extends StatelessWidget {
  const _HotSpot({
    super.key,
    required this.found,
    required this.revealed,
    required this.strong,
    required this.label,
    required this.onTap,
  });

  final bool found;

  /// Büyüteç altında: bulunmamış alan çerçevesiyle belli olur.
  final bool revealed;

  /// Yer tutucu görselde çerçeve ve etiket daha belirgin çizilir.
  final bool strong;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final show = found || revealed;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: !show
          ? const SizedBox.expand()
          : DecoratedBox(
              decoration: BoxDecoration(
                color: strong && revealed ? Colors.black26 : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: found ? AppTheme.brass : Colors.amberAccent,
                  width: found ? 2 : 1.5,
                ),
              ),
              child: strong && revealed
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: FittedBox(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: found
                                  ? AppTheme.brass
                                  : Colors.amberAccent,
                            ),
                          ),
                        ),
                      ),
                    )
                  : !found
                  ? const SizedBox.expand()
                  : const Align(
                      alignment: Alignment.topRight,
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppTheme.brass,
                      ),
                    ),
            ),
    );
  }
}
