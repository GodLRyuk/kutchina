import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'add_lead_screen.dart';
import 'lead_detail_screen.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  String selectedFilter = 'All';
  bool sortByAiScore = false;

  final List<Map<String, dynamic>> _leads = [
    {
      'name': 'Ananya Das',
      'product': 'Neo Elica 90cm Chimney',
      'location': 'Follow up today · Salt Lake',
      'score': 92,
      'status': 'Hot',
    },
    {
      'name': 'Debashish Ghosh',
      'product': 'Built-in Oven 60L',
      'location': 'Site visit scheduled · Howrah',
      'score': 87,
      'status': 'Hot',
    },
    {
      'name': 'Bimal Roy',
      'product': '3-Burner Auto Ignition Hob',
      'location': 'Quoted ₹9,500 · Behala',
      'score': 61,
      'status': 'Warm',
    },
    {
      'name': 'Priya Sen',
      'product': 'RO + UV Water Purifier',
      'location': 'No response · 12 days',
      'score': 18,
      'status': 'Cold',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    var list = selectedFilter == 'All'
        ? _leads
        : _leads.where((l) => l['status'] == selectedFilter).toList();
    if (sortByAiScore) {
      list = [...list]
        ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    }
    return list;
  }

  int _countFor(String status) =>
      _leads.where((l) => l['status'] == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leads',
          style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => AppWidgets.toast(context, 'Search coming soon'),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip('All · ${_leads.length}', 'All'),
                const SizedBox(width: 8),
                _filterChip('Hot · ${_countFor('Hot')}', 'Hot'),
                const SizedBox(width: 8),
                _filterChip('Warm · ${_countFor('Warm')}', 'Warm'),
                const SizedBox(width: 8),
                _filterChip('Cold · ${_countFor('Cold')}', 'Cold'),
                const SizedBox(width: 8),
                AppWidgets.buildChip(
                  '✦ Sort by AI score',
                  isActive: sortByAiScore,
                  activeColor: AppColors.aiBlue,
                  onTap: () => setState(() => sortByAiScore = !sortByAiScore),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final lead = _filtered[index];
                return AppWidgets.buildCard(
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LeadDetailScreen(lead: lead),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              lead['name'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                AppWidgets.buildAiScoreBadge(lead['score']),
                                const SizedBox(width: 6),
                                AppWidgets.buildStatusBadge(lead['status']),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lead['product'],
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.steel,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lead['location'],
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.steelLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.red,
        onPressed: () async {
          final newLead = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(builder: (_) => const AddLeadScreen()),
          );
          if (newLead != null) {
            setState(() => _leads.insert(0, newLead));
            AppWidgets.toast(context, 'Lead saved');
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    return AppWidgets.buildChip(
      label,
      isActive: selectedFilter == value,
      onTap: () => setState(() => selectedFilter = value),
    );
  }
}
