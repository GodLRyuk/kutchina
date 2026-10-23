import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/admin_bottom_nav.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/admin/reports/report_detail_screen.dart';
import 'package:kutchina/module/admin/reports/report_models.dart';
import 'package:flutter/material.dart';

/// Entry point for the "Reports" bottom-nav destination.
class ReportsHubScreen extends StatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  State<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends State<ReportsHubScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  static const List<Color> _cardAccents = [
    Color(0xFF1D5FD8),
    Color(0xFF12B981),
    Color(0xFFF07A2B),
    Color(0xFF9B2FD1),
    Color(0xFF5EB70A), 
    Color(0xFFBA0808),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _totalReports =>
      ReportCatalog.categories.fold(0, (sum, c) => sum + c.reports.length);

  List<ReportCategory> get _filteredCategories {
    if (_query.trim().isEmpty) return ReportCatalog.categories;
    final q = _query.toLowerCase();
    return ReportCatalog.categories
        .map(
          (c) => ReportCategory(
            name: c.name,
            reports: c.reports
                .where(
                  (r) =>
                      r.title.toLowerCase().contains(q) ||
                      r.subtitle.toLowerCase().contains(q),
                )
                .toList(),
          ),
        )
        .where((c) => c.reports.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: false,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar.simple(title: 'Reports'),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              // ---- Hero summary card ----
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E2430).withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.insights_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "REPORTS CENTER",
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: Text(
                        'Everything you need to track performance, in one place',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.90),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _heroStat('$_totalReports', 'Reports'),
                        Container(
                          width: 1,
                          height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                        _heroStat(
                          '${ReportCatalog.categories.length}',
                          'Categories',
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                        _heroStat('2', 'AI-powered'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ---- Search ----
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search reports',
                    hintStyle: const TextStyle(
                      color: AppColors.steelLight,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.steel,
                      size: 20,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.steel,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // ---- Categories ----
              if (categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 38,
                        color: AppColors.steelLight,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No reports match your search',
                        style: TextStyle(
                          color: AppColors.steel,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: category.reports.first.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category.name,
                              //category.name.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.steel,
                                letterSpacing: .5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${category.reports.length})',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.steel,
                                //color: AppColors.steelLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // ...category.reports.map(
                        //   (r) => Padding(
                        //     padding: const EdgeInsets.only(bottom: 10),
                        //     child: _ReportCard(report: r),
                        //   ),
                        // ),
                        ...category.reports.asMap().entries.map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(bottom: 14),
                            child: _ReportCard(
                              report: entry.value,
                              accent:
                                  _cardAccents[entry.key % _cardAccents.length],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: const AdminBottomNav(
          initialIndex: 1,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportConfig report;
  final Color accent;
  const _ReportCard({required this.report, required this.accent});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReportDetailScreen(report: report)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(report.icon, color: AppColors.white, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: accent,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.steel,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.ash,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                color: AppColors.black, //steel,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
