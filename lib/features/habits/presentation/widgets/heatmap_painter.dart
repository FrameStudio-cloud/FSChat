import 'package:flutter/material.dart';

class HeatmapPainter extends CustomPainter {
  final Set<String> loggedDateStrings;
  final int weeksToShow;
  final Color activeColor;
  final Color emptyColor;

  HeatmapPainter({
    required this.loggedDateStrings,
    this.weeksToShow = 20,
    this.activeColor = const Color(0xFF075E54),
    this.emptyColor = const Color(0x1A000000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / (weeksToShow + 1);
    final cellGap = cellSize * 0.2;
    final cellDraw = cellSize - cellGap;
    final radius = cellDraw * 0.25;

    final today = DateTime.now();
    final endOfWeek = today.add(Duration(days: 6 - today.weekday));

    for (int w = 0; w < weeksToShow; w++) {
      for (int d = 0; d < 7; d++) {
        final date = endOfWeek
            .subtract(Duration(days: (weeksToShow - 1 - w) * 7 + (6 - d)));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        final x = (weeksToShow - w).toDouble() * cellSize + cellGap * 0.5;
        final y = d.toDouble() * cellSize + cellGap * 0.5;

        final isFuture = date.isAfter(today);
        final isLogged = loggedDateStrings.contains(dateStr);

        final paint = Paint()
          ..color = isFuture
              ? Colors.transparent
              : (isLogged ? activeColor : emptyColor)
          ..style = PaintingStyle.fill;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, cellDraw, cellDraw),
            Radius.circular(radius),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(HeatmapPainter oldDelegate) =>
      oldDelegate.loggedDateStrings != loggedDateStrings ||
      oldDelegate.activeColor != activeColor;
}
