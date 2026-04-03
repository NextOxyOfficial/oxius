import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/rideshare_models.dart';
import '../../services/auth_service.dart';
import '../../services/rideshare_service.dart';
import '../../services/translation_service.dart';

class RideshareVehiclesScreen extends StatefulWidget {
  const RideshareVehiclesScreen({super.key});

  @override
  State<RideshareVehiclesScreen> createState() => _RideshareVehiclesScreenState();
}

class _RideshareVehiclesScreenState extends State<RideshareVehiclesScreen> {
  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4F46E5);
  static const Color _secondary = Color(0xFF8B5CF6);
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _surfaceSoft = Color(0xFFF1F5F9);
  static const Color _card = Colors.white;
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _textMuted = Color(0xFF94A3B8);
  static const Color _line = Color(0xFFE2E8F0);
  static const Color _success = Color(0xFF10B981);
  static const Color _successSoft = Color(0xFFECFDF5);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _dangerSoft = Color(0xFFFEF2F2);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _warningSoft = Color(0xFFFFFBEB);

  final TranslationService _ts = TranslationService();
  String t(String key, {required String fallback}) => _ts.t(key, fallback: fallback);

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<Vehicle> _vehicles = const [];
  DriverProfile? _driverProfile;

  @override
  void initState() {
    super.initState();
    _ts.addListener(_onTranslationsChanged);
    _loadVehicles();
  }

  @override
  void dispose() {
    _ts.removeListener(_onTranslationsChanged);
    super.dispose();
  }

  void _onTranslationsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadVehicles() async {
    if (!AuthService.isAuthenticated) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please log in to manage your vehicles.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final vehicleFuture = RideshareService.listVehicles();
    final profileFuture = RideshareService.getDriverProfile();
    final vehicleResult = await vehicleFuture;
    final profileResult = await profileFuture;
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _driverProfile = profileResult.data;
      if (vehicleResult.success) {
        _vehicles = vehicleResult.data ?? const [];
      } else {
        _errorMessage = vehicleResult.message;
      }
    });
  }

  void _handleAddVehicle() {
    if (_driverProfile == null || !_driverProfile!.isApproved) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            t('rideshare_kyc_required', fallback: 'KYC Approval Required'),
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary),
          ),
          content: Text(
            t('rideshare_kyc_required_desc', fallback: 'Your KYC must be approved before you can add a vehicle. Please complete your driver registration and wait for admin approval.'),
            style: GoogleFonts.inter(fontSize: 13, color: _textSecondary, height: 1.5),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(t('ok', fallback: 'OK'), style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      return;
    }
    _showVehicleForm();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? _danger : _success,
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          t('rideshare_contact_support', fallback: 'Contact Support'),
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary),
        ),
        content: Text(
          t('rideshare_vehicle_edit_note', fallback: 'Vehicle information cannot be edited directly. Please contact our support center to make changes to your vehicle details.'),
          style: GoogleFonts.inter(fontSize: 13, color: _textSecondary, height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('OK', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _setDefaultVehicle(Vehicle vehicle) async {
    setState(() => _isSubmitting = true);
    final result = await RideshareService.updateVehicle(
      vehicle.id,
      isDefault: true,
    );
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (result.success) {
      _showMessage('Default vehicle updated.');
      await _loadVehicles();
      return;
    }

    _showMessage(result.message, isError: true);
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: _card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                t('rideshare_delete_confirm', fallback: 'Delete vehicle?'),
                style: GoogleFonts.inter(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                'This will remove ${vehicle.displayName} from your driver profile.',
                style: GoogleFonts.inter(
                  color: _textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    t('cancel', fallback: 'Cancel'),
                    style: const TextStyle(color: _textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(t('rideshare_delete_vehicle', fallback: 'Delete')),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) return;

    setState(() => _isSubmitting = true);
    final result = await RideshareService.deleteVehicle(vehicle.id);
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (result.success) {
      _showMessage('Vehicle deleted successfully.');
      await _loadVehicles();
      return;
    }

    _showMessage(result.message, isError: true);
  }

  Future<void> _showVehicleForm({Vehicle? vehicle}) async {
    final formKey = GlobalKey<FormState>();
    final brandController = TextEditingController(text: vehicle?.brand ?? '');
    final modelController = TextEditingController(text: vehicle?.modelName ?? '');
    final colorController = TextEditingController(text: vehicle?.color ?? '');
    final regController = TextEditingController(
      text: vehicle?.registrationNumber ?? '',
    );
    final seatController = TextEditingController(
      text: (vehicle?.seatCapacity ?? 1).toString(),
    );

    String selectedType = vehicle?.vehicleType ?? 'bike';
    bool isActive = vehicle?.isActive ?? true;
    bool isDefault = vehicle?.isDefault ?? _vehicles.isEmpty;
    bool isSaving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              if (isSaving || !(formKey.currentState?.validate() ?? false)) {
                return;
              }

              setSheetState(() => isSaving = true);
              final seatCapacity = int.tryParse(seatController.text.trim()) ?? 1;

              final result = vehicle == null
                  ? await RideshareService.createVehicle(
                      vehicleType: selectedType,
                      registrationNumber: regController.text.trim(),
                      brand: brandController.text.trim(),
                      modelName: modelController.text.trim(),
                      color: colorController.text.trim(),
                      seatCapacity: seatCapacity,
                      isDefault: isDefault,
                    )
                  : await RideshareService.updateVehicle(
                      vehicle.id,
                      vehicleType: selectedType,
                      registrationNumber: regController.text.trim(),
                      brand: brandController.text.trim(),
                      modelName: modelController.text.trim(),
                      color: colorController.text.trim(),
                      seatCapacity: seatCapacity,
                      isActive: isActive,
                      isDefault: isDefault,
                    );

              if (!mounted) return;

              setSheetState(() => isSaving = false);
              if (result.success) {
                Navigator.of(context).pop(true);
              } else {
                _showMessage(result.message, isError: true);
              }
            }

            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: vehicle == null ? 0.82 : 0.88,
              minChildSize: 0.52,
              maxChildSize: 0.94,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(top: 16, bottom: bottomInset),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Container(
                                  width: 42,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: _line,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                vehicle == null ? 'Add vehicle' : 'Edit vehicle',
                                style: GoogleFonts.inter(
                                  color: _textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t('rideshare_vehicle_accuracy_note', fallback: 'Keep your vehicle details accurate so ride assignment stays smooth.'),
                                style: GoogleFonts.inter(
                                  color: _textSecondary,
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildSectionLabel('Vehicle type'),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: selectedType,
                                decoration: _inputDecoration(),
                                style: GoogleFonts.inter(
                                  color: _textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                items: [
                                  DropdownMenuItem(value: 'bike', child: Text(t('rideshare_vehicle_bike', fallback: 'Bike'))),
                                  DropdownMenuItem(value: 'car', child: Text(t('rideshare_vehicle_car', fallback: 'Car'))),
                                  DropdownMenuItem(value: 'cng', child: Text(t('rideshare_vehicle_cng', fallback: 'CNG'))),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setSheetState(() => selectedType = value);
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildSectionLabel('Brand'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: brandController,
                                decoration: _inputDecoration(hint: 'Honda, Toyota, Bajaj'),
                                style: GoogleFonts.inter(fontSize: 13, color: _textPrimary),
                              ),
                              const SizedBox(height: 12),
                              _buildSectionLabel('Model'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: modelController,
                                decoration: _inputDecoration(hint: 'Civic, Discover, Auto'),
                                style: GoogleFonts.inter(fontSize: 13, color: _textPrimary),
                              ),
                              const SizedBox(height: 12),
                              _buildSectionLabel('Color'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: colorController,
                                decoration: _inputDecoration(hint: 'Red, Black, Silver'),
                                style: GoogleFonts.inter(fontSize: 13, color: _textPrimary),
                              ),
                              const SizedBox(height: 12),
                              _buildSectionLabel('Registration number'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: regController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: _inputDecoration(hint: 'DHAKA METRO-GA-12-3456'),
                                style: GoogleFonts.inter(fontSize: 13, color: _textPrimary),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Registration number is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildSectionLabel('Seat capacity'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: seatController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(hint: '1'),
                                style: GoogleFonts.inter(fontSize: 13, color: _textPrimary),
                                validator: (value) {
                                  final seats = int.tryParse(value?.trim() ?? '');
                                  if (seats == null || seats < 1) {
                                    return 'Enter a valid seat count';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildToggleTile(
                                title: 'Set as default vehicle',
                                subtitle: 'This vehicle will be used first for ride matching.',
                                value: isDefault,
                                onChanged: (value) {
                                  setSheetState(() => isDefault = value);
                                },
                              ),
                              if (vehicle != null) ...[
                                const SizedBox(height: 10),
                                _buildToggleTile(
                                  title: 'Vehicle active',
                                  subtitle: 'Inactive vehicles will stay hidden from dispatch.',
                                  value: isActive,
                                  onChanged: (value) {
                                    setSheetState(() => isActive = value);
                                  },
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: isSaving ? null : submit,
                                  child: isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          vehicle == null ? 'Save vehicle' : 'Update vehicle',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    brandController.dispose();
    modelController.dispose();
    colorController.dispose();
    regController.dispose();
    seatController.dispose();

    if (saved == true) {
      _showMessage(vehicle == null ? 'Vehicle added successfully.' : 'Vehicle updated successfully.');
      await _loadVehicles();
    }
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: _textMuted, fontSize: 13),
      filled: true,
      fillColor: _surfaceSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _danger, width: 1.4),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: _textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: _textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: value,
            activeColor: _primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  IconData _vehicleIcon(String type) {
    switch (type) {
      case 'bike':
        return Icons.two_wheeler_rounded;
      case 'car':
        return Icons.directions_car_filled_rounded;
      case 'cng':
        return Icons.electric_rickshaw_rounded;
      default:
        return Icons.directions_car_filled_rounded;
    }
  }

  String _vehicleTypeLabel(String type) {
    switch (type) {
      case 'bike':
        return 'Bike';
      case 'car':
        return 'Car';
      case 'cng':
        return 'CNG';
      default:
        return type;
    }
  }

  Color _vehicleColorValue(String colorName) {
    switch (colorName.trim().toLowerCase()) {
      case 'black':
        return const Color(0xFF111827);
      case 'white':
        return const Color(0xFFF8FAFC);
      case 'gray':
      case 'grey':
      case 'silver':
        return const Color(0xFF94A3B8);
      case 'red':
        return const Color(0xFFEF4444);
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'green':
        return const Color(0xFF10B981);
      case 'yellow':
        return const Color(0xFFF59E0B);
      case 'orange':
        return const Color(0xFFF97316);
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'brown':
        return const Color(0xFF92400E);
      default:
        return _textMuted;
    }
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
    required Color tint,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: accent, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFD6D9FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    final defaultVehicle = _vehicles.cast<Vehicle?>().firstWhere(
          (vehicle) => vehicle?.isDefault == true,
          orElse: () => null,
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.garage_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('rideshare_my_vehicles', fallback: 'My Vehicle Garage'),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      t('rideshare_my_vehicles_desc', fallback: 'Manage your listed and active vehicles from one compact garage dashboard.'),
                      style: GoogleFonts.inter(
                        color: const Color(0xFFD6E2FF),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatCard(
                label: 'Total listed',
                value: '${_vehicles.length}',
                icon: Icons.local_taxi_rounded,
                accent: _primary,
                tint: Colors.white.withValues(alpha: 0.18),
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                label: 'Active now',
                value: '${_vehicles.where((vehicle) => vehicle.isActive).length}',
                icon: Icons.check_circle_rounded,
                accent: _success,
                tint: const Color(0x3322C55E),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    defaultVehicle == null
                        ? 'Set one vehicle as default for faster assignment.'
                        : 'Default vehicle: ${defaultVehicle.displayName}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    final isDefault = vehicle.isDefault;
    final isActive = vehicle.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDefault ? _primary.withOpacity(0.18) : _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDefault
                    ? const [Color(0xFF6366F1), Color(0xFF8B5CF6)]
                    : const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDefault ? Colors.white.withOpacity(0.16) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _vehicleIcon(vehicle.vehicleType),
                    color: isDefault ? Colors.white : _primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.displayName,
                        style: GoogleFonts.inter(
                          color: isDefault ? Colors.white : _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.registrationNumber,
                        style: GoogleFonts.inter(
                          color: isDefault ? const Color(0xFFE8E7FF) : _textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      t('rideshare_set_default', fallback: 'Default'),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _buildMetaText(
                icon: _vehicleIcon(vehicle.vehicleType),
                label: _vehicleTypeLabel(vehicle.vehicleType),
              ),
              _buildMetaText(
                icon: Icons.event_seat_rounded,
                label: '${vehicle.seatCapacity} seats',
              ),
              if (vehicle.color.trim().isNotEmpty)
                _buildMetaText(
                  icon: Icons.circle,
                  label: vehicle.color.trim(),
                  iconColor: _vehicleColorValue(vehicle.color),
                ),
              _buildMetaText(
                icon: isActive ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                label: isActive ? 'Active' : 'Inactive',
                iconColor: isActive ? _success : _danger,
                textColor: isActive ? _success : _danger,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textSecondary,
                    side: const BorderSide(color: _line),
                    backgroundColor: _surfaceSoft,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showContactSupportDialog(),
                  icon: const Icon(Icons.support_agent_rounded, size: 18),
                  label: Text(
                    t('rideshare_edit_via_support', fallback: 'Edit via Support'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isDefault ? _surfaceSoft : _primary,
                    foregroundColor: isDefault ? _textSecondary : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSubmitting || isDefault
                      ? null
                      : () => _setDefaultVehicle(vehicle),
                  icon: Icon(
                    isDefault ? Icons.verified_rounded : Icons.stars_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isDefault ? 'Selected' : 'Set Default',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isSubmitting ? null : () => _deleteVehicle(vehicle),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _dangerSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: _danger),
                ),
              ),
            ],
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaText({
    required IconData icon,
    required String label,
    Color? iconColor,
    Color? textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor ?? _primary),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            color: textColor ?? _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primary),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadVehicles,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 96),
        children: [
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _dangerSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: _danger,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t('rideshare_load_error', fallback: 'Unable to load vehicles'),
                    style: GoogleFonts.inter(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: _textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _loadVehicles,
                    child: Text(t('try_again', fallback: 'Try again'), style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            )
          else ...[
          _buildOverview(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('rideshare_your_vehicles', fallback: 'Your vehicles'),
                      style: GoogleFonts.inter(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t('rideshare_vehicles_manage_desc', fallback: 'Manage which vehicles are active and ready for rides.'),
                      style: GoogleFonts.inter(
                        color: _textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _warningSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tips_and_updates_outlined, color: _warning, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      t('rideshare_keep_one_default', fallback: 'Keep one default'),
                      style: GoogleFonts.inter(
                        color: _warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_vehicles.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primary, _secondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t('rideshare_no_vehicles', fallback: 'No vehicles added yet'),
                    style: GoogleFonts.inter(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t('rideshare_no_vehicles_desc', fallback: 'Add your bike, car, or CNG to start receiving rides with the right vehicle type.'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: _textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._vehicles.map(_buildVehicleCard),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('rideshare_my_vehicles', fallback: 'My Vehicles'),
              style: GoogleFonts.inter(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              t('rideshare_garage_subtitle', fallback: 'Compact garage management'),
              style: GoogleFonts.inter(
                color: _textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFEFF2FF),
                foregroundColor: _primary,
              ),
              onPressed: _loadVehicles,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 0,
        backgroundColor: _driverProfile?.isApproved == true ? _primary : _textMuted,
        foregroundColor: Colors.white,
        onPressed: _isSubmitting ? null : () => _handleAddVehicle(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          t('rideshare_add_vehicle', fallback: 'Add Vehicle'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}
