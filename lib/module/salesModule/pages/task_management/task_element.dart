import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kutchina/core/auth/app_roles.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/form_widgets.dart';

class TaskElement {
  TaskElement._();

  static Widget taskElementTopHeader({bool isEditMode = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Task',
            style: TextStyle(
              color: Colors.white,
              fontFamily: AppFonts.display,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Assign work and track the next steps',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // Task Card 19-11-2026
  
  static Widget taskElementSummaryCard(
    Map<String, dynamic> task, {
    VoidCallback? onAssign,
  }) {
    final title = (task['title'] ?? '').toString().trim();
    final description = (task['description'] ?? '').toString().trim();
    final priority = (task['priority'] ?? 'medium').toString().trim();

    final priorityText = priority.isEmpty
        ? 'Medium'
        : priority[0].toUpperCase() + priority.substring(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.aiBlue, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0B2752),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Icon
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.aiBlueBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              color: AppColors.regionBlue,
              size: 30,
            ),
          ),

          const SizedBox(width: 14),

          // Task Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title.isEmpty ? 'Untitled task' : title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.regionBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amberLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        priorityText,
                        style: const TextStyle(
                          color: AppColors.amberDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                // Description
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.steel,
                    ),
                  ),
                ],

                // Assign Button
                if (onAssign != null) ...[
                  const SizedBox(height: 12),
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
                          onTap: onAssign,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
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
                                  'Assign To',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Done

  static Widget taskElementForm(
    BuildContext context, {
    required TextEditingController titleController,
    required TextEditingController descriptionController,
    // required TextEditingController parentTaskController,
    required TextEditingController assigneeController,
    required TextEditingController reasonController,
    required DateTime dueDate,
    required ValueChanged<DateTime> onDueDateChanged,
    required String priority,
    required ValueChanged<String> onPriorityChanged,
    required AppRole userRole,
    bool canEditCoreFields = true,
    bool isEditMode = false,
    List<TaskUser> initialAssignees = const [],

    String status = 'pending',
    DateTime? followUpDate,
    ValueChanged<DateTime>? onFollowUpDateChanged,
    ValueChanged<String>?
    onStatusChanged, // ******************************************
  }) {
    Future<void> pickDueDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: dueDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) onDueDateChanged(picked);
    }

    Future<void> pickFollowUpDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: followUpDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) onFollowUpDateChanged?.call(picked);
    }

    Widget lock(Widget child) => canEditCoreFields
        ? child
        : IgnorePointer(child: Opacity(opacity: 0.6, child: child));

    // *********************************************
    const statusList = ['pending', 'in_progress', 'completed', "follow_up"];

    String pretty(String v) =>
        v.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    //*********************************************** */

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 21, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        border: Border.all(color: const Color(0xFFE6E4E5)),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100B2752),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          lock(
            FormWidgets.textField(
              label: 'Task title',
              controller: titleController,
              hint: 'e.g. Patna Retailer Visit',
              required: true,
            ),
          ),
          const SizedBox(height: 17),
          lock(
            FormWidgets.textField(
              label: 'Description',
              controller: descriptionController,
              hint: 'Describe the work to be completed',
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 17),
          FormWidgets.label('Due date', required: true),
          const SizedBox(height: 7),
          lock(
            InkWell(
              onTap: pickDueDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: FormWidgets.inputDecoration().copyWith(
                  suffixIcon: const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                  ),
                ),
                child: Text(
                  DateFormat('dd MMM yyyy').format(dueDate),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 17),
          FormWidgets.label('Priority', required: true),
          const SizedBox(height: 8),
          lock(
            Row(
              children: ['low', 'medium', 'high'].map((value) {
                final selected = priority == value;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: InkWell(
                      onTap: () => onPriorityChanged(value),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.regionBlue.withValues(alpha: 0.09)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.regionBlue
                                : const Color(0xFFE4E4E4),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          value[0].toUpperCase() + value.substring(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? AppColors.regionBlue
                                : AppColors.ink,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // const SizedBox(height: 17),
          // if (userRole != AppRole.hod) ...[
          //   FormWidgets.textField(
          //     label: 'Parent task ID',
          //     controller: parentTaskController,
          //     hint: 'Optional',
          //     keyboardType: TextInputType.number,
          //     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          //   ),
          // ],
          const SizedBox(height: 17),
          _TaskAssigneeField(
            controller: assigneeController,
            initialUsers: initialAssignees,
          ),
          const SizedBox(height: 17),
          FormWidgets.textField(
            label: 'Change reason',
            controller: reasonController,
            hint: 'e.g. Assigning work to SH',
            required: false,
          ),

          const SizedBox(height: 17),

          if (isEditMode) ...[
            FormWidgets.label('Status'),
            const SizedBox(height: 7),
            DropdownMenuFormField<String>(
              expandedInsets: EdgeInsets.zero,
              requestFocusOnTap: false,
              hintText: 'Select status',
              initialSelection: statusList.contains(status) ? status : null,
              dropdownMenuEntries: statusList
                  .map((s) => DropdownMenuEntry(value: s, label: pretty(s)))
                  .toList(),
              onSelected: (v) {
                if (v != null) onStatusChanged?.call(v);
              },
            ),
            const SizedBox(height: 17),
            if (status == 'follow_up') ...[
              FormWidgets.label('Follow up date', required: true),
              const SizedBox(height: 7),
              InkWell(
                onTap: pickFollowUpDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: FormWidgets.inputDecoration().copyWith(
                    suffixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                    ),
                  ),
                  child: Text(
                    followUpDate == null
                        ? 'Select date'
                        : DateFormat('dd MMM yyyy').format(followUpDate),
                    style: TextStyle(
                      fontSize: 15,
                      color: followUpDate == null ? Colors.grey.shade400 : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 17),
            ],
          ],
        ],
      ),
    );
  }
}

class _TaskAssigneeField extends StatefulWidget {
  const _TaskAssigneeField({
    required this.controller,
    this.initialUsers = const [],
  });

  final TextEditingController controller;
  final List<TaskUser> initialUsers;

  @override
  State<_TaskAssigneeField> createState() => _TaskAssigneeFieldState();
}

class _TaskAssigneeFieldState extends State<_TaskAssigneeField> {
  //List<TaskUser> _selectedUsers = [];
  late List<TaskUser> _selectedUsers = List.of(widget.initialUsers);

  Future<void> _selectAssignees(FormFieldState<String> field) async {
    final selectedUsers = await showModalBottomSheet<List<TaskUser>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _AssigneeSelectionSheet(initialSelection: _selectedUsers),
    );
    if (selectedUsers == null || !mounted) return;

    setState(() => _selectedUsers = selectedUsers);
    final ids = selectedUsers.map((user) => user.id).toList();
    widget.controller.text = ids.join(', ');
    field.didChange(widget.controller.text);
    field.validate();
  }

  String? _validate(String? value) {
    final assigneeIds = (value ?? '').split(',').map((id) => id.trim());
    if ((value ?? '').trim().isEmpty) {
      return 'Select at least one assignee';
    }
    if (assigneeIds.any((id) => int.tryParse(id) == null)) {
      return 'Select valid assignees';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller.text,
      validator: _validate,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormWidgets.label('Assignee To', required: true),
          const SizedBox(height: 5),
          InkWell(
            onTap: () => _selectAssignees(field),
            borderRadius: BorderRadius.circular(11),
            child: InputDecorator(
              isEmpty: _selectedUsers.isEmpty,
              decoration: FormWidgets.inputDecoration().copyWith(
                suffixIcon: const Icon(Icons.arrow_drop_down),
                errorText: field.errorText,
              ),
              child: _selectedUsers.isEmpty
                  ? Text(
                      'Search and select assignees',
                      style: TextStyle(color: Colors.grey.shade400),
                    )
                  : Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _selectedUsers
                          .map(
                            (user) => Chip(
                              label: Text(
                                user.fullName.isEmpty
                                    ? 'User ${user.id}'
                                    : user.fullName,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssigneeSelectionSheet extends StatefulWidget {
  const _AssigneeSelectionSheet({required this.initialSelection});

  final List<TaskUser> initialSelection;

  @override
  State<_AssigneeSelectionSheet> createState() =>
      _AssigneeSelectionSheetState();
}

class _AssigneeSelectionSheetState extends State<_AssigneeSelectionSheet> {
  final _searchController = TextEditingController();
  final Map<String, TaskUser> _selectedUsers = {};
  List<TaskUser> _users = [];
  Timer? _searchDebounce;
  String? _loadError;
  bool _isLoading = true;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    for (final user in widget.initialSelection) {
      _selectedUsers[user.id] = user;
    }
    _loadUsers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({String search = ''}) async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final page = await TaskUsersApi.fetchAssignTasks(
        pageSize: 50,
        search: search,
      ); // *********************************************

      if (!mounted || requestId != _requestId) return;
      setState(
        () => _users = page.users
            .where((user) => int.tryParse(user.id) != null)
            .toList(),
      );
    } on ApiException catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _loadError = error.message);
    } catch (e, st) {
      debugPrint('LOAD USERS ERROR: $e');
      debugPrint('$st');
      if (!mounted || requestId != _requestId) return;
      setState(() => _loadError = 'Unable to load users');
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _loadUsers(search: value.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = (screenHeight - bottomInset - 40).clamp(
      280.0,
      screenHeight * 0.82,
    );
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Stack(
        children: [
          const Positioned.fill(child: AppBackground(child: SizedBox.expand())),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                height: sheetHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Select Assignees',
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: FormWidgets.inputDecoration(
                        hint: 'Search users',
                      ).copyWith(prefixIcon: const Icon(Icons.search)),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '${_selectedUsers.length} selected',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.steel,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Expanded(child: _buildUserList()),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _selectedUsers.isEmpty
                              ? null
                              : AppColors.buttonGradient,
                          color: _selectedUsers.isEmpty
                              ? AppColors.steelLight
                              : null,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: _selectedUsers.isEmpty
                                ? null
                                : () => Navigator.pop(
                                    context,
                                    _selectedUsers.values.toList(),
                                  ),
                            child: const Center(
                              child: Text(
                                'Done',
                                style: TextStyle(
                                  fontFamily: AppFonts.display,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  _loadUsers(search: _searchController.text.trim()),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    if (_users.isEmpty) {
      return const Center(child: Text('No users found'));
    }
    return ListView.separated(
      itemCount: _users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = _users[index];
        final id = int.tryParse(user.id);
        if (id == null) return const SizedBox.shrink();
        final name = user.fullName.isEmpty ? 'User $id' : user.fullName;
        final selected = _selectedUsers.containsKey(user.id);
        final accent = index.isEven ? AppColors.aiBlue : AppColors.dayEndIconBg;
        return Material(
          color: AppColors.white.withValues(alpha: 0.9),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: accent, width: 1.5),
          ),
          child: ListTile(
            minVerticalPadding: 20,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
            title: Text(
              name.toUpperCase(),
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.regionBlue,
              ),
            ),
            subtitle: Text(
              ['ID: $id', if (user.email.isNotEmpty) user.email].join(' • '),
              style: const TextStyle(fontSize: 11, color: AppColors.steel),
            ),
            trailing: Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.regionBlue : accent,
            ),
            onTap: () {
              setState(() {
                if (!selected) {
                  _selectedUsers[user.id] = user;
                } else {
                  _selectedUsers.remove(user.id);
                }
              });
            },
          ),
        );
      },
    );
  }
}
