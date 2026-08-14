import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/features/auth/checkin_screen.dart';
import 'package:kutchina/features/leads/add_lead_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    if (index == 1) {
      Navigator.pushNamed(
        context,
        '/leads',
      ).then((_) => setState(() => _navIndex = 0));
      return;
    }
    setState(() => _navIndex = index);
    AppWidgets.toast(context, 'Coming soon');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning',
              style: TextStyle(fontSize: 11, color: AppColors.steel),
            ),
            Text(
              'Rohit Sharma',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => AppWidgets.toast(context, 'No new notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppWidgets.buildCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  AppWidgets.buildBurnerRing(
                    percent: 0.68,
                    centerLabel: '68%',
                    centerSubLabel: 'OF ₹12L',
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Monthly target · ₹8.2L achieved',
                    style: TextStyle(fontSize: 11, color: AppColors.steel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _quickAction(
                  Icons.chat_bubble_outline,
                  'New lead',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddLeadScreen()),
                  ),
                ),
                const SizedBox(width: 8),
                _quickAction(
                  Icons.location_on_outlined,
                  'Check-in',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckInScreen()),
                  ),
                ),
                const SizedBox(width: 8),
                _quickAction(
                  Icons.shopping_bag_outlined,
                  'New order',
                  () => AppWidgets.toast(context, 'Orders coming soon'),
                ),
                const SizedBox(width: 8),
                _quickAction(
                  Icons.list_alt_outlined,
                  'Collect',
                  () => AppWidgets.toast(context, 'Collect coming soon'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            AppWidgets.aiRecommendCard(
              'Call Ananya Das before noon — score 92, highest close-probability lead this week. '
              'Behala Kitchen World is 18 days without a visit — at risk of churn.',
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's visits · 3",
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.aiBlueChipBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✦ AI-sequenced route',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: AppColors.aiBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _visitCard(
              context,
              'Sharma Electronics',
              'Salt Lake, Kolkata',
              '42 Salt Lake Sector V, Kolkata 700091',
              '10:30 AM',
              AppColors.amberLight,
              AppColors.amberDark,
            ),
            const SizedBox(height: 8),
            _visitCard(
              context,
              'Newtown Appliances',
              'Newtown, Kolkata',
              'Newtown, Kolkata 700156',
              '1:00 PM',
              AppColors.coldBg,
              AppColors.coldText,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        selectedItemColor: AppColors.red,
        unselectedItemColor: AppColors.steel,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Leads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'Dealers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppColors.red),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _visitCard(
    BuildContext context,
    String name,
    String location,
    String address,
    String time,
    Color badgeBg,
    Color badgeColor,
  ) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckInScreen(dealerName: name, address: address),
        ),
      ),
      child: AppWidgets.buildCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.steel,
                  ),
                ),
              ],
            ),
            AppWidgets.buildBadge(time, badgeBg, badgeColor),
          ],
        ),
      ),
    );
  }
}
