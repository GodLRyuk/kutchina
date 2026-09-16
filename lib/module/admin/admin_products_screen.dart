import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _searchController = TextEditingController();

  static const _products = [
    {
      'name': 'Chimneys',
      'value': '₹18.6L',
      'units': '412 units',
      'percent': 0.38,
      'label': '38%',
      'color': AppColors.productChimney,
      'icon': Icons.kitchen_outlined,
    },
    {
      'name': 'Hobs',
      'value': '₹12.4L',
      'units': '298 units',
      'percent': 0.26,
      'label': '26%',
      'color': AppColors.productHobs,
      'icon': Icons.local_fire_department_outlined,
    },
    {
      'name': 'Water Purifiers',
      'value': '₹9.8L',
      'units': '210 units',
      'percent': 0.20,
      'label': '20%',
      'color': AppColors.productWaterPurifiers,
      'icon': Icons.water_drop_outlined,
    },
    {
      'name': 'Ovens',
      'value': '₹7.8L',
      'units': '156 units',
      'percent': 0.16,
      'label': '16%',
      'color': AppColors.productOvens,
      'icon': Icons.microwave_outlined,
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _products;
    return _products
        .where((p) => (p['name'] as String).toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: const Text(
          'Products',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales performance by product category',
                style: TextStyle(fontSize: 12, color: AppColors.steel),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.line, width: 1.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 13, color: AppColors.ink),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, size: 18, color: AppColors.steel),
                    hintText: 'Search products',
                    hintStyle: TextStyle(
                      color: AppColors.steelLight,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No products found',
                          style: TextStyle(color: AppColors.steel),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _productCard(_filtered[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> p) {
    final color = p['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(p['icon'] as IconData, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['name'] as String,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      p['units'] as String,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                p['value'] as String,
                style: const TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: p['percent'] as double,
                    minHeight: 6,
                    backgroundColor: AppColors.ash,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                p['label'] as String,
                style: const TextStyle(fontSize: 10, color: AppColors.steel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
