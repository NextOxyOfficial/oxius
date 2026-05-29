import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/rideshare_models.dart';
import '../../services/auth_service.dart';
import '../../services/rideshare_service.dart';
import '../../utils/payment_policy.dart';
import '../../widgets/ios_payment_blocked_widget.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

const double customLocationFee = 199.0;

/// Parse a coordinate string that may be decimal ("23.905722") or
/// DMS ("23°54'20.5" / "23°54'20.5\"" / "23 54 20.5").
double? parseCoordinate(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final plain = double.tryParse(text);
  if (plain != null) return plain;

  final dmsPattern = RegExp(
    r"""^(-?\d+(?:\.\d+)?)\s*[°\s]\s*(\d+(?:\.\d+)?)\s*['\'\s]\s*(\d+(?:\.\d+)?)\s*[\"\"\s]?\s*""",
  );
  final m = dmsPattern.firstMatch(text);
  if (m != null) {
    final d = double.tryParse(m.group(1)!) ?? 0;
    final min = double.tryParse(m.group(2)!) ?? 0;
    final sec = double.tryParse(m.group(3)!) ?? 0;
    final sign = d < 0 ? -1.0 : 1.0;
    return sign * (d.abs() + min / 60.0 + sec / 3600.0);
  }

  return null;
}

/// Result returned when user selects or creates a location from the sheet.
class CustomLocationSheetResult {
  final RidePoint point;
  final String? successMessage;

  const CustomLocationSheetResult({required this.point, this.successMessage});
}

/// Shows the custom-location bottom sheet with two tabs:
///   Tab 0 – আমার লোকেশন (My Locations)
///   Tab 1 – নতুন অ্যাড (Add New)
///
/// Returns a [CustomLocationSheetResult] when the user selects or creates a
/// location, or `null` if the sheet was dismissed.
Future<CustomLocationSheetResult?> showCustomLocationSheet(
    BuildContext context) {
  return showModalBottomSheet<CustomLocationSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _CustomLocationSheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet widget (stateful)
// ─────────────────────────────────────────────────────────────────────────────

class _CustomLocationSheet extends StatefulWidget {
  const _CustomLocationSheet();

  @override
  State<_CustomLocationSheet> createState() => _CustomLocationSheetState();
}

class _CustomLocationSheetState extends State<_CustomLocationSheet> {
  // ── Add-tab controllers ───
  final _nameCtl = TextEditingController();
  final _subtitleCtl = TextEditingController();
  final _keywordsCtl = TextEditingController();
  final _latCtl = TextEditingController();
  final _lonCtl = TextEditingController();
  bool _isSubmitting = false;
  bool _isResolvingGps = false;

  // ── Tab state ──
  int _activeTab = 0; // 0 = My Locations, 1 = Add New
  String? _error;

  // ── My-Locations state ──
  List<CustomRideLocation> _myLocations = [];
  bool _isLoadingLocations = true;
  String? _editingId;
  final _editNameCtl = TextEditingController();
  final _editSubtitleCtl = TextEditingController();
  final _editKeywordsCtl = TextEditingController();
  bool _isEditSaving = false;
  String? _deletePendingId;
  bool _deleteSecondConfirm = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadMyLocations();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _subtitleCtl.dispose();
    _keywordsCtl.dispose();
    _latCtl.dispose();
    _lonCtl.dispose();
    _editNameCtl.dispose();
    _editSubtitleCtl.dispose();
    _editKeywordsCtl.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────

  Future<void> _loadMyLocations() async {
    setState(() => _isLoadingLocations = true);
    final result = await RideshareService.getMyLocations();
    if (!mounted) return;
    if (result.success && result.data != null) {
      _myLocations = result.data!;
    }
    setState(() => _isLoadingLocations = false);
  }

  Future<void> _useCurrentGps() async {
    setState(() => _isResolvingGps = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      final result = await RideshareService.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      if (result.success && result.data != null) {
        _latCtl.text = result.data!.latitude.toStringAsFixed(6);
        _lonCtl.text = result.data!.longitude.toStringAsFixed(6);
      } else {
        setState(() => _error = result.message.isEmpty
            ? 'Could not load current location.'
            : result.message);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load current location.');
    } finally {
      if (mounted) setState(() => _isResolvingGps = false);
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  void _startEdit(CustomRideLocation loc) {
    _editNameCtl.text = loc.name;
    _editSubtitleCtl.text = loc.subtitle;
    _editKeywordsCtl.text = loc.searchKeywords;
    setState(() {
      _editingId = loc.id;
      _deletePendingId = null;
      _deleteSecondConfirm = false;
      _error = null;
    });
  }

  Future<void> _saveEdit(String locId) async {
    final name = _editNameCtl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Location name is required.');
      return;
    }
    setState(() {
      _isEditSaving = true;
      _error = null;
    });
    final result = await RideshareService.updateMyLocation(
      id: locId,
      name: name,
      subtitle: _editSubtitleCtl.text.trim(),
      searchKeywords: _editKeywordsCtl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isEditSaving = false);
    if (!result.success) {
      setState(() => _error = result.message);
      return;
    }
    setState(() => _editingId = null);
    _showSnack('Location updated.', isError: false);
    await _loadMyLocations();
  }

  void _onDeleteTap(String locId) {
    if (_deletePendingId == locId && _deleteSecondConfirm) {
      _executeDelete(locId);
    } else if (_deletePendingId == locId) {
      setState(() => _deleteSecondConfirm = true);
    } else {
      setState(() {
        _deletePendingId = locId;
        _deleteSecondConfirm = false;
        _editingId = null;
        _error = null;
      });
    }
  }

  Future<void> _executeDelete(String locId) async {
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    final result = await RideshareService.deleteMyLocation(locId);
    if (!mounted) return;
    setState(() {
      _isDeleting = false;
      _deletePendingId = null;
      _deleteSecondConfirm = false;
    });
    if (!result.success) {
      setState(() => _error = result.message);
      return;
    }
    _showSnack('Location removed.', isError: false);
    await _loadMyLocations();
  }

  void _selectLocation(CustomRideLocation loc) {
    Navigator.of(context)
        .pop(CustomLocationSheetResult(point: loc.asRidePoint));
  }

  Future<void> _submitNewLocation() async {
    // Block the action on iOS — saving a custom location charges a fee.
    if (PaymentPolicy.shouldBlockDigitalPayment()) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content:
              const IOSPaymentBlockedWidget(featureName: 'Custom Location'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final lat = parseCoordinate(_latCtl.text);
    final lon = parseCoordinate(_lonCtl.text);
    final name = _nameCtl.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Location name is required.');
      return;
    }
    if (lat == null || lon == null) {
      setState(() => _error = 'Valid latitude and longitude are required.');
      return;
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    final result = await RideshareService.createCustomLocation(
      name: name,
      subtitle: _subtitleCtl.text.trim(),
      searchKeywords: _keywordsCtl.text.trim(),
      latitude: lat,
      longitude: lon,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success || result.data == null) {
      setState(() => _error = result.message);
      return;
    }

    await AuthService.refreshUserData();
    if (!mounted) return;

    Navigator.of(context).pop(CustomLocationSheetResult(
      point: result.data!.location.asRidePoint,
      successMessage:
          'Location added. ৳${result.data!.feeCharged.toStringAsFixed(0)} charged.',
    ));
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final walletBalance = AuthService.currentUser?.balance ?? 0.0;
    final hasEnoughBalance = walletBalance >= customLocationFee;

    return SafeArea(
      top: false,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ─────────────────────────────────────────
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // ── Tab bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(children: [
                    _tabButton('আমার লোকেশন', Icons.location_on_rounded, 0),
                    const SizedBox(width: 4),
                    _tabButton('নতুন অ্যাড', Icons.add_location_alt_rounded, 1),
                  ]),
                ),
              ),
              const SizedBox(height: 14),

              // ── Error banner ────────────────────────────────────────
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),

              // ── Tab content ─────────────────────────────────────────
              Flexible(
                child: _activeTab == 0
                    ? _buildMyLocationsTab()
                    : _buildAddTab(hasEnoughBalance, walletBalance),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab button ───────────────────────────────────────────────────────────

  Widget _tabButton(String label, IconData icon, int index) {
    final active = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _activeTab = index;
          _error = null;
          if (index == 0) {
            _editingId = null;
            _deletePendingId = null;
            _deleteSecondConfirm = false;
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: active
                      ? const Color(0xFFEA580C)
                      : const Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 0 – My Locations
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMyLocationsTab() {
    if (_isLoadingLocations) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
            child:
                AdsyLoadingIndicator(strokeWidth: 2, color: Color(0xFFEA580C))),
      );
    }

    if (_myLocations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.location_off_rounded,
                  color: Color(0xFFEA580C), size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'আপনি এখনো কোনো লোকেশন অ্যাড করেননি',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            Text(
              'আপনার বাড়ি, অফিস বা পছন্দের জায়গা সেভ করে রাখুন যাতে দ্রুত রাইড নিতে পারেন।',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF94A3B8), height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => setState(() {
                _activeTab = 1;
                _error = null;
              }),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('লোকেশন অ্যাড করুন',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
      itemCount: _myLocations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildLocationItem(_myLocations[i]),
    );
  }

  Widget _buildLocationItem(CustomRideLocation loc) {
    if (_deletePendingId == loc.id) return _buildDeleteConfirmCard(loc);
    if (_editingId == loc.id) return _buildEditCard(loc);
    return _buildNormalCard(loc);
  }

  // ── Delete confirmation ───────────────────────────────────────────────

  Widget _buildDeleteConfirmCard(CustomRideLocation loc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _deleteSecondConfirm
                    ? 'সত্যিই ডিলিট করবেন?'
                    : '"${loc.name}" ডিলিট করবেন?',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.red.shade800),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            _deleteSecondConfirm
                ? '⚠ এই অ্যাকশন ফেরানো যাবে না। লোকেশন অ্যাড করতে দেওয়া ৳199 রিফান্ড করা হবে না।'
                : 'লোকেশন ডিলিট করলে এটি সার্চ থেকে সরিয়ে দেওয়া হবে। পেমেন্ট রিফান্ড করা হবে না।',
            style: GoogleFonts.inter(
                fontSize: 12, color: Colors.red.shade700, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isDeleting
                    ? null
                    : () => setState(() {
                          _deletePendingId = null;
                          _deleteSecondConfirm = false;
                        }),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('বাতিল',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _isDeleting ? null : () => _onDeleteTap(loc.id),
                style: FilledButton.styleFrom(
                  backgroundColor: _deleteSecondConfirm
                      ? const Color(0xFFDC2626)
                      : Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: AdsyLoadingIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _deleteSecondConfirm
                            ? 'হ্যাঁ, ডিলিট করুন'
                            : 'ডিলিট করুন',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Edit card ──────────────────────────────────────────────────────────

  Widget _buildEditCard(CustomRideLocation loc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('এডিট করুন',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF9A3412))),
          const SizedBox(height: 10),
          _textField(
              controller: _editNameCtl, label: 'Name', hint: 'Location name'),
          const SizedBox(height: 8),
          _textField(
              controller: _editSubtitleCtl,
              label: 'Area / details',
              hint: 'Area'),
          const SizedBox(height: 8),
          _textField(
              controller: _editKeywordsCtl,
              label: 'Keywords',
              hint: 'Comma-separated'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isEditSaving
                    ? null
                    : () => setState(() {
                          _editingId = null;
                          _error = null;
                        }),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('বাতিল',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _isEditSaving ? null : () => _saveEdit(loc.id),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isEditSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: AdsyLoadingIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('সেভ করুন',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Normal location card ──────────────────────────────────────────────

  Widget _buildNormalCard(CustomRideLocation loc) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectLocation(loc),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEA580C).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: Color(0xFFEA580C), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.name,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (loc.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      loc.subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => _startEdit(loc),
              icon: const Icon(Icons.edit_rounded,
                  size: 18, color: Color(0xFF64748B)),
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            IconButton(
              onPressed: () => _onDeleteTap(loc.id),
              icon: Icon(Icons.delete_outline_rounded,
                  size: 18, color: Colors.red.shade400),
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 – Add New Location
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAddTab(bool hasEnoughBalance, double walletBalance) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ───
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.add_location_alt_rounded,
                  color: Color(0xFFEA580C)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'নতুন লোকেশন অ্যাড',
                    style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'প্রতি লোকেশন সেভ করতে ৳199 AdsyPay ব্যালেন্স থেকে কাটা হবে।',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        height: 1.35),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Coordinates ───
          Row(children: [
            Expanded(
                child: _textField(
                    controller: _latCtl,
                    label: 'Latitude',
                    hint: '23.905722',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true))),
            const SizedBox(width: 10),
            Expanded(
                child: _textField(
                    controller: _lonCtl,
                    label: 'Longitude',
                    hint: '89.136444',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true))),
          ]),
          const SizedBox(height: 14),

          // ── Quick fill ───
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickFillChip(
                label: _isResolvingGps ? 'Loading GPS...' : 'Use current GPS',
                onTap: _isResolvingGps ? null : _useCurrentGps,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Fields ───
          _textField(
              controller: _nameCtl,
              label: 'Location name',
              hint: 'যেমন: আমার বাড়ির নাম, গ্রামের মোড়'),
          const SizedBox(height: 12),
          _textField(
              controller: _subtitleCtl,
              label: 'Area / details',
              hint: 'যেমন: মিরপুর, ঢাকা'),
          const SizedBox(height: 12),
          _textField(
              controller: _keywordsCtl,
              label: 'Search keywords',
              hint: 'কমা দিয়ে alias লিখুন, যেমন: bari, village home'),
          const SizedBox(height: 18),

          // ── Low balance warning ───
          if (!hasEnoughBalance) ...[
            Text(
              'আপনার ব্যালেন্স কম আছে। আগে wallet-এ টাকা add করলে লোকেশন সেভ করতে পারবেন।',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB91C1C)),
            ),
            const SizedBox(height: 12),
          ],

          // ── Buttons ───
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Cancel',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: (!hasEnoughBalance || _isSubmitting)
                    ? null
                    : _submitNewLocation,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: AdsyLoadingIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Pay ৳199 & Save',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared tiny widgets
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFFEA580C), width: 1.4)),
          ),
        ),
      ],
    );
  }

  Widget _quickFillChip({required String label, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              onTap == null ? const Color(0xFFF1F5F9) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: onTap == null
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFC7D2FE)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: onTap == null
                ? const Color(0xFF94A3B8)
                : const Color(0xFF4338CA),
          ),
        ),
      ),
    );
  }
}
