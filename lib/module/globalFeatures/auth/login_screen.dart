import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/offline/connectivity_service.dart';
import 'package:kutchina/core/offline/offline_prefetch.dart';
import 'package:kutchina/core/offline/sync_service.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/services/auth_api.dart';
import 'package:kutchina/core/services/biometric_auth_service.dart';
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
  bool _fingerprintReady = false; // device supports it AND user enabled it
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initFingerprint();
  }

  Future<void> _initFingerprint() async {
    final available = await BiometricAuthService.isAvailable();
    final enabled = await BiometricAuthService.isEnabled();
    if (!mounted) return;
    setState(() => _fingerprintReady = available && enabled);
    if (_fingerprintReady) {
      // Prompt straight away, the user can still cancel and type a password.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loginWithFingerprint(),
      );
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Shared by password login, fingerprint login and offline login.
  void _enterApp(KUser user) {
    context.read<AuthProvider>().setUser(user);

    // Warm the offline cache (dropdowns etc.) and flush anything that was
    // saved while offline. Both are no-ops when there is no network.
    OfflinePrefetch.run();
    SyncService.instance.syncNow();

    if (user.role?.toLowerCase() == 'admin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminDashboard()),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  Future<void> _login() async {
    final userId = _mobileController.text.trim();
    final password = _passwordController.text;
    if (userId.isEmpty || password.isEmpty) {
      AppWidgets.toast(context, 'Enter mobile number and password');
      return;
    }

    setState(() => _loading = true);

    try {
      final loginResult = await AuthApi.login(
        username: userId,
        password: password,
      );
      if (!mounted) return;
      setState(() => _loading = false);

      await _offerFingerprint(userId, password);
      if (!mounted) return;

      _enterApp(loginResult.user);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      var message = error is ApiException
          ? error.message
          : 'Login failed. Try again.';
      if (error is ApiException && error.isNetworkError && _fingerprintReady) {
        message = 'No internet. Use fingerprint login to work offline.';
      }
      AppWidgets.toast(context, message);
    }
  }

  /// After a successful password login: keep the stored fingerprint
  /// credentials fresh, or ask once whether to turn fingerprint login on.
  Future<void> _offerFingerprint(String userId, String password) async {
    try {
      if (!await BiometricAuthService.isAvailable()) return;
      final userJson = await UserStore.getUser();
      if (userJson == null) return;

      if (await BiometricAuthService.isEnabled()) {
        await BiometricAuthService.refreshIfEnabled(
          userId: userId,
          password: password,
          userJson: userJson,
        );
        if (await BiometricAuthService.storedUserId() == userId) return;
      }
      if (!mounted) return;

      final replacing = await BiometricAuthService.isEnabled();
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            replacing
                ? 'Switch fingerprint login?'
                : 'Enable fingerprint login?',
          ),
          content: Text(
            replacing
                ? 'Fingerprint login is set up for another account on this phone. Use it for this account instead?'
                : 'Log in with your fingerprint next time, even when there is no internet. Your login is stored encrypted on this phone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
      if (yes != true) return;

      final ok = await BiometricAuthService.enable(
        userId: userId,
        password: password,
        userJson: userJson,
      );
      if (!mounted) return;
      AppWidgets.toast(
        context,
        ok ? 'Fingerprint login enabled' : 'Fingerprint not confirmed',
      );
      if (ok) setState(() => _fingerprintReady = true);
    } catch (_) {
      // Never block a successful login because of the optional fingerprint step.
    }
  }

  Future<void> _loginWithFingerprint() async {
    if (_loading) return;

    final ok = await BiometricAuthService.authenticate(
      'Log in to Kutchina Sales Companion',
    );
    if (!ok || !mounted) return;

    final creds = await BiometricAuthService.readCredentials();
    if (creds == null) {
      AppWidgets.toast(context, 'No saved login. Log in with password once.');
      return;
    }

    setState(() => _loading = true);

    if (ConnectivityService.instance.isOnline) {
      try {
        // Online: fresh tokens from the server, same as a password login.
        final result = await AuthApi.login(
          username: creds.userId,
          password: creds.password,
        );
        if (!mounted) return;
        setState(() => _loading = false);
        _enterApp(result.user);
        return;
      } on ApiException catch (e) {
        if (!e.isNetworkError) {
          // Server said no (password changed?). Do not fall into offline mode.
          if (!mounted) return;
          setState(() => _loading = false);
          AppWidgets.toast(
            context,
            '${e.message} Log in with your password to update fingerprint login.',
          );
          return;
        }
        // Server unreachable: continue with offline login below.
      }
    }

    await _offlineLogin();
  }

  /// No server to validate against, so the fingerprint itself is the proof.
  /// Restores the user profile saved at the last online login.
  Future<void> _offlineLogin() async {
    final json = await BiometricAuthService.readUserJson();
    if (!mounted) return;
    if (json == null) {
      setState(() => _loading = false);
      AppWidgets.toast(
        context,
        'Connect to the internet once to finish setting up offline login.',
      );
      return;
    }
    final user = KUser.fromJson(json);
    await UserStore.saveUser(json);
    if (!mounted) return;
    setState(() => _loading = false);
    AppWidgets.toast(context, 'Signed in offline');
    _enterApp(user);
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
              if (_fingerprintReady) ...[
                const SizedBox(height: 12),
                AppWidgets.buildButton(
                  'Login with fingerprint',
                  icon: Icons.fingerprint,
                  variant: AppButtonVariant.outline,
                  onTap: _loading ? null : _loginWithFingerprint,
                ),
              ],
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
