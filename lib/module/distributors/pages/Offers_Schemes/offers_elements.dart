import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';

enum SchemeFilter { active, upcoming, expired }

class SchemeCardData {
  final String label;
  final String title;
  final String subtitle;
  final String status;
  final String actionText;
  final Color color;
  final IconData icon;
  final SchemeFilter period; // which tab this scheme belongs to
  final double? progress; // 0.0 to 1.0, e.g. 32 / 50
  final VoidCallback? onAction;

  const SchemeCardData({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.actionText,
    required this.color,
    required this.icon,
    this.period = SchemeFilter.active,
    this.progress,
    this.onAction,
  });

  bool get isExpired => period == SchemeFilter.expired;
}

class SchemeFilterChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const SchemeFilterChip({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(text),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.navActive,
        backgroundColor: AppColors.white,
        labelStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: selected ? AppColors.white : AppColors.ink,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? Colors.transparent : AppColors.line,
          ),
        ),
      ),
    );
  }
}

class SchemeCard extends StatelessWidget {
  final SchemeCardData data;
  const SchemeCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    
    final accent = data.isExpired ? AppColors.steel : data.color;
    final deep = Color.lerp(accent, AppColors.black, 0.55)!; 
    final mid = Color.lerp(accent, AppColors.black, 0.35)!; 
    final buttonColor =
        Color.lerp(accent, AppColors.black, 0.25)!; 

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(accent.withOpacity(0.10), AppColors.white),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withOpacity(0.75), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + label
          Row(
            children: [
              Icon(data.icon, size: 20, color: mid),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    color: mid,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.title,
            style: TextStyle(
              fontFamily: AppFonts.display,
              color: deep,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.subtitle,
            style: TextStyle(
              fontFamily: AppFonts.body,
              color: mid,
              fontSize: 12,
            ),
          ),

          
          if (data.progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: data.progress!.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: accent.withOpacity(0.18),
                valueColor: AlwaysStoppedAnimation(buttonColor),
              ),
            ),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  data.status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    color: deep,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
             
              if (!data.isExpired && data.actionText.isNotEmpty) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: data.onAction ?? () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(data.actionText),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}