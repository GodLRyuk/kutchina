import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_bottom_nav.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesModule/pages/task_management/task_element.dart';
import 'package:provider/provider.dart';

class CreateTaskScreen extends StatefulWidget {
  final bool showBottomNav;

  const CreateTaskScreen({super.key, this.showBottomNav = true});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _parentTaskController = TextEditingController();
  final _assigneeController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime _dueDate = DateTime.now();
  String _priority = 'medium';
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _parentTaskController.dispose();
    _assigneeController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final assigneeIds = _assigneeController.text
        .split(',')
        .map((value) => int.tryParse(value.trim()))
        .whereType<int>()
        .toList();
    final parentText = _parentTaskController.text.trim();
    final payload = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'due_date': DateFormat('yyyy-MM-dd').format(_dueDate),
      'priority': _priority,
      'parent_task_id': parentText.isEmpty ? null : int.parse(parentText),
      'assignee_ids': assigneeIds,
      'change_reason': _reasonController.text.trim(),
    };

    setState(() => _submitting = true);
    try {
      final response = await ApiService.instance.post(
        '/api/v1/task/tasks/',
        data: payload,
      );
      if (!mounted) return;
      AppWidgets.toast(context, 'Task created successfully');
      Navigator.pop(context, response.data ?? true);
    } on ApiException catch (error) {
      if (mounted) AppWidgets.toast(context, error.message);
    } catch (_) {
      if (mounted) AppWidgets.toast(context, 'Unable to create task');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      // extendBody: true,
      extendBody: false,
      extendBodyBehindAppBar: true,

      appBar: AppTopBar.brand(
        centerImage: const AssetImage('assets/images/logo.jpg'),
        showBackButton: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.regionBlue,
              child: const Icon(Icons.person, color: Colors.white, size: 21),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + kToolbarHeight,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TaskElement.taskElementTopHeader(),
                  const SizedBox(height: 20),
                  TaskElement.taskElementForm(
                    context,
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    parentTaskController: _parentTaskController,
                    assigneeController: _assigneeController,
                    reasonController: _reasonController,
                    dueDate: _dueDate,
                    onDueDateChanged: (value) =>
                        setState(() => _dueDate = value),
                    priority: _priority,
                    onPriorityChanged: (value) =>
                        setState(() => _priority = value),
                    userRole: auth.role,
                  ),
                  const SizedBox(height: 21),
                  _actionButton(
                    _submitting ? 'Creating…' : 'Create Task  →',
                    onPressed: _submitting ? null : _submit,
                    gradient: AppColors.buttonGradient,
                  ),
                  const SizedBox(height: 14),
                  _actionButton(
                    'Cancel',
                    onPressed: () => Navigator.pop(context),
                    color: const Color(0xFF075092),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(backgroundColor: Colors.white)
          : null,
    );
  }

  Widget _actionButton(
    String label, {
    required VoidCallback? onPressed,
    LinearGradient? gradient,
    Color? color,
  }) => SizedBox(
    height: 64,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : gradient,
        color: onPressed == null ? AppColors.steelLight : color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: AppFonts.display,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
