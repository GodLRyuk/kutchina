import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kutchina/core/constants/app_theme.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? greeting;
  final String? subtitle;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final ImageProvider? centerImage;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const AppTopBar({
    super.key,
    this.title,
    this.greeting,
    this.subtitle,
    this.showBackButton = true,
    this.actions,
    this.onBack,
    this.centerImage = const AssetImage('assets/images/logo.jpg'),
    this.systemOverlayStyle,
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
    this.systemOverlayStyle,
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
    this.systemOverlayStyle,
  }) : title = null;

  const AppTopBar.brand({
    super.key,
    this.actions,
    this.showBackButton = false, // add here
    this.centerImage = const AssetImage('assets/images/logo.jpg'),
    this.systemOverlayStyle = const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
    ),
  }) : title = null,
       greeting = null,
       subtitle = null,
       //  showBackButton = false,
       onBack = null;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: systemOverlayStyle,
      leadingWidth: showBackButton ? 36 : null, // added
      titleSpacing: showBackButton ? 0 : null, // added
      leading: showBackButton
          ? IconButton(
              padding: EdgeInsets.zero, // added
              constraints: const BoxConstraints(), // added
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          : null,
      centerTitle: title != null,
      flexibleSpace: greeting != null && centerImage != null
          ? SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight,
                child: Center(
                  child: SizedBox(
                    width: 100,
                    height: 22,
                    child: Image(image: centerImage!, fit: BoxFit.contain),
                  ),
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
          : greeting != null
          ? Row(
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
            )
          : centerImage != null
          ? Image(image: centerImage!, height: 32, fit: BoxFit.contain)
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
