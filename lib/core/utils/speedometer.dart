// lib/core/widgets/speedo_painter.dart
import 'dart:math' as math; // ← add this, needed for needle angle math
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
    const borderW = strokeW + 4;

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

    // ---- needle (clock-hand style, tracks same percent) ----
    final needleAngle = startAngle + sweepAngle * percent.clamp(0.0, 1.0);
    final needleLen = radius - (strokeW / 2) - 6; // stop short of arc band
    final needleEnd = Offset(
      center.dx + needleLen * math.cos(needleAngle),
      center.dy + needleLen * math.sin(needleAngle),
    );

    final needleShadowPaint = Paint()
      ..color = AppColors.ink.withOpacity(0.15)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needleShadowPaint);

    final needlePaint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);

    // hub
    canvas.drawCircle(center, 8, Paint()..color = AppColors.ink);
    canvas.drawCircle(
      center,
      8,
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant SpeedoPainter oldDelegate) =>
      oldDelegate.percent != percent;
}
