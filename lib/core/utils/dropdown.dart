import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_background.dart';

class EntityPickerSheet extends StatefulWidget {
  final String label;
  final List<String> options;
  const EntityPickerSheet({
    super.key,
    required this.label,
    required this.options,
  });

  @override
  State<EntityPickerSheet> createState() => EntityPickerSheetState();
}

class EntityPickerSheetState extends State<EntityPickerSheet> {
  final _searchController = TextEditingController();

  List<String> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options.where((e) => e.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: AppBackground(child: SizedBox.expand())),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.line,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Select ${widget.label}',
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * .5,
                          ),
                          child: _filtered.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Text(
                                    'No results found',
                                    style: TextStyle(
                                      color: AppColors.steel,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: _filtered.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  // separatorBuilder: (_, _) =>
                                  //     const Divider(height: 1, color: AppColors.line),
                                  itemBuilder: (context, i) {
                                    final e = _filtered[i];
                                    final accent = i.isEven ? AppColors.aiBlue : AppColors.dayEndIconBg;
                                       
                                    return Material(
                                      color: AppColors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                        color: accent ,
                                        width: 1.5  
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 2,
                                            ),
                                        title: Text(
                                          e,
                                          style: const TextStyle(
                                            fontFamily: AppFonts.display,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.regionBlue,
                                          ),
                                        ),
                                        onTap: () => Navigator.pop(context, e),
                                      ),
                        
                                      
                                    );
                                    
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
