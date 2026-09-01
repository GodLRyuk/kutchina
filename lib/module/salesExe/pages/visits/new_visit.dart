import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';

class NewVisitScreen extends StatefulWidget {
  const NewVisitScreen({
    super.key,
    this.dealerName = 'Sharma Electronics',
    this.address = '42 Salt Lake Sector V, Kolkata 700091',
  });

  final String dealerName;
  final String address;

  @override
  State<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends State<NewVisitScreen> {
  final _purposeController = TextEditingController(
    text: 'Stock check & new display',
  );
  final _noteController = TextEditingController();
  bool _photoAdded = false;
  bool _noteAdded = false;

  String? _visitType; // Distributor / Retailer — no default
  String? _entity;

  static const _distributors = [
    'Sharma Electronics',
    'Newtown Appliances',
    'Howrah Home Center',
  ];
  static const _retailers = [
    'Baruipur Home Corner',
    'Sonarpur Electric Mart',
    'Garia Kitchen Studio',
  ];

  List<String> get _entityOptions =>
      _visitType == 'Distributor' ? _distributors : _retailers;

  String get _displayName => _entity ?? widget.dealerName;

  @override
  void dispose() {
    _purposeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addPhoto() {
    setState(() => _photoAdded = true);
    AppWidgets.toast(context, 'Photo attached');
  }

  Future<void> _addNote() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final controller = TextEditingController(text: _noteController.text);
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Visit note',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'What happened at this visit?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              AppWidgets.buildButton(
                'Save note',
                onTap: () => Navigator.pop(ctx, controller.text),
              ),
            ],
          ),
        );
      },
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _noteController.text = result.trim();
        _noteAdded = true;
      });
    }
  }

  Future<void> _pickEntity() async {
    if (_visitType == null) {
      AppWidgets.toast(context, 'Select Distributor or Retailer first');
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _entityOptions
              .map(
                (e) => ListTile(
                  title: Text(e),
                  onTap: () => Navigator.pop(ctx, e),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (picked != null) setState(() => _entity = picked);
  }

  void _checkIn() {
    if (_visitType == null) {
      AppWidgets.toast(context, 'Select Distributor or Retailer first');
      return;
    }
    if (_entity == null) {
      AppWidgets.toast(
        context,
        'Select a ${_visitType!.toLowerCase()} to check in',
      );
      return;
    }
    Navigator.pop(context, {
      'dealer': _displayName,
      'type': _visitType,
      'purpose': _purposeController.text.trim(),
      'note': _noteController.text.trim(),
      'photo': _photoAdded,
    });
    AppWidgets.toast(context, 'Checked in at $_displayName');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Visit check-in',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              height: 130,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFE3E1DB),
              ),
              child: CustomPaint(
                painter: _MapPlaceholderPainter(),
                child: const Align(
                  alignment: Alignment(0, -0.2),
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.red,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'VISIT TYPE',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.steel,
                      fontWeight: FontWeight.bold,
                      letterSpacing: .4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _typeBox(
                          title: 'Distributor',
                          icon: Icons.storefront_outlined,
                          selected: _visitType == 'Distributor',
                          onTap: () => setState(() {
                            _visitType = 'Distributor';
                            _entity = null;
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _typeBox(
                          title: 'Retailer',
                          icon: Icons.store_mall_directory_outlined,
                          selected: _visitType == 'Retailer',
                          onTap: () => setState(() {
                            _visitType = 'Retailer';
                            _entity = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                  if (_visitType != null) ...[
                    const SizedBox(height: 12),
                    AppWidgets.buildStaticField(
                      label: _visitType!,
                      value: _entity ?? 'Select $_visitType',
                      isPlaceholder: _entity == null,
                      onTap: _pickEntity,
                    ),
                  ],
                  const SizedBox(height: 12),

                  AppWidgets.buildTextField(
                    label: 'Purpose of visit',
                    controller: _purposeController,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _actionTile(
                          Icons.photo_camera_outlined,
                          _photoAdded ? 'Photo added' : 'Add photo',
                          _photoAdded,
                          _addPhoto,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionTile(
                          Icons.list_alt_outlined,
                          _noteAdded ? 'Note added' : 'Add note',
                          _noteAdded,
                          _addNote,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppWidgets.buildButton(
                    'Check in now',
                    icon: Icons.location_on_outlined,
                    onTap: _checkIn,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBox({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.redLight : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.red : AppColors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.redDark : AppColors.steel,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.redDark : AppColors.steel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.greenLight : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? AppColors.green : AppColors.line),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? AppColors.green : AppColors.steel,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? AppColors.green : AppColors.steel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cheap diagonal-stripe placeholder standing in for a map tile background.
class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDBD9D2)
      ..strokeWidth = 10;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(14),
      ),
    );
    const gap = 20.0;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
