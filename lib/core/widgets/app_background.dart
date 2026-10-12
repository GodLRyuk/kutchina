import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final String asset;
  final double veil;
  final double? height;

  const AppBackground({
    super.key,
    required this.child,
    this.asset = 'assets/images/background.png',
    this.veil = 0.2,
    this.height,
  });

  Widget _image() => Image.asset(
    asset,
    fit: BoxFit.cover,
    alignment: Alignment.topCenter,
    width: double.infinity,
    height: double.infinity,
    // Missing / wrong file name: fall back to the plain page colour.
    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
  );

  Widget _layer() {
    if (height == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _image(),
          if (veil > 0)
            ColoredBox(color: AppColors.ash.withValues(alpha: veil)),
        ],
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _image(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.ash.withValues(alpha: 0.0), AppColors.ash],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ash,
      child: SizedBox.expand(
        child: Stack(fit: StackFit.expand, children: [_layer(), child]),
      ),
    );
  }
}
