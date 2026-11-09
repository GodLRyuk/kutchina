import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/utils/admin_services.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';

class FeatureListItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const FeatureListItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

const List<FeatureListItem> _defaultFeatureItems = [
  FeatureListItem(
    title: 'Approval Limits',
    subtitle: 'SH 2L, BM 5L, ASM 15L',
    icon: Icons.currency_rupee,
    color: AppColors.regionBlue,
  ),
  FeatureListItem(
    title: 'Final Pricing',
    subtitle: 'Hobs +3%',
    icon: Icons.credit_card_outlined,
    color: AppColors.regionOrange,
  ),
  FeatureListItem(
    title: 'Final Credit',
    subtitle: 'Rs 20L',
    icon: Icons.credit_score_outlined,
    color: AppColors.regionPurple,
  ),
  FeatureListItem(
    title: 'Role Changes',
    subtitle: 'Rahul to BM',
    icon: Icons.groups_outlined,
    color: AppColors.regionCyan,
  ),
];

/// A reusable, configurable feature list page based on the approvals design.
class FeatureListScreen extends StatelessWidget {
  final String title;
  final String sectionTitle;
  final List<FeatureListItem> items;
  final VoidCallback? onSave;
  final VoidCallback? onProfileTap;

  const FeatureListScreen({
    super.key,
    this.title = 'Feature List',
    this.sectionTitle = 'Tap a feature',
    this.items = _defaultFeatureItems,
    this.onSave,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // extendBody: true,
      extendBody: false,
      extendBodyBehindAppBar: true,

      appBar: AppTopBar.brand(
        showBackButton: true,
        centerImage: const AssetImage('assets/images/logo.jpg'),
        actions: [],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.apps_rounded,
                          color: AppColors.regionBlue,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          sectionTitle,
                          style: const TextStyle(
                            color: AppColors.regionBlue,
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final item in items) _FeatureListTile(item: item),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureListTile extends StatelessWidget {
  final FeatureListItem item;

  const _FeatureListTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 80),
        // padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 5),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line, width: 1.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      color: AppColors.steel,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 28, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
