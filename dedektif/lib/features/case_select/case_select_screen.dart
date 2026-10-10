import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/app_services.dart';
import '../../services/purchase_service.dart';
import '../../widgets/case_image.dart';
import '../game/game_routes.dart';
import 'case_select_controller.dart';

class CaseSelectScreen extends StatelessWidget {
  const CaseSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppServices>();
    return ChangeNotifierProvider(
      create: (_) =>
          CaseSelectController(s.cases.loadAll, s.progress, s.purchases)
            ..load(),
      child: const _CaseSelectView(),
    );
  }
}

class _CaseSelectView extends StatelessWidget {
  const _CaseSelectView();

  Future<void> _onTap(BuildContext context, CaseEntry e) async {
    final c = context.read<CaseSelectController>();
    if (e.status == CaseStatus.locked) {
      await _showLocked(context, e);
      return;
    }
    await GameRoutes.openCase(
      context,
      e.data,
      playIntro: c.shouldPlayIntro(e.data),
    );
  }

  Future<void> _showLocked(BuildContext context, CaseEntry e) async {
    final c = context.read<CaseSelectController>();
    final price = await c.priceFor(e.data);
    if (!context.mounted) return;
    final buy = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(e.data.title),
        content: Text(
          'Bu vaka bir vaka paketiyle açılır.'
          '${price != null ? '\nFiyat: $price' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Kapat'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Paketi aç'),
          ),
        ],
      ),
    );
    if (buy != true || !context.mounted) return;
    final outcome = await c.buy(e.data);
    if (!context.mounted) return;
    final msg = switch (outcome) {
      PurchaseOutcome.success => 'Paket açıldı. İyi soruşturmalar!',
      PurchaseOutcome.cancelled => 'Satın alma iptal edildi.',
      PurchaseOutcome.unavailable => 'Mağaza şu an kullanılamıyor.',
      PurchaseOutcome.error => 'Satın alma tamamlanamadı.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CaseSelectController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Vakalar')),
      body: c.loading
          ? const Center(child: CircularProgressIndicator())
          : c.entries.isEmpty
          ? const Center(child: Text('Henüz vaka yok.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: c.entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final e = c.entries[i];
                return _CaseCard(entry: e, onTap: () => _onTap(context, e));
              },
            ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.entry, required this.onTap});

  final CaseEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = entry.data;
    final locked = entry.status == CaseStatus.locked;
    final badge = switch (entry.status) {
      CaseStatus.locked => const _Badge(Icons.lock, 'Kilitli', Colors.white54),
      CaseStatus.solved => _Badge(
        Icons.check_circle,
        'Çözüldü · ${entry.bestClueCount ?? 0} ipucu',
        AppTheme.brass,
      ),
      CaseStatus.inProgress => const _Badge(
        Icons.search,
        'Devam ediyor',
        Colors.lightBlueAccent,
      ),
      CaseStatus.fresh => const _Badge(
        Icons.fiber_new,
        'Yeni',
        Colors.greenAccent,
      ),
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CaseImage(name: d.coverImage, label: 'Kapak'),
                  if (locked) const ColoredBox(color: Color(0x99000000)),
                  if (locked)
                    const Center(
                      child: Icon(Icons.lock, size: 48, color: Colors.white70),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.title, style: Theme.of(context).textTheme.titleLarge),
                  if (d.subtitle.isNotEmpty)
                    Text(
                      d.subtitle,
                      style: const TextStyle(color: AppTheme.brass),
                    ),
                  if (d.summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      d.summary,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 8),
                  badge,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.icon, this.text, this.color);

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Text(text, style: TextStyle(color: color)),
    ],
  );
}
