import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';

/// Small building blocks reused by the Distributor, Sales Head and HOD
/// screens. Everything uses the existing AppColors / AppFonts.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? sub;
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.commandCentreText,
    this.sub,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.steel),
        ),
        if (sub != null)
          Text(sub!, style: const TextStyle(fontSize: 10, color: AppColors.steelLight)),
      ],
    ),
  );
}

/// 2-column grid of [KpiTile]s that sizes itself (no fixed heights).
class KpiGrid extends StatelessWidget {
  final List<KpiTile> tiles;
  const KpiGrid(this.tiles, {super.key});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class ProgressBarRow extends StatelessWidget {
  final String label;
  final double percent; // 0..100+
  final String? right;
  const ProgressBarRow({
    super.key,
    required this.label,
    required this.percent,
    this.right,
  });

  Color get _color => percent >= 100
      ? AppColors.green
      : percent >= 60
      ? AppColors.navActive
      : percent >= 30
      ? AppColors.amber
      : AppColors.red;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
              ),
            ),
            Text(
              right ?? '${percent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: _color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppColors.line,
            color: _color,
          ),
        ),
      ],
    ),
  );
}

/// Horizontal step tracker: Placed -> Approved -> Dispatched -> Delivered.
class StatusTimeline extends StatelessWidget {
  final List<String> steps;
  final int current; // index of the last completed step, -1 = none
  final bool cancelled;
  const StatusTimeline({
    super.key,
    required this.steps,
    required this.current,
    this.cancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    final done = cancelled ? AppColors.red : AppColors.green;
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= current ? done : AppColors.line,
                  ),
                  child: Icon(
                    cancelled && i == current ? Icons.close : Icons.check,
                    size: 13,
                    color: i <= current ? Colors.white : AppColors.steelLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: i <= current ? AppColors.ink : AppColors.steelLight,
                  ),
                ),
              ],
            ),
          ),
          if (i != steps.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  height: 2,
                  color: i < current ? done : AppColors.line,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Maps free-text server status to a badge colour.
Widget statusPill(String status) {
  final s = status.toLowerCase();
  Color bg = AppColors.coldBg;
  Color fg = AppColors.coldText;
  if (s.contains('deliver') || s.contains('approved') || s.contains('paid') ||
      s.contains('active') || s.contains('received')) {
    bg = AppColors.greenLight;
    fg = AppColors.green;
  } else if (s.contains('pending') || s.contains('placed') || s.contains('due') ||
      s.contains('dispatch') || s.contains('partial')) {
    bg = AppColors.amberLight;
    fg = AppColors.amberDark;
  } else if (s.contains('reject') || s.contains('cancel') || s.contains('overdue') ||
      s.contains('inactive') || s.contains('risk')) {
    bg = AppColors.redLight;
    fg = AppColors.red;
  }
  return AppWidgets.buildBadge(status, bg, fg);
}
