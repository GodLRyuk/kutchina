import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';

class AdminTeamMemberDetailScreen extends StatelessWidget {
  final String initials;
  final String name;
  final String today;
  final String month;
  final Color avatarBg;

  const AdminTeamMemberDetailScreen({
    super.key,
    required this.initials,
    required this.name,
    required this.today,
    required this.month,
    required this.avatarBg,
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
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: avatarBg,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.commandCentreText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _stat('Today', today, AppColors.salesTodayColumn),
                        Container(width: 1, height: 32, color: AppColors.line),
                        _stat('This Month', month, AppColors.salesThisMonthColumn),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'RECENT ORDERS',
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
                  'Recent orders placeholder — wire to a per-salesperson orders endpoint when available.',
                  style: TextStyle(fontSize: 12, color: AppColors.steel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontFamily: AppFonts.mono, fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.steel)),
      ],
    );
  }
}
