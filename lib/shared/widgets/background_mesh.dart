import 'dart:math';
import 'package:flutter/material.dart';

class BackgroundMesh extends StatelessWidget {
  final Widget child;
  final double opacity;
  final Color? dotColor;

  const BackgroundMesh({
    super.key,
    required this.child,
    this.opacity = 0.03,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = dotColor ?? cs.onSurface;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _MeshPainter(color: color, opacity: opacity),
          ),
        ),
        child,
      ],
    );
  }
}

class _MeshPainter extends CustomPainter {
  final Color color;
  final double opacity;

  _MeshPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final rng = Random(42);
    const spacing = 32.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final jitter = rng.nextDouble() * 4 - 2;
        final radius = 0.8 + rng.nextDouble() * 0.6;
        canvas.drawCircle(Offset(x + jitter, y + jitter), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter o) =>
      o.color != color || o.opacity != opacity;
}
