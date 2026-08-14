import 'package:flutter/material.dart';
import 'package:kutchina/features/otp/otp_screen.dart';
import 'package:kutchina/splash_screen.dart';
import 'core/constants/app_theme.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/leads/leads_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KutchinaSalesApp());
}

class KutchinaSalesApp extends StatelessWidget {
  const KutchinaSalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kutchina Sales Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/otp': (context) => const OtpVerificationScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/leads': (context) => const LeadsScreen(),
      },
    );
  }
}
