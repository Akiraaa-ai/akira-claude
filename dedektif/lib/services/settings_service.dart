import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ses ayarları. Değişince dinleyenlere (ses servisi, ayarlar ekranı) haber verir.
class SettingsService extends ChangeNotifier {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  bool get music => _prefs.getBool('settings.music') ?? true;
  bool get sfx => _prefs.getBool('settings.sfx') ?? true;
  bool get voice => _prefs.getBool('settings.voice') ?? true;

  Future<void> setMusic(bool v) => _set('settings.music', v);
  Future<void> setSfx(bool v) => _set('settings.sfx', v);
  Future<void> setVoice(bool v) => _set('settings.voice', v);

  Future<void> _set(String key, bool v) async {
    await _prefs.setBool(key, v);
    notifyListeners();
  }
}
