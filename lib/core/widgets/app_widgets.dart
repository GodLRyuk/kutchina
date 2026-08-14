import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

enum AppButtonVariant { primary, outline, dark }

class AppWidgets {
  // ---------------- Badge ----------------
  static Widget buildBadge(String text, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Preset status badges matching the .badge-hot / -warm / -cold / -success
  /// / -pending / -danger classes in the v3 design.
  static Widget buildStatusBadge(String status) {
    switch (status.toLowerCase()) {
      case 'hot':
        return buildBadge('Hot', AppColors.redLight, AppColors.redDark);
      case 'warm':
        return buildBadge('Warm', AppColors.amberLight, AppColors.amberDark);
      case 'cold':
        return buildBadge('Cold', AppColors.coldBg, AppColors.coldText);
      case 'success':
        return buildBadge('In stock', AppColors.greenLight, AppColors.green);
      case 'pending':
        return buildBadge('Pending', AppColors.amberLight, AppColors.amberDark);
      case 'danger':
        return buildBadge('Reorder', AppColors.redLight, AppColors.redDark);
      default:
        return buildBadge(status, AppColors.coldBg, AppColors.coldText);
    }
  }

  static Widget buildAiScoreBadge(int score) {
    return buildBadge(
      '\u2726 $score',
      AppColors.aiBlueChipBg,
      AppColors.aiBlue,
    );
  }

  // ---------------- Card ----------------
  static Widget buildCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    Color? borderColor,
    Color? bgColor,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.only(bottom: 10),
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor ?? AppColors.line),
      ),
      child: child,
    );
  }

  // ---------------- Chip ----------------
  static Widget buildChip(
    String label, {
    required bool isActive,
    VoidCallback? onTap,
    Color? activeColor,
    Color? activeTextColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? (activeColor ?? AppColors.charcoal)
              : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? (activeColor ?? AppColors.charcoal)
                : AppColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive
                ? (activeTextColor ?? Colors.white)
                : AppColors.steel,
          ),
        ),
      ),
    );
  }

  // ---------------- Button ----------------
  static Widget buildButton(
    String label, {
    required VoidCallback? onTap,
    AppButtonVariant variant = AppButtonVariant.primary,
    IconData? icon,
    bool fullWidth = true,
  }) {
    Color bg;
    Color fg;
    BoxBorder? border;
    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.red;
        fg = Colors.white;
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.red;
        border = Border.all(color: AppColors.red, width: 1.4);
        break;
      case AppButtonVariant.dark:
        bg = AppColors.charcoal;
        fg = Colors.white;
        break;
    }
    final child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: fg,
          ),
        ),
      ],
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          border: border,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }

  // ---------------- Text field ----------------
  static Widget buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.steel,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.line, width: 1.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppColors.ink, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.steelLight,
                fontSize: 13,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
      ],
    );
  }

  /// Non-editable "input-style" row, e.g. a picker ("Select state ▾").
  static Widget buildStaticField({
    required String label,
    required String value,
    VoidCallback? onTap,
    bool isPlaceholder = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.steel,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.line, width: 1.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: isPlaceholder ? AppColors.steelLight : AppColors.ink,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- Icon button ----------------
  static Widget buildIconButton(
    IconData icon, {
    VoidCallback? onTap,
    bool ghost = false,
    bool darkBg = false,
    double size = 30,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ghost
              ? (darkBg ? Colors.white.withOpacity(.15) : Colors.transparent)
              : AppColors.white,
          shape: BoxShape.circle,
          boxShadow: ghost
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 2,
                  ),
                ],
        ),
        child: Icon(
          icon,
          size: size * 0.53,
          color: ghost && darkBg ? Colors.white : AppColors.charcoal,
        ),
      ),
    );
  }

  // ---------------- Burner ring (signature motif) ----------------
  static Widget buildBurnerRing({
    required double percent,
    required String centerLabel,
    required String centerSubLabel,
    double size = 132,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percent.clamp(0, 1),
              strokeWidth: 10,
              backgroundColor: const Color(0xFFEDEBE6),
              valueColor: const AlwaysStoppedAnimation(AppColors.red),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                centerLabel,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal,
                ),
              ),
              Text(
                centerSubLabel,
                style: const TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 9.5,
                  color: AppColors.steel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget aiRecommendCard(String body, {String title = 'AI recommends'}) {
    return buildCard(
      bgColor: AppColors.aiBlueBg,
      borderColor: AppColors.aiBlueBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 15, color: AppColors.aiBlue),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.aiBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.steel,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  static void toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}
