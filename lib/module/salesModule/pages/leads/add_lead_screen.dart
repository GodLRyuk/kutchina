import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';

class AddLeadScreen extends StatefulWidget {
  const AddLeadScreen({super.key});

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _areaController = TextEditingController();
  final _notesController = TextEditingController();
  String product = 'Chimneys — Neo Elica 90cm ▾';
  String source = 'Walk-in';
  String priority = 'Warm';

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty ||
        _mobileController.text.trim().isEmpty) {
      AppWidgets.toast(context, 'Enter name and mobile number');
      return;
    }
    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'product': product.replaceAll(' ▾', ''),
      'location':
          '${_areaController.text.trim()}${_areaController.text.trim().isEmpty ? '' : ' · '}Just added',
      'score': priority == 'Hot' ? 75 : (priority == 'Warm' ? 45 : 15),
      'status': priority,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Order',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppWidgets.buildTextField(
              label: 'Customer name',
              controller: _nameController,
              hint: 'e.g. Ananya Das',
            ),
            const SizedBox(height: 12),
            AppWidgets.buildTextField(
              label: 'Mobile number',
              controller: _mobileController,
              hint: '+91 90XXX XXXXX',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            AppWidgets.buildTextField(
              label: 'Area / location',
              controller: _areaController,
              hint: 'e.g. Salt Lake, Kolkata',
            ),
            const SizedBox(height: 12),
            AppWidgets.buildStaticField(
              label: 'Product interested',
              value: product,
              onTap: () => _pickProduct(),
            ),
            const SizedBox(height: 12),

            _label('Source'),
            const SizedBox(height: 5),
            Row(
              children: ['Walk-in', 'Reference', 'Online']
                  .map(
                    (s) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: AppWidgets.buildChip(
                          s,
                          isActive: source == s,
                          onTap: () => setState(() => source = s),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),

            _label('Priority'),
            const SizedBox(height: 5),
            Row(
              children: ['Hot', 'Warm', 'Cold'].map((p) {
                final active = priority == p;
                final isHot = p == 'Hot';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: AppWidgets.buildChip(
                      p,
                      isActive: active,
                      activeColor: isHot && active ? AppColors.redLight : null,
                      activeTextColor: isHot && active
                          ? AppColors.redDark
                          : null,
                      onTap: () => setState(() => priority = p),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            AppWidgets.buildTextField(
              label: 'Notes',
              controller: _notesController,
              hint: 'Budget, preferences, anything useful for follow-up',
            ),
            const SizedBox(height: 24),

            AppWidgets.buildButton('Save lead', onTap: _save),
          ],
        ),
      ),
    );
  }

  void _pickProduct() async {
    final products = [
      'Chimneys — Neo Elica 90cm',
      'Hobs — 3-Burner Auto Ignition',
      'Ovens — Built-in 60L',
      'Purifiers — RO + UV',
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: products
              .map(
                (p) => ListTile(
                  title: Text(p),
                  onTap: () => Navigator.pop(ctx, p),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (picked != null) setState(() => product = '$picked ▾');
  }

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 10.5,
      color: AppColors.steel,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.4,
    ),
  );
}
