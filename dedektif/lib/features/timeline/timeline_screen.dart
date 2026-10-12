import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/case_data.dart';
import '../../services/audio_service.dart';
import '../game/game_controller.dart';

class TimelineSounds {
  static const solved = 'cizelge_tamam';
  static const wrong = 'yanlis';
}

/// Zaman çizelgesi: kim, saat kaçta, neredeydi? Oyuncu olay kartlarını
/// saatlere kendisi yerleştirir (sürükleyerek ya da kartı seçip saate dokunarak).
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  String? _selected;

  void _place(String eventId, String? slot) {
    context.read<GameController>().placeEvent(eventId, slot);
    setState(() => _selected = null);
  }

  void _check() {
    final game = context.read<GameController>();
    final correct = game.checkTimeline();
    final total = game.timelineEvents.length;
    final audio = context.read<AudioService>();
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (game.progress.timelineSolved) {
      audio.playSfx(TimelineSounds.solved);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Zaman çizelgesi doğru! Olaylar yerine oturdu.'),
        ),
      );
      return;
    }
    if (correct < total) audio.playSfx(TimelineSounds.wrong);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          correct == total
              ? 'Şimdilik hepsi doğru. Yeni ipuçlarıyla gelecek kartları da yerleştir.'
              : '$total karttan $correct tanesi doğru saatte.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final tl = game.data.timeline!;
    final events = game.timelineEvents;
    final unplaced = events.where((e) => game.placementOf(e.id) == null);
    final solved = game.progress.timelineSolved;
    final locked = game.lockedTimelineEvents;
    final allPlaced = events.isNotEmpty && unplaced.isEmpty;

    // Kart tepsisi üstte sabit durur, saatler altında kayar.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            solved ? 'Çizelge tamam: kim, ne zaman, neredeydi, hepsi yerinde.' : 'Kim, saat kaçta, neredeydi? Kartı seç ya da sürükle, doğru saate bırak.',
            style: TextStyle(color: solved ? AppTheme.brass : Colors.white70),
          ),
        ),
        if (!solved && unplaced.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in unplaced)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 180,
                        child: Draggable<String>(
                          data: e.id,
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: 180,
                              child: _EventCard(game: game, e: e, lifted: true),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _EventCard(game: game, e: e),
                          ),
                          child: GestureDetector(
                            key: ValueKey('tl_card_${e.id}'),
                            onTap: () => setState(
                              () => _selected = _selected == e.id ? null : e.id,
                            ),
                            child: _EventCard(
                              game: game,
                              e: e,
                              selected: _selected == e.id,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (!solved && events.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Henüz kart yok. İpucu buldukça olaylar buraya gelir.',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        if (!solved && locked > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'Yeni ipuçları buldukça $locked olay kartı daha gelecek.',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              for (final slot in tl.slots)
                _SlotRow(
                  key: ValueKey('tl_slot_$slot'),
                  slot: slot,
                  placed: [
                    for (final e in events)
                      if (game.placementOf(e.id) == slot) e,
                  ],
                  game: game,
                  locked: solved,
                  highlight: _selected != null,
                  onDrop: (id) => _place(id, slot),
                  onTapSlot: _selected == null
                      ? null
                      : () => _place(_selected!, slot),
                  // Seçili kart varsa bu saate gelir; yoksa dokunulan kart geri alınır.
                  onTapCard: (id) => _selected != null
                      ? _place(_selected!, slot)
                      : _place(id, null),
                ),
              if (!solved) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: allPlaced ? _check : null,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Kontrol et'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    super.key,
    required this.slot,
    required this.placed,
    required this.game,
    required this.locked,
    required this.highlight,
    required this.onDrop,
    required this.onTapSlot,
    required this.onTapCard,
  });

  final String slot;
  final List<TimelineEvent> placed;
  final GameController game;
  final bool locked;
  final bool highlight;
  final ValueChanged<String> onDrop;
  final VoidCallback? onTapSlot;
  final ValueChanged<String> onTapCard;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                slot,
                style: const TextStyle(
                  color: AppTheme.brass,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          // Dikey çizgi ve nokta.
          SizedBox(
            width: 18,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                const Positioned.fill(
                  child: Center(
                    child: VerticalDivider(width: 2, color: Colors.white24),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppTheme.brass,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: DragTarget<String>(
              onWillAcceptWithDetails: (_) => !locked,
              onAcceptWithDetails: (d) => onDrop(d.data),
              builder: (context, candidates, _) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTapSlot,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minHeight: 48),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: candidates.isNotEmpty || highlight
                          ? AppTheme.brass
                          : Colors.white12,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final e in placed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: GestureDetector(
                            key: ValueKey('tl_placed_${e.id}'),
                            onTap: locked ? null : () => onTapCard(e.id),
                            child: _EventCard(game: game, e: e, done: locked),
                          ),
                        ),
                      if (placed.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Buraya bırak',
                            style: TextStyle(color: Colors.white24),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.game,
    required this.e,
    this.selected = false,
    this.lifted = false,
    this.done = false,
  });

  final GameController game;
  final TimelineEvent e;
  final bool selected;
  final bool lifted;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final who = e.suspectId == null
        ? null
        : game.data.suspect(e.suspectId!).name;
    final header = [?who, ?e.place].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected
              ? AppTheme.blood
              : done
              ? AppTheme.brass
              : Colors.transparent,
          width: 2.5,
        ),
        boxShadow: lifted
            ? const [BoxShadow(color: Colors.black54, blurRadius: 12)]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header.isNotEmpty)
            Text(
              header,
              style: const TextStyle(
                color: Color(0xFF7A4E1E),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            e.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 13,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
