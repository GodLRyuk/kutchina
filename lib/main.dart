import 'package:flutter/material.dart';
import 'package:kutchina/core/provider/app_providers.dart';
import 'package:kutchina/module/globalFeatures/otp/otp_screen.dart';
import 'package:kutchina/splash_screen.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';

import 'module/globalFeatures/auth/login_screen.dart';
import 'module/globalFeatures/auth/register_screen.dart';
import 'module/salesExe/pages/dashboard/dashboard_screen.dart';
import 'module/salesExe/pages/leads/leads_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(providers: appProviders(), child: KutchinaSalesApp()));
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
