import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/models/channel_model.dart';
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
  String? _orderType;
  String? _channel;
  String? _channelError;
  String? _orderTypeError;

  // Accent colours / icons for the channel cards (assigned by position,
  // so it works with whatever names ChannelModel returns).
  static const List<Color> _channelColors = [
    AppColors.regionBlue,
    AppColors.regionOrange,
    AppColors.regionPurple,
    AppColors.regionCyan,
  ];
  static const List<IconData> _channelIcons = [
    Icons.storefront_outlined,
    Icons.store_outlined,
    Icons.add_business_outlined,
    Icons.fact_check_outlined,
  ];

  @override
  void initState() {
    super.initState();
    setState(() {
      ChannelModel.loadChannels().then((_) {
        setState(() {});
      });
    });
  }

  void _continue() {
    setState(() {
      _channelError = _channel == null ? 'Select a channel' : null;
      _orderTypeError = _orderType == null ? 'Select an order type' : null;
    });

    if (_channelError != null || _orderTypeError != null) return;

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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: AppBackground(child: SizedBox.expand())),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
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
                    const SizedBox(height: 16),

                    // ---------- Header ----------
                    Row(
                      children: [
                        const Icon(
                          Icons.grid_view_rounded,
                          size: 14,
                          color: AppColors.regionBlue,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'CHANNEL',
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 12,
                            color: AppColors.commandCentreText,
                            fontWeight: FontWeight.bold,
                            letterSpacing: .4,
                          ),
                        ),
                        if (_channelError != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _channelError!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ---------- Channel grid (2 columns) ----------
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 12.0;
                        final cardWidth = (constraints.maxWidth - gap) / 2;
                        final channels = ChannelModel.channels;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: List.generate(channels.length, (i) {
                            return SizedBox(
                              width: cardWidth,
                              child: _channelCard(
                                name: channels[i],
                                color:
                                    _channelColors[i % _channelColors.length],
                                icon: _channelIcons[i % _channelIcons.length],
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // ---------- Order type ----------
                    if (_orderTypeError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          _orderTypeError!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    _optionCard(
                      title: 'PRIMARY',
                      subtitle: 'Distributor',
                      icon: Icons.storefront_outlined,
                      accent: AppColors.viewAllButton, // blue
                      selected: _orderType == 'D',
                      error: _orderTypeError != null,
                      onTap: () => setState(() {
                        _orderType = 'D';
                        _orderTypeError = null;
                      }),
                    ),
                    const SizedBox(height: 10),
                    _optionCard(
                      title: 'SECONDARY',
                      subtitle: 'Retailer',
                      icon: Icons.store_mall_directory_outlined,
                      accent: AppColors.regionCyan, // green/teal
                      selected: _orderType == 'R',
                      error: _orderTypeError != null,
                      onTap: () => setState(() {
                        _orderType = 'R';
                        _orderTypeError = null;
                      }),
                    ),

                    const SizedBox(height: 24),

                    // ---------- Submit ----------
                    AppWidgets.buildButton(
                      'Submit →',
                      onTap: _continue,
                      variant: AppButtonVariant.gradient,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelCard({
    required String name,
    required Color color,
    required IconData icon,
  }) {
    final active = _channel == name;
    final hasError = _channelError != null && _channel == null;

    return GestureDetector(
      onTap: () => setState(() {
        _channel = name;
        _channelError = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(active ? 0.16 : 0.07),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: hasError
                ? AppColors.red
                : color.withOpacity(active ? 1 : 0.7),
            width: active ? 1.8 : 1.2,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.check_circle, size: 16, color: color),
              ),
          ],
        ),
      ),
    );
  }

  Widget _optionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required bool selected,
    required VoidCallback onTap,
    bool error = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withOpacity(0.10)
              : AppColors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: error
                ? AppColors.red
                : accent.withOpacity(selected ? 1 : 0.8),
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
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
                  const SizedBox(height: 2),
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
            Icon(
              selected ? Icons.check_circle : Icons.chevron_right,
              color: accent,
            ),
          ],
        ),
      ),
    );
  }
}
