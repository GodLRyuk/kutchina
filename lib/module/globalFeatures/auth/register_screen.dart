import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isSalesExec = true;
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _idController = TextEditingController();
  String territory = 'Select state ▾';

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _pickTerritory() async {
    final states = ['West Bengal', 'Bihar', 'Jharkhand', 'Odisha', 'Assam'];
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: states
              .map(
                (s) => ListTile(
                  title: Text(s),
                  onTap: () => Navigator.pop(ctx, s),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (picked != null) setState(() => territory = picked);
  }

  void _sendOtp() {
    if (_nameController.text.trim().isEmpty ||
        _mobileController.text.trim().isEmpty) {
      AppWidgets.toast(context, 'Fill in name and mobile number');
      return;
    }
    Navigator.pushNamed(
      context,
      '/otp',
      arguments: _mobileController.text.trim(),
    );
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
          'Create account',
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
            const Text(
              'I AM A',
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.steel,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isSalesExec = true),
                    child: _buildRoleCard(
                      'Sales executive',
                      Icons.person_outline,
                      isSalesExec,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isSalesExec = false),
                    child: _buildRoleCard(
                      'Dealer / distributor',
                      Icons.storefront_outlined,
                      !isSalesExec,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            AppWidgets.buildTextField(
              label: 'Full name',
              controller: _nameController,
              hint: 'e.g. Rohit Sharma',
            ),
            const SizedBox(height: 12),
            AppWidgets.buildTextField(
              label: 'Mobile number',
              controller: _mobileController,
              hint: '+91 98XXX XXXXX',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            AppWidgets.buildTextField(
              label: isSalesExec ? 'Employee ID' : 'GSTIN',
              controller: _idController,
              hint: isSalesExec ? 'KUT-EMP-0000' : '19AAACK1234F1Z5',
            ),
            const SizedBox(height: 12),
            AppWidgets.buildStaticField(
              label: 'Territory / state',
              value: territory,
              isPlaceholder: territory == 'Select state ▾',
              onTap: _pickTerritory,
            ),
            const SizedBox(height: 24),

            AppWidgets.buildButton('Send OTP', onTap: _sendOtp),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.redLight : AppColors.white,
        border: Border.all(color: isActive ? AppColors.red : AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.redDark : AppColors.steel,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? AppColors.redDark : AppColors.steel,
            ),
          ),
        ],
      ),
    );
  }
}
