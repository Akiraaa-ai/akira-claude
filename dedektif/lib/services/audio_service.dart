import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'asset_catalog.dart';
import 'settings_service.dart';

/// Müzik, efekt ve seslendirme. Dosya yoksa ya da çalınamazsa sessizce geçer.
abstract class AudioService {
  Future<void> playMusic(String? name);
  Future<void> stopMusic();
  Future<void> playSfx(String? name);
  Future<void> playVoice(String? name);
  Future<void> stopVoice();
  Future<void> stopAll();
  void dispose();
}

/// Ses kapalıyken ya da testlerde kullanılan boş uygulama.
class SilentAudioService implements AudioService {
  final List<String> log = [];

  @override
  Future<void> playMusic(String? name) async => log.add('music:$name');
  @override
  Future<void> stopMusic() async => log.add('stopMusic');
  @override
  Future<void> playSfx(String? name) async => log.add('sfx:$name');
  @override
  Future<void> playVoice(String? name) async => log.add('voice:$name');
  @override
  Future<void> stopVoice() async => log.add('stopVoice');
  @override
  Future<void> stopAll() async => log.add('stopAll');
  @override
  void dispose() {}
}

/// audioplayers ile çalışan gerçek uygulama.
class AudioPlayersService implements AudioService {
  AudioPlayersService(this._catalog, this._settings) {
    _settings.addListener(_onSettingsChanged);
  }

  final AssetCatalog _catalog;
  final SettingsService _settings;
  final AudioPlayer _music = AudioPlayer(playerId: 'music');
  final AudioPlayer _voice = AudioPlayer(playerId: 'voice');
  final List<AudioPlayer> _sfxPool = [];
  String? _currentMusic;

  /// AudioCache 'assets/' önekini kendisi ekler.
  static String _relative(String path) => path.replaceFirst('assets/', '');

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Ses hatası (yok sayıldı): $e');
    }
  }

  @override
  Future<void> playMusic(String? name) async {
    final path = _catalog.audio(name);
    if (path == null) return;
    if (_currentMusic == path) return;
    _currentMusic = path;
    if (!_settings.music) return;
    await _safe(() async {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(0.6);
      await _music.play(AssetSource(_relative(path)));
    });
  }

  @override
  Future<void> stopMusic() async {
    _currentMusic = null;
    await _safe(_music.stop);
  }

  @override
  Future<void> playSfx(String? name) async {
    if (!_settings.sfx) return;
    final path = _catalog.audio(name);
    if (path == null) return;
    await _safe(() async {
      // Boştaki bir oynatıcıyı kullan, yoksa yenisini aç (en fazla 4).
      var player = _sfxPool
          .where((p) => p.state != PlayerState.playing)
          .firstOrNull;
      if (player == null && _sfxPool.length < 4) {
        player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        _sfxPool.add(player);
      }
      player ??= _sfxPool.first;
      await player.play(AssetSource(_relative(path)));
    });
  }

  @override
  Future<void> playVoice(String? name) async {
    if (!_settings.voice) return;
    final path = _catalog.audio(name);
    if (path == null) return;
    await _safe(() => _voice.play(AssetSource(_relative(path))));
  }

  @override
  Future<void> stopVoice() => _safe(_voice.stop);

  @override
  Future<void> stopAll() async {
    await stopMusic();
    await stopVoice();
    for (final p in _sfxPool) {
      await _safe(p.stop);
    }
  }

  void _onSettingsChanged() {
    if (!_settings.music) {
      _safe(_music.pause);
    } else if (_currentMusic != null) {
      final path = _currentMusic!;
      _safe(() async {
        await _music.setReleaseMode(ReleaseMode.loop);
        await _music.play(AssetSource(_relative(path)));
      });
    }
    if (!_settings.voice) _safe(_voice.stop);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _music.dispose();
    _voice.dispose();
    for (final p in _sfxPool) {
      p.dispose();
    }
  }
}
