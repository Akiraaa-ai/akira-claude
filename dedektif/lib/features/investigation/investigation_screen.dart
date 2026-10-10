import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/audio_service.dart';
import '../accusation/accusation_screen.dart';
import '../game/game_controller.dart';
import '../game/game_routes.dart';
import '../intro/intro_screen.dart';
import '../notebook/notebook_screen.dart';
import '../scene/scene_screen.dart';
import '../suspects/suspects_screen.dart';

/// Soruşturma merkezi: sahne, defter ve şüpheliler sekmeleri + suçlama düğmesi.
class InvestigationScreen extends StatefulWidget {
  const InvestigationScreen({super.key});

  @override
  State<InvestigationScreen> createState() => _InvestigationScreenState();
}

enum _MenuAction { replayIntro, restart }

class _InvestigationScreenState extends State<InvestigationScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final game = context.read<GameController>();
    context.read<AudioService>().playMusic(game.data.music.investigation);
  }

  Future<void> _onMenu(_MenuAction a) async {
    final game = context.read<GameController>();
    switch (a) {
      case _MenuAction.replayIntro:
        await GameRoutes.push(
          context,
          const IntroScreen(continueToInvestigation: false),
        );
        if (mounted) {
          context.read<AudioService>().playMusic(game.data.music.investigation);
        }
      case _MenuAction.restart:
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Vakayı baştan oyna'),
            content: const Text('Bulduğun ipuçları ve sorgular sıfırlanacak.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Baştan başla'),
              ),
            ],
          ),
        );
        if (ok == true) game.restart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(game.data.title),
        actions: [
          PopupMenuButton<_MenuAction>(
            onSelected: _onMenu,
            itemBuilder: (_) => [
              if (game.data.intro != null)
                const PopupMenuItem(
                  value: _MenuAction.replayIntro,
                  child: Text('Girişi tekrar izle'),
                ),
              const PopupMenuItem(
                value: _MenuAction.restart,
                child: Text('Vakayı baştan oyna'),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [SceneScreen(), NotebookScreen(), SuspectsScreen()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'accuse',
        onPressed: () => GameRoutes.push(context, const AccusationScreen()),
        icon: const Icon(Icons.gavel),
        label: const Text('Suçluyu seç'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.travel_explore),
            label: 'Sahne',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: game.foundClueCount,
              isLabelVisible: game.foundClueCount > 0,
              child: const Icon(Icons.menu_book),
            ),
            label: 'Defter',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: game.data.suspects.any(
                (s) => game.hasNewQuestions(s.id),
              ),
              child: const Icon(Icons.groups),
            ),
            label: 'Şüpheliler',
          ),
        ],
      ),
    );
  }
}
