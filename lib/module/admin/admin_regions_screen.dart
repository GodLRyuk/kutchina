import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/module/admin/detailsScreen/admin_regions_screen.dart';

class AdminRegionsScreen extends StatefulWidget {
  const AdminRegionsScreen({super.key});

  @override
  State<AdminRegionsScreen> createState() => _AdminRegionsScreenState();
}

class _AdminRegionsScreenState extends State<AdminRegionsScreen> {
  List<Zone> _zones = [];
  bool _isLoading = true;
  String? _loadError;

  static const List<Color> _colors = [
    AppColors.regionBlue,
    AppColors.regionPurple,
    AppColors.regionCyan,
    AppColors.regionOrange,
  ];

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final data = await MastersApi.fetchZones();
      if (!mounted) return;
      setState(() => _zones = data);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Unable to load regions');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openZone(Zone zone, Color color) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminRegionSalesScreen(zone: zone, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: const AppTopBar.simple(title: 'Regions'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Regions',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.commandCentreText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select a region to view its sales',
                style: TextStyle(fontSize: 12, color: AppColors.steel),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.steel),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadZones, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_zones.isEmpty) {
      return const Center(
        child: Text(
          'No regions found',
          style: TextStyle(color: AppColors.steel),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadZones,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _zones.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _regionCard(_zones[i], i),
      ),
    );
  }

  Widget _regionCard(Zone zone, int index) {
    final color = _colors[index % _colors.length];
    final statusColor = zone.isActive ? AppColors.steel : AppColors.steelLight;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _openZone(zone, color),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      zone.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(fontSize: 10.5, color: statusColor),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.steelLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
