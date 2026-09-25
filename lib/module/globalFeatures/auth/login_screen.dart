import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/services/auth_api.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/core/utils/responsive.dart';
import 'package:kutchina/module/admin/admin_dashboard.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const List<String> _roles = ['Sales Exec', 'Admin'];

  String _selectedRole = 'Sales Exec';

  bool _loading = false;
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

    setState(() => _loading = true);

    AuthApi.login(
          username: _mobileController.text.trim(),
          password: _passwordController.text,
        )
        .then((loginResult) {
          if (!mounted) return;
          context.read<AuthProvider>().setUser(loginResult.user);
          setState(() => _loading = false);

          if (loginResult.user.role?.toLowerCase() == 'admin') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminDashboard()),
            );
          } else {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        })
        .catchError((error) {
          if (!mounted) return;
          setState(() => _loading = false);
          final message = error is ApiException
              ? error.message
              : 'Login failed. Try again.';
          AppWidgets.toast(context, message);
        });
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
                      // width: 100,
                      // height: 55,
                      decoration: BoxDecoration(
                        color: AppColors.commandCentreText,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Image(
                        image: AssetImage('assets/images/logo.jpg'),
                        width: 100,
                        // height: 50,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Sign in to manage your territory',
                      style: TextStyle(fontSize: 11.5, color: AppColors.steel),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Role selector (dropdown)
              // _roleDropdown(),
              const SizedBox(height: 16),

              AppWidgets.buildTextField(
                label: 'User Id',
                controller: _mobileController,
                hint: 'KUT***',
                keyboardType: TextInputType.text,
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

              AppWidgets.buildButton(
                _loading ? 'Logging in…' : 'Log in',
                onTap: _loading ? null : _login,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFECEAE5),
        borderRadius: BorderRadius.circular(11),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.steel,
          ),
          borderRadius: BorderRadius.circular(11),
          dropdownColor: AppColors.white,
          items: _roles
              .map(
                (role) => DropdownMenuItem<String>(
                  value: role,
                  child: Text(
                    role,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.commandCentreText,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedRole = value);
          },
        ),
      ),
    );
  }
}
