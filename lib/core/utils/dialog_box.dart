import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/services/location_service.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';

Future<bool> showCheckInRequiredDialog(BuildContext context) async {
  bool success = false;

  await showDialog(
    context: context,
    barrierDismissible: false, // force user to check in
    builder: (dialogContext) {
      bool isSubmitting = false;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Check-in required'),
            content: const Text('Please check in to continue using the app.'),
            actions: [
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);

                        try {
                          final position =
                              await LocationService.getCurrentLocation();

                          final ok = await CheckInService.checkIn(
                            locationName:
                                'Office', // or reverse-geocode this if you need a real place name
                            latitude: position.latitude,
                            longitude: position.longitude,
                          );

                          if (!dialogContext.mounted) return;

                          if (ok) {
                            success = true;
                            Navigator.of(dialogContext).pop();
                          } else {
                            setDialogState(() => isSubmitting = false);
                            AppWidgets.toast(
                              dialogContext,
                              'Check-in failed. Try again.',
                            );
                          }
                        } catch (e) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() => isSubmitting = false);
                          AppWidgets.toast(dialogContext, e.toString());
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Check In'),
              ),
            ],
          );
        },
      );
    },
  );

  return success;
}

//Non-dismissible, no back button, no
/// baked-in navigation — just shows content and closes on confirm.
/// Returns true if the user tapped confirm, false if somehow dismissed.
Future<bool> showCheckInRequiredDialogall(
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
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.green, size: 24),
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
