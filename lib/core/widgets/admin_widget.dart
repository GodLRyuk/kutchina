import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';

class AdminWidget {
  static Widget quickAction(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? bgColor,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: bgColor?.withOpacity(1) ?? AppColors.line,
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 30, color: bgColor),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: bgColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
