import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/utils/voice_input_sheet.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';

class NoteSheet extends StatefulWidget {
  final String initialText;
  const NoteSheet({required this.initialText});

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
                    border: OutlineInputBorder(),
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
          AppWidgets.buildButton(
            'Save note',
            onTap: () => Navigator.pop(context, _controller.text),
          ),
        ],
      ),
    );
  }
}
