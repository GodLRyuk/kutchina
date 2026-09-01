import 'package:flutter/material.dart';

/// Screen-size breakpoints and helpers, used across every page instead of
/// hardcoding MediaQuery calls everywhere.
class Responsive {
  Responsive._();

  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) =>
      screenWidth(context) < mobileMaxWidth;
  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= mobileMaxWidth &&
      screenWidth(context) < tabletMaxWidth;
  static bool isDesktop(BuildContext context) =>
      screenWidth(context) >= tabletMaxWidth;

  /// Caps content width on large screens so forms/cards don't stretch edge
  /// to edge on tablets/desktop, while staying full-width on phones.
  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 420;
    if (isTablet(context)) return 480;
    return double.infinity;
  }

  /// Horizontal page padding that scales down on small phones.
  static double horizontalPadding(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 16;
    if (w < 600) return 20;
    return 32;
  }
}

/// Wraps a page's content so it centers horizontally with a max width on
/// large screens, and centers vertically when the content is shorter than
/// the viewport (falls back to normal top-aligned scroll otherwise).
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final bool scrollable;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.contentMaxWidth(context),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context),
          ),
          child: child,
        ),
      ),
    );

    if (!scrollable) return content;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: content),
          ),
        );
      },
    );
  }
}
