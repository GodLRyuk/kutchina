import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/utils/voice_input_sheet.dart';
import 'package:kutchina/module/salesExe/models/product_model.dart';

class NoteSheet extends StatefulWidget {
  final String initialText;
  final List<SuggestionModel> suggestions;
  const NoteSheet({required this.initialText, this.suggestions = const []});

  @override
  State<NoteSheet> createState() => NoteSheetState();
}

class NoteSheetState extends State<NoteSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose(); // safe: runs after close animation ends
    super.dispose();
  }

  Future<void> _voice() async {
    FocusScope.of(context).unfocus(); // hide keyboard
    final text = await showVoiceInputSheet(context);
    if (!mounted || text == null || text.isEmpty) return;
    final old = _controller.text.trim();
    _controller.text = old.isEmpty ? text : '$old $text';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  /// Blue → teal gradient button, same style as the Submit button.
  Widget _saveButton() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: AppColors.buttonGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.regionBlue.withOpacity(.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pop(context, _controller.text),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Save note',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Visit note',
            style: TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.regionOrange,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'What happened at this visit?',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.regionOrange),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.regionOrange,
                        width: 1.3,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.regionOrange,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _voice,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.red.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(Icons.mic, color: AppColors.red, size: 22),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          _saveButton(),
        ],
      ),
    );
  }
}