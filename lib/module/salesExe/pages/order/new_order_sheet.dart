import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/pages/order/select_product_screen.dart';

Future<void> showNewOrderSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const _NewOrderSheet(),
  );
}

class _NewOrderSheet extends StatefulWidget {
  const _NewOrderSheet();

  @override
  State<_NewOrderSheet> createState() => _NewOrderSheetState();
}

class _NewOrderSheetState extends State<_NewOrderSheet> {
  String? _orderType; // Distributor / Retailer
  String? _channel; // Retailer / Direct Marketing / Vertical

  static const _channels = [
    'Retailer',
    'Premium',
    'Direct Marketing',
    'Vertical',
  ];

  void _continue() {
    if (_orderType == null || _channel == null) {
      AppWidgets.toast(context, 'Select order type and channel');
      return;
    }
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SelectProductScreen(orderType: _orderType!, channel: _channel!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'CHANNEL',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 10.5,
              color: AppColors.steel,
              fontWeight: FontWeight.bold,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _channels.map((c) {
              final active = _channel == c;
              return GestureDetector(
                onTap: () => setState(() => _channel = c),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.charcoal : AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: active ? AppColors.charcoal : AppColors.line,
                    ),
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.steel,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _optionCard(
            title: 'Primary',
            subtitle: 'Distributor',
            icon: Icons.storefront_outlined,
            selected: _orderType == 'Distributor',
            onTap: () => setState(() => _orderType = 'Distributor'),
          ),
          const SizedBox(height: 10),
          _optionCard(
            title: 'Secondary',
            subtitle: 'Retailer',
            icon: Icons.store_mall_directory_outlined,
            selected: _orderType == 'Retailer',
            onTap: () => setState(() => _orderType = 'Retailer'),
          ),
          const SizedBox(height: 18),

          const SizedBox(height: 20),
          AppWidgets.buildButton('Continue', onTap: _continue),
        ],
      ),
    );
  }

  Widget _optionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.rupeeIconBg : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.commandCentreText : AppColors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? AppColors.commandCentreText : AppColors.ash,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.steel,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.steel,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.commandCentreText)
            else
              const Icon(Icons.chevron_right, color: AppColors.steelLight),
          ],
        ),
      ),
    );
  }
}
