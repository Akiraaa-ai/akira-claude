import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../widgets/case_image.dart';
import '../../widgets/effects/ken_burns.dart';
import '../../widgets/effects/rain_overlay.dart';
import '../case_select/case_select_screen.dart';
import '../settings/settings_screen.dart';

/// Genel (vakadan bağımsız) görsel ve ses adları.
class MenuAssets {
  static const background = 'menu_arkaplan';
  static const music = 'menu_muzik';
  static const tapSfx = 'dokunma';
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AudioService>().playMusic(MenuAssets.music);
  }

  Future<void> _open(Widget page, {String? name}) async {
    final audio = context.read<AudioService>();
    audio.playSfx(MenuAssets.tapSfx);
    await Navigator.of(context)
        .push(FadeRoute(page, settings: RouteSettings(name: name)));
    // Vakadan dönünce menü müziği yeniden başlasın.
    audio.playMusic(MenuAssets.music);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const KenBurns(
            child: CaseImage(
              name: MenuAssets.background,
              label: 'Ana menü arka planı',
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0xEE000000)],
              ),
            ),
          ),
          const RainOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Text(
                    'DEDEKTİF',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      letterSpacing: 8,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.paper,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Her ifade bir iz bırakır.',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: AppTheme.brass),
                  ),
                  const Spacer(flex: 3),
                  FilledButton(
                    onPressed: () => _open(
                      const CaseSelectScreen(),
                      name: caseListRouteName,
                    ),
                    child: const Text('Oyna'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                    onPressed: () => _open(const SettingsScreen()),
                    child: const Text('Ayarlar'),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
