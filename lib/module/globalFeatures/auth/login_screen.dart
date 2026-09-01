import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/core/utils/responsive.dart';
import 'package:kutchina/module/admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isSalesExec = true;
  bool isAdmin = false;
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_mobileController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      AppWidgets.toast(context, 'Enter mobile number and password');
      return;
    }

    if (isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminDashboard()),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: AppColors.commandCentreText,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 55,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Sign in to manage your territory',
                      style: TextStyle(fontSize: 11.5, color: AppColors.steel),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Functional role switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEAE5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  children: [
                    Expanded(child: _roleTab('Sales exec', isSalesExec)),
                    Expanded(child: _roleTab('Dealer', !isSalesExec)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              AppWidgets.buildTextField(
                label: 'Mobile number',
                controller: _mobileController,
                hint: '+91 98XXX XXXXX',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              AppWidgets.buildTextField(
                label: 'Password',
                controller: _passwordController,
                hint: '••••••••',
                obscure: true,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: GestureDetector(
                    onTap: () =>
                        AppWidgets.toast(context, 'Password reset coming soon'),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 11,
                        color: AppColors.commandCentreText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              AppWidgets.buildButton('Log in', onTap: _login),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleTab(String label, bool active) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isSalesExec = label == 'Sales exec';
          isAdmin = !isSalesExec;
        });
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 11.5,
            fontWeight: active ? FontWeight.bold : FontWeight.w600,
            color: active ? AppColors.commandCentreText : AppColors.steel,
          ),
        ),
      ),
    );
  }
}
