import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/utils/dropdown.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';

class NewVisitScreen extends StatefulWidget {
  const NewVisitScreen({super.key});

  @override
  State<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends State<NewVisitScreen> {
  final _purposeController = TextEditingController(
    text: 'Stock check & new display',
  );
  final _noteController = TextEditingController();
  bool _noteAdded = false;
  File? _photoFile;
  bool get _photoAdded => _photoFile != null;
  String? _visitType; // 'Distributor' / 'Retailer' — used for UI only
  String? _entity;
  String? _entityName;
  String? _entityId;

  double? _lat;
  double? _long;
  bool _loadingLocation = false;
  String? _locationError;
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _distributors = [];
  List<dynamic> _retailers = [];
  bool _loadingEntities = false;
  String? _entityError;
  bool _submitting = false;
  String? _address;
  bool _loadingAddress = false;

  /// Maps the UI label to the API code expected by the backend.
  String? get _visitTypeCode {
    switch (_visitType) {
      case 'D':
        return 'D';
      case 'R':
        return 'R';
      default:
        return null;
    }
  }

  List<dynamic> get _entityList =>
      _visitType == 'D' ? _distributors : _retailers;

  List<String> get _entityOptions =>
      _entityList.map<String>((e) => e.name as String).toList();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadEntities() async {
    if (_visitType == null) return;
    setState(() {
      _loadingEntities = true;
      _entityError = null;
    });
    try {
      if (_visitType == 'D') {
        _distributors = await MastersApi.fetchDistributors();
      } else {
        _retailers = await MastersApi.fetchRetailers();
      }
      setState(() => _loadingEntities = false);
    } catch (e) {
      setState(() {
        _entityError =
            'Could not load ${_visitType == 'D' ? 'Distributors' : 'Retailers'}';
        _loadingEntities = false;
      });
    }
  }

  Future<void> _addPhoto() async {
    try {
      final XFile? shot = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // compress a bit before upload
        preferredCameraDevice: CameraDevice.rear,
      );
      if (shot == null) return; // user cancelled
      setState(() => _photoFile = File(shot.path));
      if (!mounted) return;
      AppWidgets.toast(context, 'Photo attached');
    } catch (e) {
      if (!mounted) return;
      AppWidgets.toast(context, 'Could not open camera');
    }
  }

  void _removePhoto() {
    setState(() => _photoFile = null);
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

    // Lazily load the list the first time this type is opened, or retry
    // after a previous failure.
    if (_entityOptions.isEmpty && !_loadingEntities) {
      await _loadEntities();
    }

    if (!mounted) return;

    if (_loadingEntities) {
      AppWidgets.toast(
        context,
        'Still loading ${_visitType == 'D' ? 'Distributors' : 'Retailers'}…',
      );
      return;
    }

    if (_entityError != null) {
      AppWidgets.toast(context, _entityError!);
      return;
    }

    if (_entityOptions.isEmpty) {
      AppWidgets.toast(
        context,
        'No ${_visitType == 'D' ? 'Distributors' : 'Retailers'} available',
      );
      return;
    }

    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => EntityPickerSheet(
        label: _visitType == 'D' ? 'Distributor' : 'Retailer',
        options: _entityOptions,
      ),
    );
    if (picked != null) {
      // Resolve the id from the name that came back from the sheet.
      dynamic match;
      for (final e in _entityList) {
        if (e.name == picked) {
          match = e;
          break;
        }
      }

      setState(() {
        _entity = picked;
        _entityId = match?.id;
        _entityName = match?.name?.toString();
      });
      print('Selected entity: $_entity ($_entityId)');
      print('Entity name: $_entityName');
    }
  }

  Future<void> _checkIn() async {
    if (_submitting) return;

    if (_visitType == null) {
      AppWidgets.toast(context, 'Select Distributor or Retailer first');
      return;
    }
    if (_entity == null || _entityId == null) {
      AppWidgets.toast(
        context,
        'Select a ${_visitType!.toLowerCase()} to check in',
      );
      return;
    }
    if (_lat == null || _long == null) {
      AppWidgets.toast(context, 'Fetching location, please wait…');
      await _getCurrentLocation();
      if (_lat == null || _long == null) return;
    }

    final payload = <String, dynamic>{
      'visit_type': _visitTypeCode,
      'visitor_id': _entityId,
      'visitor_name': _entityName,
      'visit_purpose': _purposeController.text.trim(),
      'note': _noteController.text.trim(),
      'lat': _lat?.toString() ?? '',
      'long': _long?.toString() ?? '',
      'address': _address ?? '',
    };

    if (_photoFile != null) {
      payload['image'] = await MultipartFile.fromFile(
        _photoFile!.path,
        filename: _photoFile!.path.split('/').last,
      );
    }

    setState(() => _submitting = true);
    try {
      await VisitService.checkIn(payload: payload);
      if (!mounted) return;
      AppWidgets.toast(context, 'Checked in successfully');
      if (Navigator.canPop(context)) {
        Navigator.pop(context, payload);
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException
          ? e.message
          : 'Check-in failed. Try again.';
      AppWidgets.toast(context, message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are off';
          _loadingLocation = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied';
            _loadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location permission permanently denied. Enable it in Settings.';
          _loadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _long = position.longitude;
        _loadingLocation = false;
      });

      // Reverse geocode once we have coordinates.
      _resolveAddress(position.latitude, position.longitude);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Could not get location';
        _loadingLocation = false;
      });
    }
  }

  Future<void> _resolveAddress(double lat, double long) async {
    print('Resolving address for coordinates: $lat, $long');
    setState(() => _loadingAddress = true);
    try {
      final geocoding = Geocoding();
      final placemarks = await geocoding.placemarkFromCoordinates(lat, long);
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.postalCode,
          p.country,
        ].where((s) => s != null && s.trim().isNotEmpty).toList();
        setState(() {
          _address = parts.join(', ');
          _loadingAddress = false;
        });
        print('Resolved address: $_address');
      } else {
        setState(() {
          _address = null;
          _loadingAddress = false;
        });
      }
    } catch (e) {
      print('Reverse geocoding failed: $e');
      if (!mounted) return;
      setState(() {
        _address = null;
        _loadingAddress = false;
      });
    }
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
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
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
                  if (_loadingAddress)
                    const Positioned(
                      left: 10,
                      bottom: 10,
                      child: Text(
                        'Resolving address…',
                        style: TextStyle(fontSize: 10.5),
                      ),
                    )
                  else if (_address != null)
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _address!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5),
                        ),
                      ),
                    ),
                ],
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
                          selected: _visitType == 'D',
                          onTap: () {
                            if (_visitType == 'D')
                              return; // no-op if already selected
                            setState(() {
                              _visitType = 'D';
                              _entity = null;
                              _entityId = null;
                              _entityName = null;
                              _entityError = null;
                              _purposeController.text =
                                  'Stock check & new display';
                              _noteController.clear();
                              _noteAdded = false;
                              _photoFile = null;
                            });
                            _loadEntities();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _typeBox(
                          title: 'Retailer',
                          icon: Icons.store_mall_directory_outlined,
                          selected: _visitType == 'R',
                          onTap: () {
                            if (_visitType == 'R')
                              return; // no-op if already selected
                            setState(() {
                              _visitType = 'R';
                              _entity = null;
                              _entityId = null;
                              _entityName = null;
                              _entityError = null;
                              _purposeController.text =
                                  'Stock check & new display';
                              _noteController.clear();
                              _noteAdded = false;
                              _photoFile = null;
                            });
                            _loadEntities();
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_visitType != null) ...[
                    const SizedBox(height: 12),
                    if (_loadingEntities)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.commandCentreText,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Loading ${_visitType == 'D' ? 'Distributors' : 'Retailers'}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.steel,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_entityError != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.redLight,
                          border: Border.all(
                            color: AppColors.red.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 16,
                              color: AppColors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _entityError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.redDark,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _loadEntities,
                              child: const Text(
                                'Retry',
                                style: TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      AppWidgets.buildStaticField(
                        label: _visitType == 'D' ? 'Distributor' : 'Retailer',
                        value:
                            _entity ??
                            'Select ${_visitType == 'D' ? 'Distributor' : 'Retailer'}',
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

                  if (_photoFile != null) ...[
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _photoFile!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: _removePhoto,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                  AppWidgets.buildButton(
                    'Submit',
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
