import 'dart:math' as math;

import 'package:flutter/material.dart';

class DonutChartPainter extends CustomPainter {
  final List<double> values; // percentages, need not sum to exactly 100
  final List<Color> colors;

  DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    final total = values.fold<double>(0, (a, b) => a + b);
    double startAngle = -math.pi / 2;

    for (var i = 0; i < values.length; i++) {
      final sweep = total == 0 ? 0.0 : (values[i] / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i]
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.butt
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => true;
}
