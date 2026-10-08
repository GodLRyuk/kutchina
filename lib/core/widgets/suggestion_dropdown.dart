import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/module/salesExe/models/product_model.dart';

List<SuggestionModel> filterSuggestions(
  List<SuggestionModel> all,
  String value,
) {
  final q = value.trim().toLowerCase();
  if (q.isEmpty) return [];
  return all.where((s) => s.text.toLowerCase().contains(q)).toList()
    ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
}

// True when the user typed something, suggestions exist, but none matched.
bool hasNoMatch(
  List<SuggestionModel> all,
  List<SuggestionModel> result,
  String value,
) => value.trim().isNotEmpty && result.isEmpty && all.isNotEmpty;

class SuggestionDropdown extends StatelessWidget {
  final List<SuggestionModel> items;
  final bool noMatch;
  final ValueChanged<SuggestionModel> onSelect;
  final VoidCallback? onDismiss;

  const SuggestionDropdown({
    super.key,
    required this.items,
    required this.noMatch,
    required this.onSelect,
    this.onDismiss, // add
  });

  @override
  Widget build(BuildContext context) {
    if (noMatch) {
      return GestureDetector(
        onTap: onDismiss,
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.steel.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 16,
                  color: AppColors.steel,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No matches found',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.steel,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'You can continue with your own text.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: AppColors.white,
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.line),
            itemBuilder: (context, i) => InkWell(
              onTap: () => onSelect(items[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 18, color: AppColors.steel),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i].text,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.north_west,
                      size: 16,
                      color: AppColors.steel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
