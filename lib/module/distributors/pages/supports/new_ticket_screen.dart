import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/services/target_milestone_notification_service.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/module/distributors/pages/supports/new_ticket_elements.dart';
import 'package:kutchina/module/salesModule/pages/notification/notification.dart';
import 'package:provider/provider.dart';

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  List<TargetMilestoneNotification> _targetNotifications = [];
  final _descriptionController = TextEditingController();

  final List<String> _issueTypes = [
    'Damaged goods',
    'Wrong item delivered',
    'Payment issue',
    'Delivery delay',
    'Other',
  ];
  String? _selectedIssue = 'Damaged goods';

  final List<String> _orderNUmbers = [
    'KUTORD1001',
    'KUTORD1002',
    'KUTORD1003',
    'Other',
  ];
  String? _selectedOrder = 'KUTORD1001';

  void _resetForm() {
    setState(() {
      _selectedIssue = null;
      _selectedOrder = null;
    });
    _descriptionController.clear();
  }

  Future<void> _submit() async {
    if (!mounted) return;
    // await Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (_) => const TicketSuccessScreen()),
    // );
    Navigator.pop(context);
    if (!mounted) return;
    _resetForm();
  }

  Future<void> _openTargetNotifications() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) return;
    final notifications = await TargetMilestoneNotificationService.markAllRead(
      userId,
    );

    if (!mounted) return;
    setState(() => _targetNotifications = notifications);
    await NotificationScreen.show(context, notifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar.brand(
        showBackButton: true,
        centerImage: const AssetImage('assets/images/logo.jpg'),
        actions: [
          IconButton(
            onPressed: _openTargetNotifications,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (_targetNotifications.any(
                  (notification) => !notification.isRead,
                ))
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + kToolbarHeight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 22, top: 8),
                child: Text(
                  'New Ticket',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.commandCentreText,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsetsGeometry.all(12),
                child: Column(
                  children: [
                    NewTicketElements.dropdownField<String>(
                      label: 'Issue type',
                      value: _selectedIssue,
                      items: _issueTypes,
                      onChanged: (v) => setState(() => _selectedIssue = v),
                    ),

                    const SizedBox(height: 15),

                    NewTicketElements.dropdownField<String>(
                      label: 'Related Order / Invoice',
                      value: _selectedOrder,
                      items: _orderNUmbers,
                      onChanged: (v) => setState(() => _selectedOrder = v),
                    ),

                    const SizedBox(height: 15),

                    NewTicketElements.buildTextField(
                      label: "Describe the Problem",
                      controller: _descriptionController,
                    ),

                   SizedBox(height: MediaQuery.sizeOf(context).height * 0.06),
                    NewTicketElements.submitButton(label: "Submit Ticket", onPressed: _submit)
                  ],
                ),
              ),

              //
            ],
          ),
        ),
      ),
    );
  }
}
