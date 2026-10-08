import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/utils/voice_input_sheet.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/core/widgets/suggestion_dropdown.dart';
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
  List<SuggestionModel> _filtered = [];
  bool _noMatch = false;

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

   void _onNoteChanged(String value) {
  final result = filterSuggestions(widget.suggestions, value);
  setState(() {
    _filtered = result;
    _noMatch = hasNoMatch(widget.suggestions, result, value);
  });
}

 void _selectSuggestion(SuggestionModel s) {
    _controller.text = s.text;
    _controller.selection = TextSelection.collapsed(offset: s.text.length);
    setState(() {
      _filtered = [];
      _noMatch = false;
    });
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
     _onNoteChanged(_controller.text);
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
                  onChanged: _onNoteChanged,
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
           SuggestionDropdown(
            items: _filtered,
            noMatch: _noMatch,
            onSelect: _selectSuggestion,
            onDismiss: () => setState(() => _noMatch = false),
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
