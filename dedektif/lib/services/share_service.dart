import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// Sonuç paylaşımı (Android paylaşım menüsü).
abstract class ShareService {
  Future<void> shareText(String text);
}

class SystemShareService implements ShareService {
  @override
  Future<void> shareText(String text) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (e) {
      debugPrint('Paylaşım hatası: $e');
    }
  }
}

/// Testlerde paylaşılan metni kaydeder.
class RecordingShareService implements ShareService {
  final List<String> shared = [];

  @override
  Future<void> shareText(String text) async => shared.add(text);
}
