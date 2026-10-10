import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/motion.dart';

/// Metni harf harf yazan daktilo efekti. Dokununca metnin tamamı hemen görünür.
class TypewriterText extends StatefulWidget {
  const TypewriterText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.charDelay = const Duration(milliseconds: 28),
    this.onDone,
    this.onChar,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final Duration charDelay;
  final VoidCallback? onDone;

  /// Her harfte çağrılır (ör. daktilo tık sesi).
  final VoidCallback? onChar;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? _timer;
  int _shown = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _start();
    }
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _start();
  }

  void _start() {
    _timer?.cancel();
    if (!Motion.of(context) || widget.text.isEmpty) {
      _shown = widget.text.length;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onDone?.call(),
      );
      return;
    }
    _shown = 0;
    _timer = Timer.periodic(widget.charDelay, (_) {
      if (!mounted) return;
      setState(() => _shown++);
      if (_shown % 3 == 0) widget.onChar?.call();
      if (_shown >= widget.text.length) _finish();
    });
  }

  void _finish() {
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() => _shown = widget.text.length);
    widget.onDone?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _shown >= widget.text.length;
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: done ? null : _finish,
      // Görünmeyen kısım şeffaf çizilir, böylece satırlar zıplamaz.
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: widget.text.substring(0, _shown)),
            TextSpan(
              text: widget.text.substring(_shown),
              style: const TextStyle(color: Colors.transparent),
            ),
          ],
        ),
        style: style,
        textAlign: widget.textAlign,
      ),
    );
  }
}
