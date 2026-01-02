import 'package:flutter/material.dart';
import '../../services/gold_sponsor_service.dart';
import '../../screens/business_network/become_gold_sponsor_screen.dart';

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
    if (widget.isLoggedIn) {
      _loadGoldSponsors();
    }
  }

  Future<void> _loadGoldSponsors() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch real data from API
      final response = await GoldSponsorService.getMySponsorsStats();
      
      if (mounted) {
        setState(() {
          _activeCount = response['active_count'] ?? 0;
          _totalViews = response['total_views'] ?? 0;
          
          // Calculate expiring count (sponsors expiring in next 7 days)
          final sponsors = response['featured_sponsors'] as List? ?? [];
          _expiringCount = 0; // TODO: Calculate from end_date if needed
          
          _sponsors = sponsors.map((s) => Map<String, dynamic>.from(s)).toList();
          
          print('DEBUG: Loaded ${_sponsors.length} sponsors');
          print('DEBUG: Active count: $_activeCount');
          print('DEBUG: Sponsors: $_sponsors');
        });
      }
    } catch (e) {
      print('Error loading gold sponsors: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade50,
            Colors.yellow.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.shade100.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer effect
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade500.withOpacity(0),
                  Colors.amber.shade500,
                  Colors.amber.shade500.withOpacity(0),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Header
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.amber.shade400,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '✦',
                    style: TextStyle(
                      color: Colors.amber.shade500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.amber.shade600, Colors.yellow.shade600],
                ).createShader(bounds),
                child: Text(
                  widget.isLoggedIn ? 'My Gold Sponsorships' : 'Gold Sponsorships',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Content based on login status
          if (widget.isLoggedIn)
            _buildLoggedInContent()
          else
            _buildLoginPrompt(),
        ],
      ),
    );
  }

  Widget _buildLoggedInContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Active', _activeCount.toString(), _isLoading),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildStatCard('Views', _formatViews(_totalViews), _isLoading),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildStatCard(
                'Expiring',
                _expiringCount.toString(),
                _isLoading,
                isWarning: _expiringCount > 0,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Sponsors list or empty state
        if (_isLoading)
          _buildLoadingList()
        else if (_sponsors.isEmpty)
          _buildEmptyState()
        else
          _buildSponsorsList(),
        
        const SizedBox(height: 12),
        
        // Description
        Text(
          'Become a Gold Sponsor and showcase your business to our entire network with premium visibility.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Become Gold Sponsor button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BecomeGoldSponsorScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Become Gold Sponsor',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.add, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade100),
          ),
          child: Column(
            children: [
              Icon(
                Icons.lock,
                size: 24,
                color: Colors.amber.shade500,
              ),
              const SizedBox(height: 8),
              const Text(
                'Login Required',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Login or register to access Gold Sponsor features',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login, size: 16),
                      SizedBox(width: 6),
                      Text('Login to Continue'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, bool isLoading, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWarning ? Colors.orange.shade200 : Colors.amber.shade100,
        ),
      ),
      child: Column(
        children: [
          if (isLoading)
            Container(
              height: 20,
              width: 32,
              decoration: BoxDecoration(
                color: Colors.amber.shade100.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isWarning ? Colors.orange.shade600 : Colors.amber.shade600,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return Column(
      children: List.generate(
        2,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 10,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "You don't have any active sponsorships yet.",
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSponsorsList() {
    return Column(
      children: _sponsors.map((sponsor) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  sponsor['image'] ?? '',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 24,
                      height: 24,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.business, size: 16),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sponsor['name'] ?? 'Unnamed Sponsor',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sponsor['business_description'] != null)
                      Text(
                        sponsor['business_description'],
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(sponsor['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(sponsor['status']).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getStatusText(sponsor['status']).toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: _getStatusColor(sponsor['status']),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending Approval';
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
