import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';

class AdminTeamScreen extends StatelessWidget {
  const AdminTeamScreen({super.key});

  static const _team = [
    {
      'initials': 'AM',
      'name': 'Arjun Mehta',
      'today': '₹1.25L',
      'month': '₹15.8L',
      'bg': AppColors.avatarBg1,
    },
    {
      'initials': 'NS',
      'name': 'Neha Sharma',
      'today': '₹0.98L',
      'month': '₹13.2L',
      'bg': AppColors.avatarBg2,
    },
    {
      'initials': 'RD',
      'name': 'Rohan Das',
      'today': '₹0.76L',
      'month': '₹9.5L',
      'bg': AppColors.avatarBg3,
    },
    {
      'initials': 'PK',
      'name': 'Priya Kundu',
      'today': '₹0.62L',
      'month': '₹8.1L',
      'bg': AppColors.avatarBg1,
    },
    {
      'initials': 'SB',
      'name': 'Sourav Bose',
      'today': '₹0.44L',
      'month': '₹6.7L',
      'bg': AppColors.avatarBg2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: const Text(
          'Sales Team',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales Team',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.commandCentreText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_team.length} salespeople',
                style: const TextStyle(fontSize: 12, color: AppColors.steel),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _team.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _teamCard(_team[i], rank: i + 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamCard(Map<String, dynamic> t, {required int rank}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.steelLight,
              ),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: t['bg'] as Color,
            child: Text(
              t['initials'] as String,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.commandCentreText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t['name'] as String,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                t['month'] as String,
                style: const TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.salesThisMonthColumn,
                ),
              ),
              Text(
                'today: ${t['today']}',
                style: const TextStyle(fontSize: 9.5, color: AppColors.steel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
