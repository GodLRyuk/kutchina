import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_bar.dart';

class AdminProductDetailScreen extends StatelessWidget {
  final String name;
  final String value;
  final double percent;
  final String label;
  final Color color;
  final IconData icon;

  const AdminProductDetailScreen({
    super.key,
    required this.name,
    required this.value,
    required this.percent,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppTopBar.simple(title: name),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, size: 28, color: color),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      value,
                      style: const TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.commandCentreText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$label of total sales',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.steel,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 8,
                        backgroundColor: AppColors.ash,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'MONTHLY TREND',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.steel,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Text(
                  'Trend chart placeholder — wire to a per-product sales history endpoint when available.',
                  style: TextStyle(fontSize: 12, color: AppColors.steel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
