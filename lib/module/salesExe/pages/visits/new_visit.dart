import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/offline/connectivity_service.dart';
import 'package:kutchina/core/offline/sync_service.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/utils/dropdown.dart';
import 'package:kutchina/core/utils/note_sheet.dart';
import 'package:kutchina/core/utils/voice_input_sheet.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/core/widgets/suggestion_dropdown.dart';
import 'package:kutchina/module/salesExe/models/product_model.dart';

class NewVisitScreen extends StatefulWidget {
  const NewVisitScreen({super.key});

  @override
  State<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends State<NewVisitScreen> {
  final _purposeController = TextEditingController();
  final _noteController = TextEditingController();
  final _otherController = TextEditingController();
  bool _noteAdded = false;
  File? _photoFile;
  bool get _photoAdded => _photoFile != null;
  String? _visitType; // 'Distributor' / 'Retailer' — used for UI only
  String? _entity;
  String? _entityName;
  String? _entityId;

  double? _lat;
  double? _long;
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _distributors = [];
  List<dynamic> _retailers = [];
  List<SuggestionModel> _suggestions = [];
  List<SuggestionModel> _filtered = [];
  bool _loadingEntities = false;
  String? _entityError;
  bool _submitting = false;
  String? _address;
  bool _loadingLocation = true;
  bool _loadingAddress = false;
  final List<File> _extraPhotos = [];
  String _lastQuery = '';

  static const double _sidePad = 14;
  static const double _boxRadius = 14;
  static const double _typeBoxHeight = 77;
  static const double _fieldHeight = 57;
  static const double _actionTileHeight = 57;
  static const double _micSize = 40;
  static const double _mapHeight = 166;

  SizedBox _vGap(double fraction) =>
      SizedBox(height: MediaQuery.sizeOf(context).height * fraction);

  SizedBox _hGap(double fraction) =>
      SizedBox(width: MediaQuery.sizeOf(context).width * fraction);

  /// Maps the UI label to the API code expected by the backend.
  String? get _visitTypeCode {
    switch (_visitType) {
      case 'D':
        return 'D';
      case 'R':
        return 'R';
      case 'O':
        return 'O';
      default:
        return null;
    }
  }

  List<dynamic> get _entityList =>
      // _visitType == 'D' ? _distributors : _retailers;
      _visitType == 'D'
      ? _distributors
      : _visitType == 'R'
      ? _retailers
      : [];

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
    _otherController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions(String query) async {
    try {
      final data = await MastersApi.fetchSuggestions(query);
      if (!mounted) return;
      if (query != _lastQuery) return; // ignore stale responses

      setState(() {
        _suggestions = data;
        _filtered = data;
      });
    } catch (e) {
      if (!mounted) return;
      AppWidgets.toast(context, 'Failed to load suggestions');
    }
  }

  void _fetchNow(String value) {
    final query = value.trim();
    if (query.isEmpty || query == _lastQuery) return;
    _lastQuery = query;
    _loadSuggestions(query);
  }

  void _onPurposeChanged(String value) {
    if (value.endsWith(' ') && value.trim().isNotEmpty) {
      _fetchNow(value);
      return;
    }
    _lastQuery = '';
    if (_filtered.isNotEmpty || _suggestions.isNotEmpty) {
      setState(() {
        _suggestions = [];
        _filtered = [];
      });
    }
  }

  void _selectSuggestion(SuggestionModel s) {
    final newText = '${_purposeController.text.trimRight()} ${s.text} ';

    _purposeController.text = newText;
    _purposeController.selection = TextSelection.collapsed(
      offset: newText.length,
    );

    setState(() {
      _filtered = [];
    });

    _fetchNow(newText); // next suggestions for the full text
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
      } else if (_visitType == 'R') {
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

  // Add 29-9-2026
  Future<void> _pickPhoto() async {
    try {
      final XFile? shot = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (shot == null) return;
      setState(() => _extraPhotos.add(File(shot.path)));
    } catch (e) {
      if (!mounted) return;
      AppWidgets.toast(context, 'Could not open camera');
    }
  }

  void _removeExtraPhoto(int index) {
    setState(() => _extraPhotos.removeAt(index));
  }

  void _viewPhoto(File files) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(child: Image.file(files, fit: BoxFit.contain)),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNote() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => NoteSheet(
        initialText: _noteController.text,
        suggestions: _suggestions,
      ),
    );

    if (!mounted) return;
    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _noteController.text = result.trim();
        _noteAdded = true;
      });
    }
  }

  Future<void> _pickEntity() async {
    if (_visitType == null) {
      AppWidgets.toast(
        context,
        'Select Distributor or Retailer or Others first',
      );
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
    }
  }

  Future<void> _checkIn() async {
    if (_submitting) return;

    if (_visitType == null) {
      AppWidgets.toast(
        context,
        'Select Distributor or Retailer or Others first',
      );
      return;
    }
    if (_visitType != 'O' && (_entity == null || _entityId == null)) {
      AppWidgets.toast(
        context,
        'Select a ${_visitType == 'D' ? 'Distributor' : 'Retailer'} to check in',
      );
      return;
    }
    if (_visitType == 'O' && _otherController.text.trim().isEmpty) {
      AppWidgets.toast(context, 'Please specify visit type');
      return;
    }
    if (_lat == null || _long == null) {
      AppWidgets.toast(context, 'Fetching location, please wait…');
      await _getCurrentLocation();
      if (!mounted) return;
      if (_lat == null || _long == null) return;
    }
    if (_address == null || _address!.trim().isEmpty) {
      AppWidgets.toast(context, 'Resolving address, please wait…');
      await _resolveAddress(_lat!, _long!);
      if (!mounted) return;
    }
    if (!_hasCapturedAddress) {
      await _showLocationNotCapturedAlert();
      return;
    }
    if (_noteController.text == "") {
      AppWidgets.toast(context, "Please Enter Note");
      return;
    }
    if (_photoFile == null) {
      AppWidgets.toast(context, "Please Take a selfie");
      return;
    }

    final isOther = _visitType == 'O';

    final payload = <String, dynamic>{
      'visit_type': _visitTypeCode,
      'visitor_id': _entityId,
      'visitor_name': isOther ? _otherController.text.trim() : _entityName,
      'visit_purpose': _purposeController.text.trim(),
      'note': _noteController.text.trim(),
      'lat': _lat?.toString() ?? '',
      'long': _long?.toString() ?? '',
      'address': _address!.trim(),
    };
    final imagePaths = <String>[
      if (_photoFile != null) _photoFile!.path,
      ..._extraPhotos.map((f) => f.path),
    ];

    debugPrint('===== CHECK-IN PAYLOAD =====');
    payload.forEach((key, value) => debugPrint('$key: $value'));
    debugPrint('images: ${imagePaths.length}');
    setState(() => _submitting = true);
    try {
      final result = await VisitService.checkIn(
        payload: payload,
        imagePaths: imagePaths,
      );
      if (!mounted) return;
      AppWidgets.toast(
        context,
        result == SubmitResult.queued
            ? 'Saved offline. Visit will sync when internet returns'
            : 'Checked in successfully',
      );
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

  Future<void> _voiceForPurpose() async {
    final text = await showVoiceInputSheet(context);
    if (text == null || text.isEmpty || !mounted) return;
    setState(() {
      final old = _purposeController.text.trim();
      _purposeController.text = old.isEmpty ? text : '$old $text';
      _purposeController.selection = TextSelection.collapsed(
        offset: _purposeController.text.length,
      );
    });
    _onPurposeChanged(_purposeController.text);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {});
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {});
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {});
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _long = position.longitude;
      });

      // Reverse geocode once we have coordinates.
      await _resolveAddress(position.latitude, position.longitude);
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _resolveAddress(double lat, double long) async {
    // Reverse geocoding needs internet. Offline, keep the raw coordinates
    // instead of waiting on a lookup that cannot succeed.
    if (!ConnectivityService.instance.isOnline) {
      if (!mounted) return;
      setState(() {
        _address = '$lat, $long';
        _loadingAddress = false;
      });
      return;
    }
    setState(() => _loadingAddress = true);
    try {
      final geocoding = Geocoding();
      final placemarks = await geocoding.placemarkFromCoordinates(lat, long);
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts =
            [
                  p.name,
                  p.subThoroughfare,
                  p.thoroughfare,
                  p.street,
                  p.subLocality,
                  p.locality,
                  p.subAdministrativeArea,
                  p.administrativeArea,
                  p.postalCode,
                  p.country,
                ]
                .whereType<String>()
                .map((part) => part.trim())
                .where((part) => part.isNotEmpty)
                .toSet()
                .toList();
        final resolvedAddress = parts.join(', ');
        setState(() {
          _address = resolvedAddress.isEmpty ? '$lat, $long' : resolvedAddress;
          _loadingAddress = false;
        });
      } else {
        setState(() {
          _address = '$lat, $long';
          _loadingAddress = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _address = '$lat, $long';
        _loadingAddress = false;
      });
    }
  }

  bool get _hasCapturedAddress {
    final address = _address?.trim();
    if (address == null || address.isEmpty) return false;
    // Offline: coordinates are the best we can capture, accept them.
    if (!ConnectivityService.instance.isOnline) return true;
    final coordinateFallback = '$_lat, $_long';
    return address != coordinateFallback;
  }

  Future<void> _showLocationNotCapturedAlert() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Location not captured'),
        content: const Text(
          'The address could not be captured. Please retry your location before submitting the visit.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _getCurrentLocation();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Same state reset the three type boxes used to do inline.
  void _selectType(String code) {
    if (_visitType == code) return; // no-op if already selected
    setState(() {
      _visitType = code;
      _entity = null;
      _entityId = null;
      _entityName = null;
      _entityError = null;
      if (code == 'O') _loadingEntities = false;
      _purposeController.text = 'Stock check & new display';
      _noteController.clear();
      _noteAdded = false;
      _photoFile = null;
    });
    if (code != 'O') _loadEntities();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar.brand(
        showBackButton: true,
        centerImage: const AssetImage('assets/images/logo.jpg'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => AppWidgets.toast(context, 'No new notifications'),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 22, top: 8),
                child: Text(
                  'Visit check-in',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.commandCentreText,
                  ),
                ),
              ),
              
               
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    _sidePad,
                    18,
                    _sidePad,
                    24 + bottomInset,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                       _mapCard(),
                        const SizedBox(height: 18),
                      // ---------------- Visit type ----------------
                      _sectionLabel('VISIT TYPE', AppColors.regionBlue),
                      _vGap(0.01),
                      Row(
                        children: [
                          Expanded(
                            child: _typeBox(
                              title: 'Distributor',
                              icon: Icons.storefront_outlined,
                              //color: AppColors.regionBlue,
                              color: AppColors.aiBlue,
                              selected: _visitType == 'D',
                              onTap: () => _selectType('D'),
                            ),
                          ),
                          _hGap(0.025),
                          Expanded(
                            child: _typeBox(
                              title: 'Retailer',
                              icon: Icons.store_mall_directory_outlined,
                              color: AppColors.productOvens,
                              selected: _visitType == 'R',
                              onTap: () => _selectType('R'),
                            ),
                          ),
                          _hGap(0.025),
                          Expanded(
                            child: _typeBox(
                              title: 'Others',
                              icon: Icons.more_horiz,
                              color: AppColors.productChimney,
                              selected: _visitType == 'O',
                              onTap: () => _selectType('O'),
                            ),
                          ),
                        ],
                      ),
                      if (_visitType == 'O') ...[
                        _vGap(0.015),
                        AppWidgets.buildTextField(
                          label: 'Name',
                          controller: _otherController,
                        ),
                      ],
                      if (_visitType == 'D' || _visitType == 'R') ...[
                        _vGap(0.015),
                        _entitySection(),
                      ],

                      // ---------------- Purpose ----------------
                      _vGap(0.025),
                      _sectionLabel('PURPOSE OF VISIT', AppColors.dayEndIconBg),
                      _vGap(0.01),
                      _purposeField(),
                      Padding(
                        padding: const EdgeInsets.only(right: 60),
                        child: SuggestionDropdown(
                          items: _filtered,
                          onSelect: _selectSuggestion,
                        ),
                      ),

                      // ---------------- Photo + note ----------------
                      _vGap(0.032),
                      Row(
                        children: [
                          Expanded(
                            child: _actionTile(
                              Icons.photo_camera_outlined,
                              _photoAdded ? 'Photo added' : 'Add photo',
                              _photoAdded,
                              AppColors.regionBlue,
                              _addPhoto,
                            ),
                          ),
                          _hGap(0.03),
                          Expanded(
                            child: _actionTile(
                              Icons.list_alt_outlined,
                              _noteAdded ? 'Note added' : 'Add note',
                              _noteAdded,
                              AppColors.regionOrange,
                              _addNote,
                            ),
                          ),
                        ],
                      ),
                      if (_photoFile != null) ...[
                        _vGap(0.022),
                        _selfiePreview(),
                      ],

                      // ---------------- Extra photos ----------------
                      _vGap(0.025),
                      _photoSection(),

                      // ---------------- Submit ----------------
                      _vGap(0.0300),
                      _submitButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================================================
  //                           DESIGN PIECES
  // ===================================================================
  Widget _sectionLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 10.5,
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: .4,
      ),
    );
  }

  Widget _mapCard() {
    final loading = _loadingLocation || _loadingAddress;
    return Container(
      height: _mapHeight,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE6F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: const Color(0xFFEFF3F8),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapPlaceholderPainter(),
                  child: Center(
                    child: loading
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.dayEndIconBg,
                            ),
                          )
                        : const Padding(
                            padding: EdgeInsets.only(bottom: 40),
                            child: Icon(
                              Icons.location_on,
                              color: AppColors.dayEndIconBg,
                              size: 38,
                            ),
                          ),
                  ),
                ),
              ),
              if (loading)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Text(
                    _loadingLocation
                        ? 'Getting your location…'
                        : 'Resolving address…',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                )
              else if (_address != null)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.96),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: AppColors.regionBlue,
                        ),
                        _hGap(0.02),
                        Expanded(
                          child: Text(
                            _address!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                              height: 1.4,
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
    );
  }

  Widget _entitySection() {
    if (_loadingEntities) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.line, width: 1.3),
          borderRadius: BorderRadius.circular(10),
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
            _hGap(0.025),
            Text(
              'Loading ${_visitType == 'D' ? 'Distributors' : 'Retailers'}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.steel),
            ),
          ],
        ),
      );
    }
    if (_entityError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.redLight,
          border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: AppColors.red),
            _hGap(0.02),
            Expanded(
              child: Text(
                _entityError!,
                style: const TextStyle(fontSize: 12, color: AppColors.redDark),
              ),
            ),
            GestureDetector(
              onTap: _loadEntities,
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.red,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return AppWidgets.buildStaticField(
      label: _visitType == 'D' ? 'Distributor' : 'Retailer',
      value:
          _entity ?? 'Select ${_visitType == 'D' ? 'Distributor' : 'Retailer'}',
      isPlaceholder: _entity == null,
      onTap: _pickEntity,
    );
  }

  /// Teal-outlined purpose field with the mic inside it.
  Widget _purposeField() {
    OutlineInputBorder border(double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(_boxRadius),
      borderSide: BorderSide(
        color: AppColors.dayEndIconBg.withOpacity(.7),
        width: w,
      ),
    );

    return TextField(
      controller: _purposeController,
      onChanged: _onPurposeChanged,
      style: const TextStyle(fontSize: 15, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: 'Enter purpose of visit',
        hintStyle: const TextStyle(fontSize: 15, color: AppColors.steelLight),
        filled: true,
        fillColor: Colors.white,
        constraints: const BoxConstraints.tightFor(height: _fieldHeight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: border(1.3),
        focusedBorder: border(1.6),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 9),
          child: _micButton(),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }

  Widget _micButton() {
    return Semantics(
      button: true,
      label: 'Voice input for purpose',
      child: Material(
        color: AppColors.redLight,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: _voiceForPurpose,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: _micSize,
            height: _micSize,
            child: Icon(Icons.mic, color: AppColors.red, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _submitButton() {
    final disabled = _submitting || _loadingLocation || _loadingAddress;
    final label = _submitting
        ? 'Submitting...'
        : (_loadingLocation || _loadingAddress
              ? 'Loading location...'
              : 'Submit →');

    return Opacity(
      opacity: disabled ? .75 : 1,
      child: AppWidgets.buildButton(
        label,
        onTap: disabled ? null : _checkIn,
        variant: AppButtonVariant.gradient,
        // icon: Icons.location_on_outlined,
        loading: _submitting,
      ),
    );
  }

  /// Square selfie preview. Change [size] to resize it.
Widget _selfiePreview() {
  const double size = 140;
  const double border = 2;
  const double radius = 14;

  return Align(
    alignment: Alignment.centerLeft,
    child: GestureDetector(
      onTap: () => _viewPhoto(_photoFile!),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.green, width: border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - border),
          child: Image.file(
            _photoFile!,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            cacheWidth: 600,
          ),
        ),
      ),
    ),
  );
}
  Widget _photoSection() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    const perRow = 4;
    final box = ((screenWidth - (_sidePad * 2) - 10 * (perRow - 1)) / perRow)
        .floorToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.image_outlined,
              size: 22,
              color: AppColors.productChimney,
            ),
            _hGap(0.015),
            const Text(
              'PHOTOS',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: .4,
                color: AppColors.productChimney,
              ),
            ),
            const Spacer(),
            Material(
              color: AppColors.productChimney.withOpacity(
                _extraPhotos.isEmpty ? .07 : .12,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: AppColors.productChimney.withOpacity(.35),
                ),
              ),
              child: InkWell(
                onTap: _pickPhoto,
                customBorder: const StadiumBorder(),
                child: Padding(
                  // ~33dp high pill
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _extraPhotos.isEmpty
                            ? Icons.photo_camera_outlined
                            : Icons.add_a_photo_outlined,
                        size: 20,
                        color: AppColors.productChimney,
                      ),
                      _hGap(0.015),
                      Text(
                        _extraPhotos.isEmpty
                            ? 'Capture Photos'
                            : 'Add more photos',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.productChimney,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_extraPhotos.isNotEmpty) ...[
          _vGap(0.018),
          // Photos wrap onto the next line automatically
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              for (int i = 0; i < _extraPhotos.length; i++)
                _thumb(_extraPhotos[i], () => _removeExtraPhoto(i), size: box),
            ],
          ),
        ],
      ],
    );
  }

  Widget _thumb(
    File file,
    VoidCallback onRemove, {
    String? label,
    double size = 72,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Photo
          GestureDetector(
            onTap: () => _viewPhoto(file),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.file(file, fit: BoxFit.cover, cacheWidth: 300),
              ),
            ),
          ),

          // Selfie label
          if (label != null)
            Positioned(
              left: 5,
              bottom: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.black.withOpacity(.60),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Remove button
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1.5),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ***************************************************************
  Widget _typeBox({
    required String title,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_boxRadius),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: selected ? color.withOpacity(.10) : color.withOpacity(.03),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_boxRadius),
            side: BorderSide(
              color: selected ? color : color.withOpacity(.55),
              width: selected ? 1.8 : 1.2,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: _typeBoxHeight,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 26, color: color),
                    // Tiny gap — kept fixed on purpose.
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionTile(
    IconData icon,
    String label,
    bool active,
    Color color,
    VoidCallback onTap,
  ) {
    final c = active ? AppColors.green : color;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: active ? AppColors.greenLight : c.withOpacity(.03),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_boxRadius),
          side: BorderSide(color: c.withOpacity(.55)),
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _actionTileHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  active ? Icons.check_circle_outline : icon,
                  size: 24,
                  color: c,
                ),
                _hGap(0.02),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Map-style placeholder (roads, parks, water) standing in for a map tile.
class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEDEFF2),
    );

    final green = Paint()..color = const Color(0xFFCDEBB0);
    final water = Paint()..color = const Color(0xFFA9DAFF);
    for (final r in [
      Rect.fromLTWH(0, 0, w * .12, h * .35),
      Rect.fromLTWH(w * .30, h * .18, w * .10, h * .22),
      Rect.fromLTWH(w * .58, h * .10, w * .14, h * .20),
      Rect.fromLTWH(w * .88, 0, w * .12, h * .30),
      Rect.fromLTWH(w * .05, h * .55, w * .14, h * .30),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(4)),
        green,
      );
    }
    canvas.drawOval(Rect.fromLTWH(w * .17, h * .05, w * .09, h * .2), water);
    canvas.drawOval(Rect.fromLTWH(w * .88, h * .30, w * .16, h * .55), water);

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    for (double x = -h; x < w; x += 70) {
      canvas.drawLine(Offset(x, h), Offset(x + h, 0), road);
    }
    for (double y = 10; y < h; y += 55) {
      canvas.drawLine(Offset(0, y + 20), Offset(w, y - 20), road);
    }
    canvas.drawLine(
      Offset(w * .78, 0),
      Offset(w * .70, h),
      Paint()
        ..color = const Color(0xFFF7D154)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
