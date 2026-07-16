import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/gold_sponsor_service.dart';
import '../../screens/business_network/become_gold_sponsor_screen.dart';
import '../../utils/html_content_utils.dart';
import '../../utils/payment_policy.dart';
import '../ios_web_redirect_screen.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class DrawerGoldSponsor extends StatefulWidget {
  final bool isLoggedIn;

  const DrawerGoldSponsor({
    super.key,
    required this.isLoggedIn,
  });

  @override
  State<DrawerGoldSponsor> createState() => _DrawerGoldSponsorState();
}

class _DrawerGoldSponsorState extends State<DrawerGoldSponsor> {
  bool _isLoading = false;
  int _activeCount = 0;
  int _totalViews = 0;
  int _expiringCount = 0;
  List<Map<String, dynamic>> _sponsors = [];

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) _loadGoldSponsors();
  }

  Future<void> _loadGoldSponsors() async {
    setState(() => _isLoading = true);
    try {
      final response = await GoldSponsorService.getMySponsorsStats();
      if (mounted) {
        setState(() {
          _activeCount = response['active_count'] ?? 0;
          _totalViews = response['total_views'] ?? 0;
          _expiringCount = 0;
          final sponsors = response['featured_sponsors'] as List? ?? [];
          _sponsors =
              sponsors.map((s) => Map<String, dynamic>.from(s)).toList();
        });
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        const Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  size: 14, color: Color(0xFFF59E0B)),
              SizedBox(width: 6),
              Text(
                'GOLD SPONSORS',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),

        // Content card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child:
              widget.isLoggedIn ? _buildLoggedInContent() : _buildLoginPrompt(),
        ),
      ],
    );
  }

  Widget _buildLoggedInContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        Row(
          children: [
            _buildStatChip('Active', _activeCount.toString(), _isLoading),
            const SizedBox(width: 6),
            _buildStatChip('Views', _formatViews(_totalViews), _isLoading),
            const SizedBox(width: 6),
            _buildStatChip('Expiring', _expiringCount.toString(), _isLoading,
                isWarning: _expiringCount > 0),
          ],
        ),

        if (_isLoading) ...[
          const SizedBox(height: 8),
          _buildLoadingList(),
        ] else if (_sponsors.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSponsorsList(),
        ],

        // CTA
        if (isIOSPlatform) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.email_rounded, size: 12, color: Colors.amber.shade700),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  'partnership@adsyclub.com',
                  style: TextStyle(fontSize: 11, color: Color(0xFF334155)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone_rounded, size: 12, color: Colors.amber.shade700),
              const SizedBox(width: 5),
              const Text(
                '+8801896144066',
                style: TextStyle(fontSize: 11, color: Color(0xFF334155)),
              ),
            ],
          ),
        ] else if (!PaymentPolicy.shouldBlockDigitalPayment()) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.amber.shade500,
              borderRadius: BorderRadius.circular(7),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BecomeGoldSponsorScreen()),
                ),
                borderRadius: BorderRadius.circular(7),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 13, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'Become Gold Sponsor',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      children: [
        Icon(Icons.workspace_premium_rounded,
            size: 20, color: Colors.amber.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Login to manage your Gold Sponsorships',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.amber.shade500,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/login'),
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              child: Text(
                'Login',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, bool isLoading,
      {bool isWarning = false}) {
    final color =
        isWarning ? Colors.orange.shade600 : const Color(0xFF0F172A);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            if (isLoading)
              Container(
                height: 14,
                width: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              )
            else
              Text(value,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return Column(
      children: List.generate(
        2,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildSponsorsList() {
    return Column(
      children: _sponsors.map((sponsor) {
        final name =
            _plainSponsorText(sponsor['name'], fallback: 'Unnamed Sponsor');
        final status = sponsor['status'] as String?;
        return Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: (sponsor['image'] ?? '').toString().isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: sponsor['image'],
                        width: 20,
                        height: 20,
                        fit: BoxFit.cover,
                        memCacheWidth: 128,
                        errorWidget: (_, __, ___) => Container(
                          width: 20,
                          height: 20,
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.business, size: 12),
                        ),
                      )
                    : Container(
                        width: 20,
                        height: 20,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.business, size: 12),
                      ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(
                      fontSize: 9,
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600),
                ),
              ),
              // Manage my sponsorship. Edit is temporarily hidden (2026-06,
              // per request) — re-enable by adding the 'edit' item back; the
              // _editSponsor flow below stays ready.
              SizedBox(
                width: 24,
                height: 24,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert,
                      size: 15, color: Colors.grey.shade500),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') _editSponsor(sponsor);
                    if (value == 'delete') _deleteSponsor(sponsor);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'delete',
                      height: 40,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _editSponsor(Map<String, dynamic> sponsor) async {
    final sponsorId = int.tryParse((sponsor['id'] ?? '').toString());
    if (sponsorId == null) return;

    // Pull the full record so description is prefilled too (the sidebar
    // stats payload only carries name/image/status).
    Map<String, dynamic> full = sponsor;
    final mine = await GoldSponsorService.getMySponsors();
    for (final m in mine) {
      if ((m['id'] ?? '').toString() == sponsorId.toString()) {
        full = m;
        break;
      }
    }
    if (!mounted) return;

    final nameController = TextEditingController(
        text: _plainSponsorText(full['business_name'] ?? full['name']));
    final descController =
        TextEditingController(text: _plainSponsorText(full['description']));
    bool saving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Edit Sponsorship',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Business name',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                minLines: 2,
                maxLines: 5,
                style: const TextStyle(fontSize: 14, height: 1.4),
                decoration: InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving
                          ? null
                          : () => Navigator.pop(sheetContext, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                              final newName = nameController.text.trim();
                              if (newName.isEmpty) return;
                              setSheetState(() => saving = true);
                              final ok =
                                  await GoldSponsorService.updateMySponsor(
                                sponsorId,
                                {
                                  'business_name': newName,
                                  'description': descController.text.trim(),
                                },
                              );
                              if (!sheetContext.mounted) return;
                              if (ok) {
                                Navigator.pop(sheetContext, true);
                              } else {
                                setSheetState(() => saving = false);
                                AdsyToast.error(sheetContext,
                                    'Could not update sponsorship');
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true && mounted) {
      AdsyToast.success(context, 'Sponsorship updated');
      await _loadGoldSponsors();
    }
  }

  Future<void> _deleteSponsor(Map<String, dynamic> sponsor) async {
    final sponsorId = int.tryParse((sponsor['id'] ?? '').toString());
    if (sponsorId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Sponsorship'),
        content: const Text(
            'Are you sure you want to delete this sponsorship? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await GoldSponsorService.deleteMySponsor(sponsorId);
    if (!mounted) return;
    if (ok) {
      AdsyToast.success(context, 'Sponsorship deleted');
      await _loadGoldSponsors();
    } else {
      AdsyToast.error(context, 'Could not delete sponsorship');
    }
  }

  String _formatViews(int views) {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}K';
    return views.toString();
  }

  String _plainSponsorText(dynamic value, {String fallback = ''}) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return fallback;
    final plainText = HtmlContentUtils.toPlainText(raw);
    return plainText.isNotEmpty ? plainText : fallback;
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending';
      case 'expired':
        return 'Expired';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green.shade600;
      case 'pending':
        return Colors.orange.shade600;
      case 'expired':
        return Colors.red.shade600;
      case 'rejected':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}
