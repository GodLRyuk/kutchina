import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';

class LeadDetailScreen extends StatelessWidget {
  const LeadDetailScreen({super.key, required this.lead});

  final Map<String, dynamic> lead;

  @override
  Widget build(BuildContext context) {
    final score = lead['score'] as int;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          lead['name'],
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: AppWidgets.buildStatusBadge(lead['status'])),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppWidgets.buildCard(
              bgColor: AppColors.aiBlueBg,
              borderColor: AppColors.aiBlueBorder,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '✦ AI lead score',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.aiBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$score / 100',
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Mono',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.aiBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'High budget fit, responded within 2 hrs, and viewed the filterless chimney range twice. '
                    'Reps who call within 24 hrs on similar profiles convert 3× more often.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.steel,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            AppWidgets.buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONTACT',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.steel,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+91 90XXX XXXXX · ${lead['location'].toString().split(' · ').last}',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            AppWidgets.buildStaticField(
              label: 'Product interested',
              value: lead['product'],
            ),
            const SizedBox(height: 12),
            AppWidgets.buildStaticField(
              label: 'Source',
              value: 'Walk-in — showroom visit',
            ),
            const SizedBox(height: 12),
            AppWidgets.buildStaticField(
              label: 'Notes',
              value: 'Wants filterless model, budget ₹18–20K',
              isPlaceholder: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Activity',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _activityRow('Jul 18', 'First call made, interested'),
            _activityRow('Jul 15', 'Lead created from showroom'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppWidgets.buildButton(
                    'Call',
                    variant: AppButtonVariant.outline,
                    onTap: () =>
                        AppWidgets.toast(context, 'Calling ${lead['name']}...'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppWidgets.buildButton(
                    'Convert to order',
                    onTap: () =>
                        AppWidgets.toast(context, 'Order flow coming soon'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityRow(String date, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 11,
              color: AppColors.steelLight,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: AppColors.steel),
            ),
          ),
        ],
      ),
    );
  }
}
