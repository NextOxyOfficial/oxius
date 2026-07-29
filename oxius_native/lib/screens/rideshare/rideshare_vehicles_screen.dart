import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/rideshare_models.dart';
import '../../services/auth_service.dart';
import '../../services/rideshare_service.dart';
import '../../services/translation_service.dart';
import 'rideshare_page_header.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

part 'rideshare_vehicles_form.dart';
part 'rideshare_vehicles_list.dart';

// Design tokens — top-level so the part files can use them unqualified.
const Color _primary = Color(0xFF6366F1);
const Color _secondary = Color(0xFF8B5CF6);
const Color _surfaceSoft = Color(0xFFF1F5F9);
const Color _card = Colors.white;
const Color _textPrimary = Color(0xFF1E293B);
const Color _textSecondary = Color(0xFF64748B);
const Color _textMuted = Color(0xFF94A3B8);
const Color _line = Color(0xFFE2E8F0);
const Color _success = Color(0xFF10B981);
const Color _danger = Color(0xFFEF4444);
const Color _dangerSoft = Color(0xFFFEF2F2);
const Color _warning = Color(0xFFF59E0B);
const Color _warningSoft = Color(0xFFFFFBEB);

class RideshareVehiclesScreen extends StatefulWidget {
  const RideshareVehiclesScreen({super.key});

  @override
  State<RideshareVehiclesScreen> createState() =>
      _RideshareVehiclesScreenState();
}

class _RideshareVehiclesScreenState extends State<RideshareVehiclesScreen> {


  final TranslationService _ts = TranslationService();
  String t(String key, {required String fallback}) =>
      _ts.t(key, fallback: fallback);

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isKYCPending = false;
  bool _needsDriverApproval = false;
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

  bool _isNotFoundMessage(String? message) {
    final normalized = message?.toLowerCase() ?? '';
    return normalized.contains('not found') ||
        normalized.contains('resource not found') ||
        normalized.contains('404');
  }

  Future<void> _loadVehicles() async {
    if (!AuthService.isAuthenticated) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please log in to manage your vehicles.';
        _isKYCPending = false;
        _needsDriverApproval = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isKYCPending = false;
      _needsDriverApproval = false;
    });

    final profileResult = await RideshareService.getDriverProfile();
    if (!mounted) return;

    RideshareApiResult<List<Vehicle>>? vehicleResult;
    final driverProfile = profileResult.data;
    final profileIsMissing = driverProfile == null &&
        (!profileResult.success || _isNotFoundMessage(profileResult.message));

    if (driverProfile?.isApproved == true) {
      vehicleResult = await RideshareService.listVehicles();
      if (!mounted) return;
    }

    setState(() {
      _isLoading = false;
      _driverProfile = driverProfile;

      if (driverProfile != null && driverProfile.isPending) {
        _isKYCPending = true;
        _needsDriverApproval = false;
        _errorMessage = null;
        _vehicles = const [];
      } else if ((driverProfile != null && !driverProfile.isApproved) ||
          profileIsMissing) {
        _isKYCPending = false;
        _needsDriverApproval = true;
        _errorMessage = null;
        _vehicles = const [];
      } else if (vehicleResult?.success == true) {
        _isKYCPending = false;
        _needsDriverApproval = false;
        _vehicles = vehicleResult?.data ?? const [];
      } else {
        _isKYCPending = false;
        _needsDriverApproval = false;
        _errorMessage = vehicleResult?.message ?? profileResult.message;
      }
    });
  }

  void _handleAddVehicle() {
    if (_driverProfile == null || !_driverProfile!.isApproved) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            t('rideshare_kyc_required', fallback: 'KYC অনুমোদন লাগবে'),
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary),
          ),
          content: Text(
            t('rideshare_kyc_required_desc',
                fallback:
                    'Your KYC must be approved before you can add a vehicle. Please complete your driver registration and wait for admin approval.'),
            style: GoogleFonts.inter(
                fontSize: 13, color: _textSecondary, height: 1.5),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(t('ok', fallback: 'ঠিক আছে'),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
    if (isError) {
      AdsyToast.error(context, message);
    } else {
      AdsyToast.success(context, message);
    }
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          t('rideshare_contact_support', fallback: 'সাপোর্টে যোগাযোগ করুন'),
          style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary),
        ),
        content: Text(
          t('rideshare_vehicle_edit_note',
              fallback:
                  'Vehicle information cannot be edited directly. Please contact our support center to make changes to your vehicle details.'),
          style: GoogleFonts.inter(
              fontSize: 13, color: _textSecondary, height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('OK',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
                t('rideshare_delete_confirm', fallback: 'গাড়িটি মুছে ফেলবেন?'),
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
                    t('cancel', fallback: 'বাতিল'),
                    style: const TextStyle(
                        color: _textSecondary, fontWeight: FontWeight.w600),
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
                  child:
                      Text(t('rideshare_delete_vehicle', fallback: 'মুছে ফেলুন')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            RidesharePageHeader(
              title: t('rideshare_my_vehicles', fallback: 'আমার গাড়ি'),
              subtitle: _vehicles.isEmpty
                  ? null
                  : '${_vehicles.length}টি রেজিস্টার্ড',
              action: IconButton(
                onPressed: _loadVehicles,
                icon: const Icon(Icons.refresh_rounded,
                    size: 20, color: Color(0xFF64748B)),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 0,
        backgroundColor: _driverProfile?.isApproved == true
            ? const Color(0xFF0F172A)
            : _textMuted,
        foregroundColor: Colors.white,
        onPressed: _isSubmitting ? null : () => _handleAddVehicle(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          t('rideshare_add_vehicle', fallback: 'গাড়ি যোগ করুন'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}
