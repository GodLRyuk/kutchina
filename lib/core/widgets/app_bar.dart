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
    this.centerImage = const AssetImage('assets/images/logo.jpg'),
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
    this.centerImage = const AssetImage('assets/images/logo.jpg'),
  }) : greeting = null,
       subtitle = null;

  const AppTopBar.greeting({
    super.key,
    required String this.greeting,
    required String this.subtitle,
    this.showBackButton = false,
    this.actions,
    this.onBack,
    this.centerImage = const AssetImage('assets/images/logo.jpg'),
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
      centerTitle: title != null,
      flexibleSpace: title == null && centerImage != null
          ? Padding(
              padding: const EdgeInsets.only(top: 25),
              child: Center(
                child: SizedBox(
                  width: 100,
                  height: 22,
                  child: Image(image: centerImage!, fit: BoxFit.contain),
                ),
              ),
            )
          : null,
      title: title != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (centerImage != null) ...[
                  Image(
                    image: centerImage!,
                    width: 120,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title!,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      greeting!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.steel,
                      ),
                    ),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
