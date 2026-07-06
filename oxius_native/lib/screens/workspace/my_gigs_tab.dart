import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/workspace_service.dart';
import '../../utils/network_error_handler.dart';
import '../../services/api_service.dart';
import '../../services/translation_service.dart';
import 'gig_detail_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class MyGigsTab extends StatefulWidget {
  const MyGigsTab({super.key});

  @override
  State<MyGigsTab> createState() => _MyGigsTabState();
}

class _MyGigsTabState extends State<MyGigsTab> {
  final WorkspaceService _workspaceService = WorkspaceService();

  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) =>
      _i18n.translate(key, fallback: fallback);

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
        NetworkErrorHandler.showErrorSnackbar(
          context,
          e,
          onRetry: () => _loadMyGigs(),
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
        AdsyToast.success(
            context,
            newStatus == 'active'
                ? _t('workspace_gig_activated', 'গিগ চালু হয়েছে')
                : _t('workspace_gig_paused', 'গিগ পজ করা হয়েছে'));
      }
    } else {
      if (mounted) {
        AdsyToast.error(
            context,
            _t('workspace_gig_status_failed',
                'গিগের স্ট্যাটাস আপডেট করা যায়নি'));
      }
    }
  }

  Future<void> _deleteGig(String gigId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('workspace_delete_gig', 'গিগ ডিলিট করবেন?')),
        content: Text(_t('workspace_delete_gig_confirm',
            'এই গিগটি ডিলিট করতে চান? এটা আর ফেরানো যাবে না।')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t('workspace_cancel', 'ক্যান্সেল')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(_t('workspace_delete', 'ডিলিট')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _workspaceService.deleteGig(gigId);
      if (success) {
        _loadMyGigs();
        if (mounted) {
          AdsyToast.success(
              context, _t('workspace_gig_deleted', 'গিগ ডিলিট হয়েছে'));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdsyRefreshIndicator(
      onRefresh: _loadMyGigs,
      child: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterButton(_t('workspace_all', 'সব'), 'all'),
                const SizedBox(width: 6),
                _buildFilterButton(_t('workspace_active', 'চালু'), 'active'),
                const SizedBox(width: 6),
                _buildFilterButton(_t('workspace_paused', 'পজ'), 'paused'),
                const SizedBox(width: 6),
                _buildFilterButton(
                    _t('workspace_pending', 'অপেক্ষমাণ'), 'pending'),
              ],
            ),
          ),

          // Gigs List
          Expanded(
            child: _isLoading
                ? const Center(child: AdsyLoadingIndicator())
                : _filteredGigs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
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
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 50,
                height: 50,
                child: CachedNetworkImage(
                  imageUrl: _getImageUrl(gig['image_url'] ?? gig['image']),
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child:
                        const Icon(Icons.image, color: Colors.grey, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with status
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GigDetailScreen(
                                    gigId: gig['id'].toString())),
                          ),
                          child: Text(
                            gig['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8B5CF6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Stats row
                  Row(
                    children: [
                      Text(
                        '৳$price',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.shopping_bag_outlined,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Text(
                        '$ordersCount',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu button
            PopupMenuButton(
              icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  height: 36,
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 16),
                      const SizedBox(width: 8),
                      Text(_t('workspace_edit', 'এডিট'),
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                if (status == 'active')
                  PopupMenuItem(
                    value: 'pause',
                    height: 36,
                    child: Row(
                      children: [
                        const Icon(Icons.pause, size: 16),
                        const SizedBox(width: 8),
                        Text(_t('workspace_pause', 'পজ'),
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                if (status == 'paused')
                  PopupMenuItem(
                    value: 'activate',
                    height: 36,
                    child: Row(
                      children: [
                        const Icon(Icons.play_arrow,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(_t('workspace_activate', 'চালু করুন'),
                            style: const TextStyle(
                                color: Colors.green, fontSize: 13)),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  height: 36,
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(_t('workspace_delete', 'ডিলিট'),
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    String label;

    switch (status) {
      case 'active':
        bgColor = Colors.green;
        label = _t('workspace_active', 'চালু');
        break;
      case 'paused':
        bgColor = Colors.grey[700]!;
        label = _t('workspace_paused', 'পজ');
        break;
      case 'pending':
        bgColor = Colors.orange;
        label = _t('workspace_pending', 'অপেক্ষমাণ');
        break;
      case 'rejected':
        bgColor = Colors.red;
        label = _t('workspace_rejected', 'বাতিল');
        break;
      default:
        bgColor = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: bgColor,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
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
            _t('workspace_no_gigs_yet', 'এখনো কোনো গিগ নেই'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t('workspace_create_first_gig',
                'আয় শুরু করতে প্রথম গিগটি তৈরি করুন'),
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to create gig tab
            },
            icon: const Icon(Icons.add),
            label: Text(_t('workspace_create_a_gig', 'গিগ তৈরি করুন')),
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
