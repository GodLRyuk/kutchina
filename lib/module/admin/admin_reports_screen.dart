import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  static const _reports = [
    {
      'title': 'Monthly Sales Summary',
      'subtitle': 'Sep 2026 · All regions',
      'icon': Icons.bar_chart_outlined,
      'color': AppColors.regionBlue,
    },
    {
      'title': 'Product Performance',
      'subtitle': 'Sep 2026 · By category',
      'icon': Icons.inventory_2_outlined,
      'color': AppColors.productChimney,
    },
    {
      'title': 'Team Leaderboard',
      'subtitle': 'Sep 2026 · Top salespeople',
      'icon': Icons.groups_outlined,
      'color': AppColors.achievementIconBg,
    },
    {
      'title': 'Regional Breakdown',
      'subtitle': 'Sep 2026 · Territory-wise',
      'icon': Icons.public_outlined,
      'color': AppColors.regionCyan,
    },
    {
      'title': 'Target vs Achievement',
      'subtitle': 'Sep 2026 · Company-wide',
      'icon': Icons.track_changes_outlined,
      'color': AppColors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reports',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.commandCentreText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Download or share monthly reports',
                style: TextStyle(fontSize: 12, color: AppColors.steel),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _reportCard(context, _reports[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportCard(BuildContext context, Map<String, dynamic> r) {
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
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(r['icon'] as IconData, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['title'] as String,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  r['subtitle'] as String,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.steel),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppColors.commandCentreText, size: 20),
            onPressed: () => AppWidgets.toast(context, 'Downloading ${r['title']}…'),
          ),
        ],
      ),
    );
  }
}
