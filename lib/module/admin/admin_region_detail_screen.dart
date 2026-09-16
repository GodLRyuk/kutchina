import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';

class AdminRegionDetailScreen extends StatelessWidget {
  final String name;
  final String value;
  final String percent;
  final Color color;

  const AdminRegionDetailScreen({
    super.key,
    required this.name,
    required this.value,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Text(
          name,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
      ),
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
                      decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                      child: Icon(Icons.location_on_outlined, size: 26, color: color),
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
                      '$percent of company sales',
                      style: const TextStyle(fontSize: 12, color: AppColors.steel),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'TOP DEALERS IN THIS REGION',
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
                  'Dealer list placeholder — wire to a per-region dealers endpoint when available.',
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
