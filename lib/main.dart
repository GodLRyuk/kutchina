import 'package:flutter/material.dart';
import 'package:kutchina/core/offline/connectivity_service.dart';
import 'package:kutchina/core/offline/offline_banner.dart';
import 'package:kutchina/core/offline/pending_sync_screen.dart';
import 'package:kutchina/core/offline/sync_service.dart';
import 'package:kutchina/core/provider/app_providers.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/module/globalFeatures/otp/otp_screen.dart';
import 'package:kutchina/splash_screen.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';

import 'module/globalFeatures/auth/login_screen.dart';
import 'module/globalFeatures/auth/register_screen.dart';
import 'module/salesExe/pages/dashboard/dashboard_screen.dart';
import 'module/salesExe/pages/leads/leads_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
bool _sessionDialogVisible = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.onSessionExpired = _showSessionExpiredDialog;
  // Offline support: watch the network first, then let the queue start
  // (it replays saved orders/visits as soon as the server is reachable).
  await ConnectivityService.instance.start();
  await SyncService.instance.start();
  runApp(MultiProvider(providers: appProviders(), child: KutchinaSalesApp()));
}

Future<void> _showSessionExpiredDialog() async {
  final context = appNavigatorKey.currentContext;
  if (context == null || _sessionDialogVisible) return;

  _sessionDialogVisible = true;
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Session expired'),
        content: const Text(
          'Your session has expired. Please log in again to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            child: const Text('Login again'),
          ),
        ],
      ),
    );
  } finally {
    _sessionDialogVisible = false;
  }
}

void _openQueueScreen() {
  appNavigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => const PendingSyncScreen()),
  );
}

class KutchinaSalesApp extends StatelessWidget {
  const KutchinaSalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'kutchina Sales Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Offline / syncing status strip on every screen.
      builder: (context, child) => OfflineShell(
        onOpenQueue: _openQueueScreen,
        child: child ?? const SizedBox.shrink(),
      ),
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
