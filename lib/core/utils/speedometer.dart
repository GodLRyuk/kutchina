import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';

class SpeedoPainter extends CustomPainter {
  final double percent; // 0.0 - 1.0
  SpeedoPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = math.min(size.width / 2 - 36, center.dy - 26);
    const strokeWidth = 28.0;
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawArc(arcRect, math.pi, math.pi, false, trackPaint);

    const arcColors = [
      Color(0xFFFF2938),
      Color(0xFFFF7800),
      Color(0xFFFFC400),
      Color(0xFF8CD500),
      Color(0xFF00B58D),
    ];
    final gradientPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: math.pi,
        endAngle: math.pi * 2,
        colors: arcColors,
        stops: [0, 0.25, 0.5, 0.75, 1],
      ).createShader(arcRect)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;
    canvas.drawArc(arcRect, math.pi, math.pi, false, gradientPaint);

    final tickPaint = Paint()
      ..color = AppColors.steelLight
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    for (var index = 0; index <= 20; index++) {
      final angle = math.pi + math.pi * index / 20;
      final isMajorTick = index % 5 == 0;
      final outer = Offset(
        center.dx + math.cos(angle) * (radius - 21),
        center.dy + math.sin(angle) * (radius - 21),
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - (isMajorTick ? 36 : 29)),
        center.dy + math.sin(angle) * (radius - (isMajorTick ? 36 : 29)),
      );
      canvas.drawLine(outer, inner, tickPaint);
    }

    for (final fraction in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final angle = math.pi + math.pi * fraction;
      final labelPosition = Offset(
        center.dx + math.cos(angle) * (radius + 24),
        center.dy + math.sin(angle) * (radius + 24),
      );
      final labelPainter = TextPainter(
        text: TextSpan(
          text: '${(fraction * 100).round()}%',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.steel,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(
          labelPosition.dx - labelPainter.width / 2,
          labelPosition.dy - labelPainter.height / 2,
        ),
      );
    }

    final progress = percent.clamp(0.0, 1.0).toDouble();
    final needleAngle = math.pi + math.pi * progress;
    final direction = Offset(math.cos(needleAngle), math.sin(needleAngle));
    // Increase 0.30 to move the pivot up; decrease it to move the pivot down.
    final needleCenter = center + Offset(0, -radius * 0.30);
    // Keep the tip on the same 0–100 scale as the dial's major ticks.
    final needleTip = center + direction * (radius - 36);
    final needleVector = needleTip - needleCenter;
    final needleLength = needleVector.distance;
    final normal = Offset(
      -needleVector.dy / needleLength,
      needleVector.dx / needleLength,
    );
    final needlePath = Path()
      ..moveTo(
        needleCenter.dx + normal.dx * 2.2,
        needleCenter.dy + normal.dy * 2.2,
      )
      ..lineTo(needleTip.dx, needleTip.dy)
      ..lineTo(
        needleCenter.dx - normal.dx * 2.2,
        needleCenter.dy - normal.dy * 2.2,
      )
      ..close();
    canvas.drawPath(needlePath, Paint()..color = AppColors.ink);
    canvas.drawCircle(needleCenter, 7, Paint()..color = AppColors.ink);
    canvas.drawCircle(
      needleCenter,
      1,
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant SpeedoPainter oldDelegate) =>
      oldDelegate.percent != percent;
}
