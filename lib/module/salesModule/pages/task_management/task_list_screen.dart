import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kutchina/core/auth/app_roles.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_bottom_nav.dart';
import 'package:kutchina/module/salesModule/pages/task_management/create_task.dart';

import 'package:provider/provider.dart';

class TaskListScreen extends StatefulWidget {
  final bool showBottomNav;

  const TaskListScreen({super.key, this.showBottomNav = true});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.instance.get('/api/v1/task/tasks/');
      final data = response.data;
      // print("Task data is $data");
      final List<dynamic> rows;
      if (data is List) {
        rows = data;
      } else if (data is Map) {
        final nested = data['results'] ?? data['tasks'] ?? data['data'];
        rows = nested is List ? nested : const [];
      } else {
        rows = const [];
      }
      if (!mounted) return;
      setState(() {
        _tasks = rows.whereType<Map>().map(_asStringMap).toList();
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load tasks';
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _asStringMap(Map row) =>
      row.map((key, value) => MapEntry(key.toString(), value));

  Future<void> _openCreateTask({Map<String, dynamic>? task}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTaskScreen(showBottomNav: false, task: task),
      ),
    );
    if (!mounted) return;
    if (result != null) _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar.brand(
        centerImage: const AssetImage('assets/images/logo.jpg'),
        showBackButton: Navigator.of(context).canPop(),
      ),
      body: AppBackground(
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + kToolbarHeight,
          ),
          child: RefreshIndicator(
            onRefresh: _loadTasks,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 19,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Management',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: AppFonts.display,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'View and manage assigned work',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _createButton(),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tasks',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      '${_tasks.length} total',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 42),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  _messageCard(
                    icon: Icons.cloud_off_outlined,
                    message: _error!,
                    action: TextButton(
                      onPressed: _loadTasks,
                      child: const Text('Try again'),
                    ),
                  )
                else if (_tasks.isEmpty)
                  _messageCard(
                    icon: Icons.task_alt_outlined,
                    message: 'No tasks yet. Create a task to get started.',
                  )
                else
                  // ..._tasks.map(_taskCard),
                  ..._tasks.asMap().entries.map(
                    (entry) => _taskCard(
                      entry.value,
                      accent: entry.key.isEven
                          ? AppColors.aiBlue
                          : AppColors.dayEndIconBg,
                    ),
                  ),

                SizedBox(height: MediaQuery.sizeOf(context).height * 0.05),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTask,
        backgroundColor: AppColors.regionBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(backgroundColor: Colors.white)
          : null,
    );
  }

  Widget _createButton() => SizedBox(
    height: 56,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: _openCreateTask,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white),
              SizedBox(width: 9),
              Text(
                'Create new task',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _messageCard({
    required IconData icon,
    required String message,
    Widget? action,
  }) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: [
        Icon(icon, size: 32, color: AppColors.regionBlue),
        const SizedBox(height: 9),
        Text(message, textAlign: TextAlign.center),
        ?action,
      ],
    ),
  );

  Widget _taskCard(Map<String, dynamic> task, {required Color accent}) {
    final auth = context.watch<AuthProvider>();
    final isHod = auth.role == AppRole.hod;

    final title = _string(task['title'], fallback: 'Untitled task');
    final description = _string(task['description']);
    final dueDate = _formatDate(task['due_date'] ?? task['dueDate']);
    final priority = _string(task['priority'], fallback: 'medium');
    final status = _string(task['status'] ?? task['state']);

    // HOD sees ASM name(s)
    final assignments = task['assignments'] is List
        ? (task['assignments'] as List).whereType<Map>().toList()
        : <Map>[];
    final assignedTo = assignments
        .map((a) => _string(a['assigned_to_name']))
        .where((n) => n.isNotEmpty)
        .join(', ');

    // ASM sees HOD name
    final assignedBy = _string(
      task['assigned_by_name'] ?? task['created_by_name'],
    );

    final personLabel = isHod ? 'Assigned to' : 'Assigned by';
    final personName = isHod ? assignedTo : assignedBy;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0B2752),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.regionBlue,
                      ),
                    ),
                  ),
                  _tag(priority, AppColors.amberLight, AppColors.amberDark),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(color: AppColors.ink)),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (dueDate.isNotEmpty)
                    _tag(
                      'Due $dueDate',
                      AppColors.aiBlueBg,
                      AppColors.regionBlue,
                    ),
                  if (status.isNotEmpty)
                    _tag(status, AppColors.greenLight, AppColors.green),
                ],
              ),
              if (personName.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE9EEF7)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.aiBlueBg,
                      child: Text(
                        personName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.regionBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            personLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.steel,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            personName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Button  19-11-2026
                    Align(
                      alignment: Alignment.centerRight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.buttonGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _openCreateTask(task: task),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_add_alt_1_outlined,
                                    size: 15,
                                    color: AppColors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Assign Task',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color background, Color foreground) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: foreground,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  String _string(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final parsed = DateTime.tryParse(value.toString());
    return parsed == null
        ? value.toString()
        : DateFormat('dd MMM yyyy').format(parsed);
  }
}
