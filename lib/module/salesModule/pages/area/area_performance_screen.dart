import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/module/salesModule/pages/area/area_feature_form_screen.dart';

class AreaPerformanceScreen extends StatefulWidget {
  const AreaPerformanceScreen({super.key});

  @override
  State<AreaPerformanceScreen> createState() => _AreaPerformanceScreenState();
}

class _AreaPerformanceScreenState extends State<AreaPerformanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: false,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar.brand(
        showBackButton: true,
        centerImage: const AssetImage('assets/images/logo.jpg'),
        actions: [],
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tap a feature',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: AppColors.steel,
                  ),
                ),
                const SizedBox(height: 8),
                _FeatureCard(
                  children: [
                    _FeatureRow(
                      iconBg: AppColors.rupeeIconBg,
                      icon: const Text(
                        '₹',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.commandCentreText,
                        ),
                      ),
                      title: 'Area sales',
                      trailing: const Text(
                        'Rs 12.9Cr',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.regionBlue,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(context, (MaterialPageRoute(builder: (context)=>AreaFeatureFormScreen(feature: AreaFeature.sales))));
                      },
                    ),
                    const _RowDivider(),
                    _FeatureRow(
                      iconBg: AppColors.amberLight,
                      icon: const _MiniBars(color: AppColors.productOvens),
                      title: 'Branch compare',
                      subtitle: 'Kolkata, Howrah, Siliguri',
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.steelLight,
                        size: 20,
                      ),
                      onTap: () {
                        Navigator.push(context, (MaterialPageRoute(builder: (context)=>AreaFeatureFormScreen(feature: AreaFeature.branchCompare))));
                      },
                    ),
                    const _RowDivider(),
                    _FeatureRow(
                      iconBg: AppColors.greenLight,
                      icon: const _MiniBars(color: AppColors.green),
                      title: 'Area forecast',
                      progress: 0.91,
                      trailing: const Text(
                        '91% likely',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.regionBlue,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(context, (MaterialPageRoute(builder: (context)=>AreaFeatureFormScreen(feature: AreaFeature.forecast))));
                      },
                    ),
                  ],
                ),
                // const SizedBox(height: 22),
                //_CompareButton(onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final List<Widget> children;
  const _FeatureCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.commandCentreText.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AppColors.line);
}

class _FeatureRow extends StatelessWidget {
  final Color iconBg;
  final Widget icon;
  final String title;
  final String? subtitle;
  final double? progress;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _FeatureRow({
    required this.iconBg,
    required this.icon,
    required this.title,
    this.subtitle,
    this.progress,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: icon,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 11,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                  if (progress != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.line,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.buttonGradientStart,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
  }
}


class _MiniBars extends StatelessWidget {
  final Color color;
  const _MiniBars({required this.color});

  @override
  Widget build(BuildContext context) {
    Widget bar(double h) => Container(
      width: 3,
      height: h,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [bar(8), bar(16), bar(11)],
    );
  }
}

// class _CompareButton extends StatelessWidget {
//   final VoidCallback onPressed;
//   const _CompareButton({required this.onPressed});

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: Ink(
//         height: 54,
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [AppColors.commandCentreText, AppColors.highPerformersBg],
//           ),
//           borderRadius: BorderRadius.circular(AppRadius.lg),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.commandCentreText.withOpacity(0.28),
//               blurRadius: 16,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: InkWell(
//           onTap: onPressed,
//           borderRadius: BorderRadius.circular(AppRadius.lg),
//           child: const Center(
//             child: Text(
//               'Compare',
//               style: TextStyle(
//                 fontFamily: AppFonts.display,
//                 fontSize: 15,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.white,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//}
