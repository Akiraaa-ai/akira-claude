import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/case_data.dart';
import 'case_image.dart';

/// Defterde ve bulunma anında gösterilen ipucu kartı.
class ClueCard extends StatelessWidget {
  const ClueCard({
    super.key,
    required this.clue,
    required this.suspectNames,
    this.isNew = false,
  });

  final Clue clue;
  final List<String> suspectNames;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isNew)
              const Text(
                'YENİ İPUCU',
                style: TextStyle(
                  color: AppTheme.brass,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
            Text(clue.title, style: Theme.of(context).textTheme.titleMedium),
            if (clue.image != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                width: double.infinity,
                child: CaseImage(name: clue.image, label: 'Yakın çekim'),
              ),
            ],
            const SizedBox(height: 6),
            Text(clue.description, style: const TextStyle(height: 1.4)),
            if (suspectNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final n in suspectNames)
                    Chip(
                      label: Text(n),
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.person, size: 16),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// İpucu kartını alt sayfada açar.
Future<void> showClueSheet(
  BuildContext context,
  Clue clue,
  List<String> suspectNames, {
  bool isNew = false,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ClueCard(clue: clue, suspectNames: suspectNames, isNew: isNew),
      ),
    ),
  );
}
