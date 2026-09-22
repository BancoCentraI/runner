import 'dart:math';

import 'package:akillisletme/product/service/service_locator.dart';
import 'package:flutter/material.dart';

/// Arka plan animasyonu — yüzen "Flutter Starter Template" yazıları.
class HomeBackground extends StatefulWidget {
  const HomeBackground({super.key});

  static final enabledNotifier = ValueNotifier<bool>(
    locator.sharedCache.isBackgroundAnimationEnabled,
  );

  @override
  State<HomeBackground> createState() => _HomeBackgroundState();
}

class _HomeBackgroundState extends State<HomeBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FloatingText> _items;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 40),
      vsync: this,
    );

    if (HomeBackground.enabledNotifier.value) _controller.repeat(reverse: true);
    HomeBackground.enabledNotifier.addListener(_onToggle);

    final rng = Random(42);
    _items = List.generate(12, (i) {
      return _FloatingText(
        x: rng.nextDouble() * 1.4 - 0.2,
        y: rng.nextDouble(),
        speed: 0.15 + rng.nextDouble() * 0.35,
        opacity: 0.04 + rng.nextDouble() * 0.05,
        fontSize: 14.0 + rng.nextDouble() * 10,
        angle: 0,
      );
    });
  }

  void _onToggle() {
    if (HomeBackground.enabledNotifier.value) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
    setState(() {});
  }

  @override
  void dispose() {
    HomeBackground.enabledNotifier.removeListener(_onToggle);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!HomeBackground.enabledNotifier.value) return const SizedBox.shrink();

    final size = MediaQuery.sizeOf(context);
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: size,
          painter: _TextBackgroundPainter(
            progress: _controller.value,
            items: _items,
            color: cs.primary,
          ),
        );
      },
    );
  }
}

class _FloatingText {
  const _FloatingText({
    required this.x,
    required this.y,
    required this.speed,
    required this.opacity,
    required this.fontSize,
    required this.angle,
  });
  final double x;
  final double y;
  final double speed;
  final double opacity;
  final double fontSize;
  final double angle;
}

class _TextBackgroundPainter extends CustomPainter {
  _TextBackgroundPainter({
    required this.progress,
    required this.items,
    required this.color,
  });

  static const String _text = 'Flutter Starter Template';

  final double progress;
  final List<_FloatingText> items;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in items) {
      final yOffset = (item.y + progress * item.speed) % 1.3 - 0.15;
      final cx = item.x * size.width;
      final cy = yOffset * size.height;

      canvas
        ..save()
        ..translate(cx, cy)
        ..rotate(item.angle);

      final textStyle = TextStyle(
        color: color.withValues(alpha: item.opacity),
        fontSize: item.fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      );

      final tp = TextPainter(
        text: TextSpan(text: _text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TextBackgroundPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
