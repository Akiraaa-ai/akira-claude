import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/case_data.dart';
import '../../services/audio_service.dart';
import '../../widgets/clue_card.dart';
import '../../widgets/effects/screen_shake.dart';
import '../game/game_controller.dart';

class BoardSounds {
  static const linked = 'ip_baglandi';
  static const wrong = 'yanlis';
}

/// Delil panosu: bulunan ipuçları mantar panoya iğnelenir, iki karta sırayla
/// dokunulunca aralarına kırmızı ip gerilir. Doğru bağlantı bir çıkarım açar.
class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  String? _selected;

  /// Sürüklenen kartın anlık yeri (bırakınca kaydedilir).
  final Map<String, Offset> _dragging = {};

  static const _cardH = 78.0;

  double _cardW(Size board) => min(120, board.width * 0.3);

  /// Kaydı olmayan kartlar üç sütunlu düzene dizilir.
  Offset _defaultPos(int i, Size board) {
    final wr = _cardW(board) / board.width;
    final gap = (1 - 3 * wr) / 4;
    final col = i % 3;
    final row = i ~/ 3;
    final y = 0.04 + row * ((_cardH + 22) / board.height);
    return Offset(gap + col * (wr + gap), min(y, 1 - _cardH / board.height));
  }

  Offset _posOf(GameController g, Clue c, int i, Size board) =>
      _dragging[c.id] ?? g.boardPosition(c.id) ?? _defaultPos(i, board);

  Future<void> _onCardTap(Clue clue) async {
    final first = _selected;
    if (first == null) {
      setState(() => _selected = clue.id);
      return;
    }
    setState(() => _selected = null);
    if (first == clue.id) return;
    final game = context.read<GameController>();
    final audio = context.read<AudioService>();
    final messenger = ScaffoldMessenger.of(context);
    switch (game.connect(first, clue.id)) {
      case ConnectResult.linked:
        audio.playSfx(BoardSounds.linked);
        await _showDeduction(game.lastConnection!);
      case ConnectResult.alreadyLinked:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Bu bağlantıyı zaten kurdun.')),
          );
      case ConnectResult.noLink:
        audio.playSfx(BoardSounds.wrong);
        ScreenShake.of(context)?.shake(intensity: 4);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Bu iki ipucu arasında bir bağ kuramadın.'),
            ),
          );
    }
  }

  Future<void> _showDeduction(BoardConnection c) {
    final game = context.read<GameController>();
    return showModalBottomSheet(
      context: context,
      builder: (s) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'BAĞLANTI KURULDU',
                style: TextStyle(
                  color: AppTheme.blood,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                c.clueIds.map((id) => game.data.clue(id).title).join('  ↔  '),
                style: const TextStyle(color: AppTheme.brass),
              ),
              const SizedBox(height: 12),
              Text(
                game.data.connectionText(c),
                style: const TextStyle(fontSize: 17, height: 1.45),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(s),
                child: const Text('Devam'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeductions() {
    final game = context.read<GameController>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (s) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (s, scroll) => DeductionList(game: game, controller: scroll),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final clues = game.boardClues;
    final total = game.data.connections.length;
    final found = game.foundConnections.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selected == null
                      ? 'İki ipucuna sırayla dokun, aralarına ip ger.'
                      : 'Şimdi bağlayacağın ikinci ipucuna dokun.',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              TextButton.icon(
                onPressed: found == 0 ? null : _showDeductions,
                icon: const Icon(Icons.lightbulb_outline, size: 18),
                label: Text('Çıkarımlar $found/$total'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 84),
            child: LayoutBuilder(
              builder: (context, box) {
                final board = box.biggest;
                final w = _cardW(board);
                Offset pin(String id) {
                  final i = clues.indexWhere((c) => c.id == id);
                  final p = _posOf(game, clues[i], i, board);
                  return Offset(
                    p.dx * board.width + w / 2,
                    p.dy * board.height + 8,
                  );
                }

                final strings = [
                  for (final c in game.foundConnections)
                    if (c.clueIds.every(game.isFound))
                      (pin(c.clueIds[0]), pin(c.clueIds[1])),
                ];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: CustomPaint(painter: _CorkPainter()),
                      ),
                      if (clues.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Pano boş. Sahnede ipucu buldukça buraya iğnelenir.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      for (final (i, c) in clues.indexed)
                        _positioned(game, c, i, board, w),
                      // İpler kartların üstünden geçer, iğneden iğneye.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(painter: _StringPainter(strings)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _positioned(GameController game, Clue c, int i, Size board, double w) {
    final p = _posOf(game, c, i, board);
    Offset clamp(Offset o) => Offset(
      o.dx.clamp(0.0, 1 - w / board.width),
      o.dy.clamp(0.0, 1 - _cardH / board.height),
    );
    return Positioned(
      left: p.dx * board.width,
      top: p.dy * board.height,
      width: w,
      height: _cardH,
      child: GestureDetector(
        key: ValueKey('board_${c.id}'),
        onTap: () => _onCardTap(c),
        onLongPress: () => showClueSheet(context, c, [
          for (final id in c.suspectIds) game.data.suspect(id).name,
        ]),
        onPanUpdate: (d) => setState(() {
          _dragging[c.id] = clamp(
            _posOf(game, c, i, board) +
                Offset(d.delta.dx / board.width, d.delta.dy / board.height),
          );
        }),
        onPanEnd: (_) {
          final pos = _dragging.remove(c.id);
          if (pos != null) game.moveBoardCard(c.id, pos);
        },
        child: _BoardCard(clue: c, selected: _selected == c.id),
      ),
    );
  }
}

/// Bulunan çıkarımların listesi (pano ve defterde).
class DeductionList extends StatelessWidget {
  const DeductionList({super.key, required this.game, this.controller});

  final GameController game;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Çıkarımlar',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: AppTheme.brass),
        ),
        const SizedBox(height: 8),
        for (final c in game.foundConnections)
          Card(
            child: ListTile(
              leading: const Icon(Icons.timeline, color: AppTheme.blood),
              title: Text(game.data.connectionText(c)),
              subtitle: Text(
                c.clueIds.map((id) => game.data.clue(id).title).join(' ↔ '),
              ),
            ),
          ),
      ],
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({required this.clue, required this.selected});

  final Clue clue;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    // Her kart kimliğine göre hafif eğik iğnelenir.
    final tilt = ((clue.id.hashCode % 7) - 3) * 0.012;
    return Transform.rotate(
      angle: tilt,
      child: AnimatedScale(
        scale: selected ? 1.06 : 1,
        duration: const Duration(milliseconds: 150),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.paper,
                  borderRadius: BorderRadius.circular(3),
                  border: selected
                      ? Border.all(color: AppTheme.blood, width: 3)
                      : null,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(2, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 14, 6, 4),
                  child: Text(
                    clue.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            // İğne.
            const Positioned(
              top: 2,
              left: 0,
              right: 0,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.3, -0.3),
                      colors: [Color(0xFFE57373), Color(0xFF7F1D1D)],
                    ),
                  ),
                  child: SizedBox(width: 12, height: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mantar pano dokusu: kahverengi zemin üzerinde sabit tohumlu benekler.
class _CorkPainter extends CustomPainter {
  const _CorkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF7A5634),
    );
    final r = Random(7);
    final dark = Paint()..color = const Color(0x55331F0E);
    final light = Paint()..color = const Color(0x33E8C9A0);
    final count = (size.width * size.height / 90).round();
    for (var i = 0; i < count; i++) {
      final o = Offset(
        r.nextDouble() * size.width,
        r.nextDouble() * size.height,
      );
      canvas.drawCircle(o, r.nextDouble() * 1.6 + 0.4, i.isEven ? dark : light);
    }
    // Kenarlarda gölge.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(
          radius: 0.9,
          colors: [Color(0x00000000), Color(0x66000000)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _CorkPainter oldDelegate) => false;
}

/// İğneden iğneye hafifçe sarkan kırmızı ipler.
class _StringPainter extends CustomPainter {
  _StringPainter(this.lines);

  final List<(Offset, Offset)> lines;

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = const Color(0x66000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final string = Paint()
      ..color = const Color(0xFFC62828)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in lines) {
      final mid = Offset.lerp(a, b, 0.5)!;
      final sag = 12 + (a - b).distance * 0.06;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy + sag, b.dx, b.dy);
      canvas.drawPath(path.shift(const Offset(1.5, 2.5)), shadow);
      canvas.drawPath(path, string);
    }
    final pin = Paint()..color = const Color(0xFF7F1D1D);
    for (final (a, b) in lines) {
      canvas.drawCircle(a, 3, pin);
      canvas.drawCircle(b, 3, pin);
    }
  }

  @override
  bool shouldRepaint(covariant _StringPainter old) => old.lines != lines;
}
