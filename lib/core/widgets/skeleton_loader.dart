import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';

enum SkeletonLayout { dashboard, list, cards, form, detail }

/// Lightweight animated loading placeholders for app content.
class SkeletonLoader extends StatefulWidget {
  final SkeletonLayout layout;
  final int rows;

  const SkeletonLoader({
    super.key,
    this.layout = SkeletonLayout.list,
    this.rows = 5,
  });

  const SkeletonLoader.dashboard({super.key})
    : layout = SkeletonLayout.dashboard,
      rows = 4;

  const SkeletonLoader.cards({super.key, this.rows = 4})
    : layout = SkeletonLayout.cards;

  const SkeletonLoader.form({super.key})
    : layout = SkeletonLayout.form,
      rows = 5;

  const SkeletonLoader.detail({super.key})
    : layout = SkeletonLayout.detail,
      rows = 4;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment(-1.5 + 3 * _controller.value, 0),
          end: Alignment(-0.5 + 3 * _controller.value, 0),
          colors: const [
            Color(0xFFE8EAF0),
            Color(0xFFF7F8FA),
            Color(0xFFE8EAF0),
          ],
          stops: const [0.25, 0.5, 0.75],
        ).createShader(bounds),
        child: _buildLayout(),
      ),
    );
  }

  Widget _buildLayout() {
    switch (widget.layout) {
      case SkeletonLayout.dashboard:
        return _dashboard();
      case SkeletonLayout.list:
        return _list();
      case SkeletonLayout.cards:
        return _cards();
      case SkeletonLayout.form:
        return _form();
      case SkeletonLayout.detail:
        return _detail();
    }
  }

  Widget _dashboard() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _block(150, double.infinity, radius: 18),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _block(78, double.infinity)),
            const SizedBox(width: 10),
            Expanded(child: _block(78, double.infinity)),
          ],
        ),
        const SizedBox(height: 14),
        _block(210, double.infinity, radius: 18),
        const SizedBox(height: 14),
        for (var i = 0; i < widget.rows; i++) ...[
          _block(52, double.infinity, radius: 12),
          const SizedBox(height: 10),
        ],
      ],
    ),
  );

  Widget _list() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        _block(42, double.infinity),
        const SizedBox(height: 16),
        for (var i = 0; i < widget.rows; i++) ...[
          _block(78, double.infinity, radius: 14),
          const SizedBox(height: 12),
        ],
      ],
    ),
  );

  Widget _cards() => Padding(
    padding: const EdgeInsets.all(16),
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < widget.rows; i++)
          _block(126, (MediaQuery.sizeOf(context).width - 44) / 2, radius: 14),
      ],
    ),
  );

  Widget _form() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _block(30, 190),
        const SizedBox(height: 22),
        for (var i = 0; i < widget.rows; i++) ...[
          _block(16, 110),
          const SizedBox(height: 8),
          _block(52, double.infinity, radius: 10),
          const SizedBox(height: 18),
        ],
      ],
    ),
  );

  Widget _detail() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _block(32, 210),
        const SizedBox(height: 18),
        _block(176, double.infinity, radius: 16),
        const SizedBox(height: 18),
        for (var i = 0; i < widget.rows; i++) ...[
          _block(18, double.infinity),
          const SizedBox(height: 10),
          _block(18, i.isEven ? 230 : 170),
          const SizedBox(height: 18),
        ],
      ],
    ),
  );

  Widget _block(double height, double width, {double radius = 8}) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: AppColors.ash,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
