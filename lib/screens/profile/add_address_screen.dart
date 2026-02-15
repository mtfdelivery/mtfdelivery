import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/address_model.dart';
import 'address_controller.dart';

class AddNewAddressScreen extends ConsumerStatefulWidget {
  const AddNewAddressScreen({super.key});

  @override
  ConsumerState<AddNewAddressScreen> createState() =>
      _AddNewAddressScreenState();
}

class _AddNewAddressScreenState extends ConsumerState<AddNewAddressScreen>
    with TickerProviderStateMixin {
  // ── Map ──
  GoogleMapController? _mapController;
  LatLng _currentCenter = const LatLng(33.8731, 7.8628); // Default: Nefta area
  String _deliveryAddress = '';
  bool _isLoadingAddress = true;
  bool _isMapMoving = false;

  // ── Pin animation ──
  late AnimationController _pinAnimController;
  late Animation<double> _pinBounceAnim;

  // ── Label ──
  int _selectedLabelIndex = 0; // 0=Maison, 1=Bureau, 2=Autre
  final TextEditingController _customLabelController = TextEditingController();

  // ── Form ──
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetNumberController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();

  // ── Coordinates ──
  double? _latitude;
  double? _longitude;
  final String _plusCode = '';

  @override
  void initState() {
    super.initState();
    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pinBounceAnim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _pinAnimController, curve: Curves.easeOut),
    );

    // Default name
    _nameController.text = 'User Account';

    // Default phone
    _phoneController.text = '';

    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pinAnimController.dispose();
    _mapController?.dispose();
    _customLabelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _streetNumberController.dispose();
    _houseController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  // ── Validation ──
  bool get _isFormValid {
    final hasAddress = _deliveryAddress.isNotEmpty;
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasPhone = _phoneController.text.trim().isNotEmpty;
    final hasLabel =
        _selectedLabelIndex != 2 ||
        _customLabelController.text.trim().isNotEmpty;
    return hasAddress && hasName && hasPhone && hasLabel;
  }

  String get _selectedLabel {
    switch (_selectedLabelIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Work';
      case 2:
        return _customLabelController.text.trim().isNotEmpty
            ? _customLabelController.text.trim()
            : 'Other';
      default:
        return 'Home';
    }
  }

  // ── Location ──
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingAddress = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingAddress = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newCenter = LatLng(position.latitude, position.longitude);
      setState(() => _currentCenter = newCenter);

      _mapController?.animateCamera(CameraUpdate.newLatLng(newCenter));
      await _reverseGeocode(newCenter);
    } catch (e) {
      if (mounted) {
        setState(() {
          _deliveryAddress = 'Unable to detect location';
          _isLoadingAddress = false;
        });
      }
    }
  }

  Future<void> _reverseGeocode(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final parts = <String>[
          if (place.street != null && place.street!.isNotEmpty) place.street!,
          if (place.subLocality != null && place.subLocality!.isNotEmpty)
            place.subLocality!,
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality!,
          if (place.country != null && place.country!.isNotEmpty)
            place.country!,
        ];
        setState(() {
          _deliveryAddress = parts.join(', ');
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _deliveryAddress = 'Address not found';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deliveryAddress = 'Address not found';
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isLoadingAddress = false;
        });
      }
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentCenter = position.target;
    if (!_isMapMoving) {
      setState(() => _isMapMoving = true);
      _pinAnimController.forward();
    }
  }

  void _onCameraIdle() {
    if (_isMapMoving) {
      _pinAnimController.reverse();
      setState(() => _isMapMoving = false);
    }
    _reverseGeocode(_currentCenter);
  }

  void _saveAddress() {
    if (!_isFormValid) return;

    final newAddress = AddressModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: _selectedLabel,
      address: _deliveryAddress,
      name: _nameController.text.trim(),
      phone: '+216 ${_phoneController.text.trim()}',
      latitude: _latitude,
      longitude: _longitude,
      plusCode: _plusCode,
      streetNumber: _streetNumberController.text.trim(),
      house: _houseController.text.trim(),
      floor: _floorController.text.trim(),
    );

    ref.read(addressControllerProvider.notifier).addAddress(newAddress);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20.sp,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ajouter une nouvelle adresse',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Map Header ──
                  _buildMapSection(isDark),

                  // ── Form Body ──
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20.h),

                        // ── Label Chips ──
                        _buildLabelSection(isDark),

                        // ── Custom Label (if Autre) ──
                        if (_selectedLabelIndex == 2) ...[
                          SizedBox(height: 14.h),
                          _buildTextField(
                            controller: _customLabelController,
                            label: "Nom de l'étiquette",
                            icon: Iconsax.tag,
                            isDark: isDark,
                          ),
                        ],

                        SizedBox(height: 20.h),

                        // ── Adresse de livraison ──
                        _buildAddressField(isDark),

                        SizedBox(height: 16.h),

                        // ── Nom ──
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nom',
                          icon: Iconsax.user,
                          isRequired: true,
                          isDark: isDark,
                        ),

                        SizedBox(height: 16.h),

                        // ── Téléphone ──
                        _buildPhoneField(isDark),

                        SizedBox(height: 16.h),

                        // ── Numéro de la rue ──
                        _buildTextField(
                          controller: _streetNumberController,
                          label: 'Numéro de la rue',
                          icon: Iconsax.signpost,
                          isDark: isDark,
                        ),

                        SizedBox(height: 16.h),

                        // ── Maison & Etage ──
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _houseController,
                                label: 'Maison',
                                icon: Iconsax.home_2,
                                isDark: isDark,
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: _buildTextField(
                                controller: _floorController,
                                label: 'Etage',
                                icon: Iconsax.building,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 30.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Save Button ──
          _buildSaveButton(isDark),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  MAP SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildMapSection(bool isDark) {
    return SizedBox(
      height: 220.h,
      child: Stack(
        children: [
          // Google Map
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20.r),
              bottomRight: Radius.circular(20.r),
            ),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentCenter,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(_currentCenter),
                );
              },
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              style: isDark ? _darkMapStyle : null,
            ),
          ),

          // Center Pin
          Center(
            child: AnimatedBuilder(
              animation: _pinBounceAnim,
              builder: (context, child) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: 40.h + (-_pinBounceAnim.value),
                  ),
                  child: child,
                );
              },
              child: _buildMapPin(),
            ),
          ),

          // Search overlay
          Positioned(
            top: 10.h,
            left: 12.w,
            child: GestureDetector(
              onTap: () {
                // Could open a place search in the future
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1E1E2E) : Colors.white)
                      .withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.search_normal_1,
                      size: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Rechercher',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expand / fullscreen button
          Positioned(
            top: 10.h,
            right: 12.w,
            child: GestureDetector(
              onTap: () async {
                final result = await context.push<String>('/map-picker');
                if (result != null && mounted) {
                  setState(() => _deliveryAddress = result);
                }
              },
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1E1E2E) : Colors.white)
                      .withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Iconsax.maximize_4,
                  size: 18.sp,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // My location FAB
          Positioned(
            bottom: 12.h,
            right: 12.w,
            child: GestureDetector(
              onTap: _getCurrentLocation,
              child: Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Iconsax.gps, color: AppColors.primary, size: 18.sp),
              ),
            ),
          ),

          // Hint text below map
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E1E2E) : Colors.white)
                    .withValues(alpha: 0.85),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.r),
                  bottomRight: Radius.circular(20.r),
                ),
              ),
              child: Text(
                'Ajouter correctement l\'adresse',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'CHOISIR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        CustomPaint(
          size: Size(14.w, 8.h),
          painter: _PinNeedlePainter(color: AppColors.primary),
        ),
        Container(
          width: 8.r,
          height: 3.r,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  LABEL SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildLabelSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Étiquette comme',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            _buildLabelChip(index: 0, icon: Iconsax.home_15, isDark: isDark),
            SizedBox(width: 12.w),
            _buildLabelChip(index: 1, icon: Icons.work_rounded, isDark: isDark),
            SizedBox(width: 12.w),
            _buildLabelChip(
              index: 2,
              icon: Icons.grid_view_rounded,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabelChip({
    required int index,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedLabelIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedLabelIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 56.r,
        height: 56.r,
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primary
                    : isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: 24.sp,
          color:
              isSelected
                  ? AppColors.primary
                  : isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppColors.textTertiary,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  FORM FIELDS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAddressField(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color:
              _deliveryAddress.isNotEmpty
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Adresse de livraison',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              Text(' *', style: TextStyle(fontSize: 11.sp, color: Colors.red)),
            ],
          ),
          SizedBox(height: 6.h),
          _isLoadingAddress
              ? Row(
                children: [
                  SizedBox(
                    width: 14.r,
                    height: 14.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Recherche d\'adresse...',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
              : Text(
                _deliveryAddress.isNotEmpty
                    ? _deliveryAddress
                    : 'Déplacez la carte pour sélectionner',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color:
                      _deliveryAddress.isNotEmpty
                          ? Theme.of(context).colorScheme.onSurface
                          : AppColors.textTertiary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        ],
      ),
    );
  }

  Widget _buildPhoneField(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color:
              isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Tunisia flag + prefix
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🇹🇳', style: TextStyle(fontSize: 18.sp)),
                SizedBox(width: 6.w),
                Text(
                  '+216',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 28.h,
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : AppColors.border,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Numéro de téléphone',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textTertiary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Téléphone',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      ' *',
                      style: TextStyle(fontSize: 13.sp, color: Colors.red),
                    ),
                  ],
                ),
              ),
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 14.sp)),
            if (isRequired)
              Text(' *', style: TextStyle(fontSize: 14.sp, color: Colors.red)),
          ],
        ),
        floatingLabelStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 13.sp,
        ),
        hintStyle: TextStyle(fontSize: 14.sp, color: AppColors.textTertiary),
        filled: true,
        fillColor:
            isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color:
                isDark
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color:
                isDark
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
      style: TextStyle(
        fontSize: 14.sp,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SAVE BUTTON
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSaveButton(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54.h,
        child: ElevatedButton(
          onPressed: _isFormValid ? _saveAddress : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            disabledForegroundColor: Colors.white70,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: Text(
            'Sauvegarder l\'emplacement',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Custom Pin Needle Painter ──
class _PinNeedlePainter extends CustomPainter {
  final Color color;
  _PinNeedlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Dark Map Style ──
const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#212121"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#757575"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#181818"}]},
  {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2c2c2c"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#8a8a8a"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#373737"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3c3c3c"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#2f3948"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]}
]
''';
