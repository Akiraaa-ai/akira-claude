import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/asset_catalog.dart';

/// `assets/images/<name>` varsa onu, yoksa isimli renkli yer tutucu kutuyu çizer.
class CaseImage extends StatelessWidget {
  const CaseImage({
    super.key,
    required this.name,
    this.label,
    this.fit = BoxFit.cover,
  });

  final String? name;

  /// Yer tutucuda dosya adının altında gösterilen açıklama.
  final String? label;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final path = context.read<AssetCatalog>().image(name);
    if (path != null) {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, _, _) => ImagePlaceholder(name: name, label: label),
      );
    }
    return ImagePlaceholder(name: name, label: label);
  }
}

/// İsimden türetilmiş sabit renkli yer tutucu.
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key, required this.name, this.label});

  final String? name;
  final String? label;

  static Color colorFor(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return HSLColor.fromAHSL(1, (h % 360).toDouble(), 0.35, 0.28).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final n = name ?? '?';
    final base = colorFor(n);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.black, 0.55)!],
        ),
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image_outlined, color: Colors.white38),
                Text(
                  n,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (label != null)
                  Text(
                    label!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
