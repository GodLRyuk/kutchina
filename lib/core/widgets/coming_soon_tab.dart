import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_bar.dart';

class ComingSoonTab extends StatelessWidget {
  final String title;
  final String message;

  const ComingSoonTab({
    super.key,
    required this.title,
    this.message = 'This tab is coming soon.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar.simple(title: title),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
