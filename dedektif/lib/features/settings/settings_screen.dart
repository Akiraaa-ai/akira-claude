import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_services.dart';
import '../../services/purchase_service.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('İlerlemeyi sıfırla'),
        content: const Text(
          'Tüm vakalardaki ilerlemen silinecek. Satın aldığın paketler kalır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<AppServices>().progress.resetAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('İlerleme sıfırlandı.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final purchases = context.read<PurchaseService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Müzik'),
            value: settings.music,
            onChanged: settings.setMusic,
          ),
          SwitchListTile(
            title: const Text('Ses efektleri'),
            value: settings.sfx,
            onChanged: settings.setSfx,
          ),
          SwitchListTile(
            title: const Text('Seslendirme'),
            value: settings.voice,
            onChanged: settings.setVoice,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Satın alımları geri yükle'),
            onTap: () async {
              await purchases.restore();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Satın alımlar kontrol edildi.'),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('İlerlemeyi sıfırla'),
            onTap: () => _confirmReset(context),
          ),
        ],
      ),
    );
  }
}
