import 'package:flutter/material.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'area_feature_form_elements.dart';

enum AreaFeature {
  sales(
    title: 'Area sales',
    periods: ['Today', 'Week', 'Month'],
    resultValue: 'Rs 12.9Cr',
  ),
  branchCompare(
    title: 'Branch compare',
    periods: ['Today', 'Week', 'Month'],
    resultValue: 'Kolkata, Howrah, Siliguri',
  ),
  forecast(
    title: 'Area forecast',
    periods: ['Week', 'Month', 'Quarter'],
    resultValue: '91% likely',
  );

  final String title;
  final List<String> periods;
  final String resultValue;

  const AreaFeature({
    required this.title,
    required this.periods,
    required this.resultValue,
  });
}

class AreaFeatureFormScreen extends StatefulWidget {
  final AreaFeature feature;

  const AreaFeatureFormScreen({super.key, required this.feature});

  @override
  State<AreaFeatureFormScreen> createState() => _AreaFeatureFormScreenState();
}

class _AreaFeatureFormScreenState extends State<AreaFeatureFormScreen> {
  static const List<String> _scopes = [
    'Own team',
    'Whole branch',
    'Whole area',
  ];

  late String _period;
  String? _scope;
  String? _scopeError;
  bool _loading = false;
  bool _showResult = false;

  AreaFeature get _f => widget.feature;

  @override
  void initState() {
    super.initState();
    _period = _f.periods.first;
  }

  Future<void> _apply() async {
    if (_scope == null) {
      setState(() => _scopeError = 'Select a scope');
      return;
    }

    setState(() => _loading = true);

    // TODO: call your API here with _f, _period and _scope.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _loading = false;
      _showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: false,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar.brand(
        showBackButton: true,
        centerImage: const AssetImage('assets/images/logo.jpg'),
        actions: [],
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AreaHeaderCard(title: _f.title),
                const SizedBox(height: 20),
                AreaFiltersCard(
                  periods: _f.periods,
                  selectedPeriod: _period,
                  onPeriodChanged: (p) => setState(() {
                    _period = p;
                    _showResult = false;
                  }),
                  scopes: _scopes,
                  selectedScope: _scope,
                  scopeError: _scopeError,
                  onScopeChanged: (s) => setState(() {
                    _scope = s;
                    _scopeError = null;
                    _showResult = false;
                  }),
                ),
                if (_showResult) ...[
                  const SizedBox(height: 22),
                  AreaResultCard(
                    title: _f.title,
                    value: _f.resultValue,
                    onOpenReport: () {},
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: AreaGradientButton(
                        label: 'Submit',
                        loading: _loading,
                        onPressed: _apply,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AreaCancelButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
