import 'package:flutter/material.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:provider/provider.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/provider/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log out?',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'You will need to log in again to access your account.',
          style: TextStyle(fontSize: 13, color: AppColors.steel),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.bold,
                color: AppColors.steel,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log out',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.bold,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<AuthProvider>().logout();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.ash,
        body: Center(
          child: Text(
            'Not logged in',
            style: TextStyle(color: AppColors.steel),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppTopBar(
        title: 'My Profile',
        centerImage: const AssetImage('assets/images/logo.jpg'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 5, 20, 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.commandCentreText, AppColors.regionBlue],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.fullName.isNotEmpty ? user.fullName : user.userId,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 12,
                          color: AppColors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          user.userId,
                          style: TextStyle(
                            fontFamily: AppFonts.mono,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statusChip(
                        icon: user.isActive
                            ? Icons.check_circle_outline
                            : Icons.pause_circle_outline,
                        label: user.isActive ? 'Active' : 'Inactive',
                        color: user.isActive
                            ? AppColors.green
                            : AppColors.steel,
                      ),
                      const SizedBox(width: 8),
                      if (user.zone != null)
                        _statusChip(
                          icon: Icons.map_outlined,
                          label: user.zone!.name,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // ---- Info sections ----
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionLabel('Contact'),
                _sectionCard([
                  _infoRow(
                    Icons.mail_outline,
                    'Email',
                    user.email.isNotEmpty ? user.email : '—',
                  ),
                  _infoRow(
                    Icons.call_outlined,
                    'Phone',
                    user.phone.isNotEmpty ? user.phone : '—',
                  ),
                  _infoRow(
                    Icons.home_outlined,
                    'Address',
                    user.address.isNotEmpty ? user.address : '—',
                  ),
                ]),

                const SizedBox(height: 8),
                _sectionLabel('Territory'),
                _sectionCard([
                  _infoRow(
                    Icons.location_on_outlined,
                    'Location',
                    user.location?.name ?? '—',
                  ),
                  _infoRow(Icons.map_outlined, 'Zone', user.zone?.name ?? '—'),
                ]),

                const SizedBox(height: 8),
                _sectionLabel('Account'),
                _sectionCard([
                  _infoRow(Icons.badge_outlined, 'User ID', user.userId),
                  _infoRow(
                    Icons.verified_user_outlined,
                    'Role',
                    user.role ?? '—',
                  ),
                  _infoRow(
                    user.isActive
                        ? Icons.check_circle_outline
                        : Icons.pause_circle_outline,
                    'Status',
                    user.isActive ? 'Active' : 'Inactive',
                    valueColor: user.isActive
                        ? AppColors.green
                        : AppColors.steel,
                  ),
                ]),

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(
                      Icons.logout,
                      size: 18,
                      color: AppColors.red,
                    ),
                    label: const Text(
                      'Log out',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.red,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.red, width: 1.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      backgroundColor: AppColors.redLight,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color ?? AppColors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: AppColors.steel,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _sectionCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              const Divider(height: 1, color: AppColors.line),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.rupeeIconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: AppColors.commandCentreText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.steel),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
