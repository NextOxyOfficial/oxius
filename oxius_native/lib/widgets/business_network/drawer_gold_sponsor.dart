import 'package:flutter/material.dart';
import '../../services/gold_sponsor_service.dart';
import '../../screens/business_network/become_gold_sponsor_screen.dart';
import '../../utils/html_content_utils.dart';
import '../../utils/payment_policy.dart';
import '../ios_web_redirect_screen.dart';

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
          _sponsors = sponsors.map((s) => Map<String, dynamic>.from(s)).toList();
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
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
          child: Row(
            children: [
              Icon(Icons.workspace_premium_rounded, size: 11, color: Colors.amber.shade600),
              const SizedBox(width: 4),
              Text(
                'GOLD SPONSORS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),

        // Content card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.shade50.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade100),
          ),
          child: widget.isLoggedIn ? _buildLoggedInContent() : _buildLoginPrompt(),
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
            _buildStatChip('Expiring', _expiringCount.toString(), _isLoading, isWarning: _expiringCount > 0),
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
                  MaterialPageRoute(builder: (_) => const BecomeGoldSponsorScreen()),
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
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
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
        Icon(Icons.workspace_premium_rounded, size: 20, color: Colors.amber.shade500),
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
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, bool isLoading, {bool isWarning = false}) {
    final color = isWarning ? Colors.orange.shade600 : Colors.amber.shade700;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isWarning ? Colors.orange.shade200 : Colors.amber.shade200),
        ),
        child: Column(
          children: [
            if (isLoading)
              Container(
                height: 14,
                width: 28,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(3),
                ),
              )
            else
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 1),
            Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
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
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildSponsorsList() {
    return Column(
      children: _sponsors.map((sponsor) {
        final name = _plainSponsorText(sponsor['name'], fallback: 'Unnamed Sponsor');
        final status = sponsor['status'] as String?;
        return Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.amber.shade100),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  sponsor['image'] ?? '',
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 20,
                    height: 20,
                    color: Colors.amber.shade100,
                    child: const Icon(Icons.business, size: 12),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(fontSize: 9, color: _getStatusColor(status), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
      case 'active': return 'Active';
      case 'pending': return 'Pending';
      case 'expired': return 'Expired';
      case 'rejected': return 'Rejected';
      default: return 'Unknown';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active': return Colors.green.shade600;
      case 'pending': return Colors.orange.shade600;
      case 'expired': return Colors.red.shade600;
      case 'rejected': return Colors.red.shade600;
      default: return Colors.grey.shade600;
    }
  }
}
