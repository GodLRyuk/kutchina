import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';

/// Generic blocking gate dialog. Non-dismissible, no back button, no
/// baked-in navigation — just shows content and closes on confirm.
/// Returns true if the user tapped confirm, false if somehow dismissed.
Future<bool> showCheckInRequiredDialog(
  BuildContext context, {
  String title = 'Check in required',
  String message =
      'You need to check in before you can use orders, visits, or any other feature today.',
  String buttonLabel = 'Check in now',
  IconData icon = Icons.location_on_outlined,
}) async {
  var confirmed = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.redDark, size: 24),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.steel,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                AppWidgets.buildButton(
                  buttonLabel,
                  icon: icon,
                  onTap: () {
                    confirmed = true;
                    Navigator.pop(dialogContext);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  return confirmed;
}
