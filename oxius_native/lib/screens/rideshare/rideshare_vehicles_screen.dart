import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/rideshare_models.dart';
import '../../services/auth_service.dart';
import '../../services/rideshare_service.dart';

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

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<Vehicle> _vehicles = const [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
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

    final result = await RideshareService.listVehicles();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _vehicles = result.data ?? const [];
      } else {
        _errorMessage = result.message;
      }
    });
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
                'Delete vehicle?',
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
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600),
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
                  child: const Text('Delete'),
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

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
              child: Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
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
                            'Keep your vehicle details accurate so ride assignment stays smooth.',
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
                            items: const [
                              DropdownMenuItem(value: 'bike', child: Text('Bike')),
                              DropdownMenuItem(value: 'car', child: Text('Car')),
                              DropdownMenuItem(value: 'cng', child: Text('CNG')),
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
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(Colors.white),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
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
    );
  }

  Widget _buildOverview() {
    final defaultVehicle = _vehicles.cast<Vehicle?>().firstWhere(
          (vehicle) => vehicle?.isDefault == true,
          orElse: () => null,
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.18),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.garage_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Vehicle Garage',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Passenger page-er moto compact card layout-e vehicle manage করুন।',
                      style: GoogleFonts.inter(
                        color: Color(0xFFD6E2FF),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                label: 'Total listed',
                value: '${_vehicles.length}',
                icon: Icons.local_taxi_rounded,
                accent: _primary,
                tint: Colors.white.withOpacity(0.18),
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                label: 'Active now',
                value: '${_vehicles.where((vehicle) => vehicle.isActive).length}',
                icon: Icons.check_circle_rounded,
                accent: _success,
                tint: const Color(0x3322C55E),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    defaultVehicle == null
                        ? 'Set one vehicle as default for faster assignment.'
                        : 'Default vehicle: ${defaultVehicle.displayName}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
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
                      'Default',
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
                    foregroundColor: _textPrimary,
                    side: const BorderSide(color: _line),
                    backgroundColor: _surfaceSoft,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : () => _showVehicleForm(vehicle: vehicle),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(
                    'Edit',
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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
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
                    'Unable to load vehicles',
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
                    child: Text('Try again', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            )
          else ...[
          _buildOverview(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your vehicles',
                      style: GoogleFonts.inter(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage which vehicles are active and ready for rides.',
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
                      'Keep one default',
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
          const SizedBox(height: 10),
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
                    'No vehicles added yet',
                    style: GoogleFonts.inter(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add your bike, car, or CNG to start receiving rides with the right vehicle type.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: _textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showVehicleForm(),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      'Add your first vehicle',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
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
              'My Vehicles',
              style: GoogleFonts.inter(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'Compact garage management',
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
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        onPressed: _isSubmitting ? null : () => _showVehicleForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Vehicle',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}
