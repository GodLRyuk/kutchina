// lib/core/widgets/speedo_painter.dart
import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';

class SpeedoPainter extends CustomPainter {
  final double percent; // 0.0 - 1.0
  SpeedoPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 30;
    const startAngle = 3.14159; // 180deg
    const sweepAngle = 3.14159; // 180deg total
    const strokeW = 38.0;
    const borderW = strokeW + 4; // border peek 2px each side

    // track border
    final trackBorderPaint = Paint()
      ..color = AppColors.ink.withOpacity(0.15)
      ..strokeWidth = borderW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackBorderPaint,
    );

    final trackPaint = Paint()
      ..color = AppColors.productWaterPurifiers
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // progress border
    final progBorderPaint = Paint()
      ..color = AppColors.green.withOpacity(0.25)
      ..strokeWidth = borderW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * percent.clamp(0.0, 1.0),
      false,
      progBorderPaint,
    );

    final progPaint = Paint()
      ..color = AppColors.greenLight
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * percent.clamp(0.0, 1.0),
      false,
      progPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SpeedoPainter oldDelegate) =>
      oldDelegate.percent != percent;
}
