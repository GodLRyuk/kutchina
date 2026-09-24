import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_bar.dart';

class AdminRegionsScreen extends StatelessWidget {
  const AdminRegionsScreen({super.key});

  static const _regions = [
    {
      'name': 'Kolkata',
      'value': '₹18.6L',
      'percent': 38.0,
      'color': AppColors.regionBlue,
      'dealers': 42,
    },
    {
      'name': 'Howrah & Hooghly',
      'value': '₹11.7L',
      'percent': 24.0,
      'color': AppColors.regionPurple,
      'dealers': 28,
    },
    {
      'name': 'North Bengal',
      'value': '₹10.2L',
      'percent': 21.0,
      'color': AppColors.regionCyan,
      'dealers': 19,
    },
    {
      'name': 'South Bengal',
      'value': '₹8.1L',
      'percent': 17.0,
      'color': AppColors.regionOrange,
      'dealers': 15,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: const AppTopBar.simple(title: 'Regions'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Regions',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.commandCentreText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sales split across territories',
                style: TextStyle(fontSize: 12, color: AppColors.steel),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 190,
                  height: 190,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      values: _regions
                          .map((r) => r['percent'] as double)
                          .toList(),
                      colors: _regions.map((r) => r['color'] as Color).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              for (final r in _regions) ...[
                _regionCard(r),
                if (r != _regions.last) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _regionCard(Map<String, dynamic> r) {
    final color = r['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['name'] as String,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${r['dealers']} dealers',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.steel,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                r['value'] as String,
                style: const TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '${(r['percent'] as double).toInt()}%',
                style: const TextStyle(fontSize: 10.5, color: AppColors.steel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _DonutChartPainter({required this.values, required this.colors});

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
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}
