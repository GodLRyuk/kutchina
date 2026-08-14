import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isSalesExec = true;
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
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '9:41',
          style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 10.5),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontFamily: 'Sora',
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
              const SizedBox(height: 20),

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
                        fontSize: 11,
                        color: AppColors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              AppWidgets.buildButton('Log in', onTap: _login),
              const SizedBox(height: 10),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/register'),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 11.5, color: AppColors.steel),
                      children: [
                        TextSpan(text: 'New to Kutchina? '),
                        TextSpan(
                          text: 'Register',
                          style: TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleTab(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => isSalesExec = label == 'Sales exec'),
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
            fontFamily: 'Sora',
            fontSize: 11.5,
            fontWeight: active ? FontWeight.bold : FontWeight.w600,
            color: active ? AppColors.ink : AppColors.steel,
          ),
        ),
      ),
    );
  }
}
