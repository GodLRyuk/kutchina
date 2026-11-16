import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';

class NewTicketElements {
  static Widget dropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T> onChanged,
    String Function(T)? itemLabel,
    String hint = 'Select',
  }) {
    String text(T item) =>
        itemLabel != null ? itemLabel(item) : item.toString();

    return LayoutBuilder(
      builder: (context, constraints) {
        return PopupMenuButton<T>(
          position: PopupMenuPosition.under,
          offset: const Offset(0, 4),
          color: AppColors.white,
          elevation: 4,
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth,
            maxWidth: constraints.maxWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          onSelected: onChanged,
          itemBuilder: (_) => items
              .map(
                (e) => PopupMenuItem<T>(
                  value: e,
                  child: Text(
                    text(e),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.ink,
                      fontWeight: e == value
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              )
              .toList(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.steel,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value != null ? text(value) : hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          color: value != null
                              ? AppColors.ink
                              : AppColors.steelLight,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.ink,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget buildTextField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.line),
    ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.steel,
            ),
          ),

          const SizedBox(height: 2),
          TextFormField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 5,
            minLines: 2,
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 13,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.steelLight,
              ),
            ),
          ),
        ],
      ),
    );
  }



   static Widget submitButton({
    required String label,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.aiBlue,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.aiBlue,
        disabledForegroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
