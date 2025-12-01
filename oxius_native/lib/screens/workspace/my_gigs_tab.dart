import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/workspace_service.dart';
import '../../services/api_service.dart';

class MyGigsTab extends StatefulWidget {
  const MyGigsTab({super.key});

  @override
  State<MyGigsTab> createState() => _MyGigsTabState();
}

class _MyGigsTabState extends State<MyGigsTab> {
  final WorkspaceService _workspaceService = WorkspaceService();
  
  List<Map<String, dynamic>> _gigs = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadMyGigs();
  }

  Future<void> _loadMyGigs() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _workspaceService.fetchMyGigs();
      if (mounted) {
        setState(() {
          _gigs = result['results'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load gigs: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredGigs {
    if (_selectedFilter == 'all') return _gigs;
    return _gigs.where((gig) {
      final status = (gig['status'] ?? '').toString().toLowerCase();
      return status == _selectedFilter;
    }).toList();
  }

  String _getImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiService.baseUrl.replaceAll('/api', '')}$url';
  }

  Future<void> _toggleGigStatus(String gigId, String newStatus) async {
    final success = await _workspaceService.updateGigStatus(gigId, newStatus);
    if (success) {
      _loadMyGigs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gig ${newStatus == 'active' ? 'activated' : 'paused'} successfully'),
            backgroundColor: newStatus == 'active' ? Colors.green : Colors.grey[700],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update gig status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteGig(String gigId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Gig'),
        content: const Text('Are you sure you want to delete this gig? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _workspaceService.deleteGig(gigId);
      if (success) {
        _loadMyGigs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gig deleted successfully')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadMyGigs,
      child: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterButton('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterButton('Active', 'active'),
                const SizedBox(width: 8),
                _buildFilterButton('Paused', 'paused'),
                const SizedBox(width: 8),
                _buildFilterButton('Pending', 'pending'),
              ],
            ),
          ),

          // Gigs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredGigs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredGigs.length,
                        itemBuilder: (context, index) {
                          return _buildGigCard(_filteredGigs[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildGigCard(Map<String, dynamic> gig) {
    final status = (gig['status'] ?? 'pending').toString().toLowerCase();
    final price = gig['price']?.toString() ?? '0';
    final ordersCount = gig['orders_count'] ?? 0;
    final rating = (gig['rating'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with status badge overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: _getImageUrl(gig['image_url'] ?? gig['image']),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey, size: 40),
                    ),
                  ),
                ),
              ),
              // Status badge
              Positioned(
                top: 8,
                left: 8,
                child: _buildStatusBadge(status),
              ),
              // Menu button
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: PopupMenuButton(
                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.black87),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      if (status == 'active')
                        const PopupMenuItem(
                          value: 'pause',
                          child: Row(
                            children: [
                              Icon(Icons.pause, size: 18),
                              SizedBox(width: 8),
                              Text('Pause'),
                            ],
                          ),
                        ),
                      if (status == 'paused')
                        const PopupMenuItem(
                          value: 'activate',
                          child: Row(
                            children: [
                              Icon(Icons.play_arrow, size: 18, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Activate', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'delete') {
                        _deleteGig(gig['id'].toString());
                      } else if (value == 'pause') {
                        await _toggleGigStatus(gig['id'].toString(), 'paused');
                      } else if (value == 'activate') {
                        await _toggleGigStatus(gig['id'].toString(), 'active');
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  gig['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Stats Row
                Row(
                  children: [
                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '৳$price',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Orders
                    Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$ordersCount orders',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    // Rating
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13, 
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
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

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'active':
        bgColor = Colors.green;
        textColor = Colors.white;
        label = 'Active';
        icon = Icons.check_circle;
        break;
      case 'paused':
        bgColor = Colors.grey[700]!;
        textColor = Colors.white;
        label = 'Paused';
        icon = Icons.pause;
        break;
      case 'pending':
        bgColor = Colors.orange;
        textColor = Colors.white;
        label = 'Pending';
        icon = Icons.schedule;
        break;
      case 'rejected':
        bgColor = Colors.red;
        textColor = Colors.white;
        label = 'Rejected';
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.grey;
        textColor = Colors.white;
        label = status.toUpperCase();
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No gigs yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first gig to start earning',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to create gig tab
            },
            icon: const Icon(Icons.add),
            label: const Text('Create a Gig'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
