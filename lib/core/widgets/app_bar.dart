import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? greeting;
  final String? subtitle;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final ImageProvider? centerImage;

  const AppTopBar({
    super.key,
    this.title,
    this.greeting,
    this.subtitle,
    this.showBackButton = true,
    this.actions,
    this.onBack,
    this.centerImage,
  }) : assert(
         title != null || subtitle != null,
         'Provide either title or (greeting + subtitle)',
       );

  const AppTopBar.simple({
    super.key,
    required String this.title,
    this.showBackButton = true,
    this.actions,
    this.onBack,
    this.centerImage,
  }) : greeting = null,
       subtitle = null;

  const AppTopBar.greeting({
    super.key,
    required String this.greeting,
    required String this.subtitle,
    this.showBackButton = false,
    this.actions,
    this.onBack,
    this.centerImage,
  }) : title = null;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          : null,
      centerTitle: false,
      title: Row(
        children: [
          Expanded(
            child: title != null
                ? Text(
                    title!,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.steel,
                        ),
                      ),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
          ),
          if (centerImage != null) ...[
            Image(
              image: centerImage!,
              width: 100,
              height: 50,
              fit: BoxFit.contain,
            ),
          ],
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
