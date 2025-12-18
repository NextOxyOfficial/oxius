import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/workspace_service.dart';
import '../../utils/network_error_handler.dart';
import '../../services/api_service.dart';
import 'order_chat_screen.dart';
import 'gig_detail_screen.dart';

class GigsOrderedTab extends StatefulWidget {
  const GigsOrderedTab({super.key});

  @override
  State<GigsOrderedTab> createState() => _GigsOrderedTabState();
}

class _GigsOrderedTabState extends State<GigsOrderedTab> {
  final WorkspaceService _workspaceService = WorkspaceService();
  
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  final Map<String, String> _statusFilters = {
    'all': 'All',
    'pending': 'Pending',
    'in_progress': 'In Progress',
    'delivered': 'Delivered',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _workspaceService.fetchMyOrders(
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );
      if (mounted) {
        setState(() {
          _orders = result['results'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiService.baseUrl.replaceAll('/api', '')}$url';
  }

  void _openChat(Map<String, dynamic> order) {
    final seller = order['seller'] ?? order['gig']?['user'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderChatScreen(
          orderId: order['id'].toString(),
          orderNumber: order['id'].toString().substring(0, 8).toUpperCase(),
          otherUser: {
            'id': seller?['id']?.toString(),
            'name': seller?['name'] ?? 'Seller',
            'avatar': seller?['avatar'],
            'kyc': seller?['kyc'] ?? false,
          },
          onMessagesRead: _loadOrders,
        ),
      ),
    );
  }

  Future<void> _completeOrder(String orderId) async {
    try {
      await _workspaceService.completeOrderPayment(orderId);
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order completed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        NetworkErrorHandler.showErrorSnackbar(
          context, 
          e,
          customMessage: 'Unable to complete order',
        );
      }
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _workspaceService.cancelOrder(orderId);
      if (success) {
        _loadOrders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled')),
          );
        }
      }
    }
  }

  Future<void> _reopenOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Revision'),
        content: const Text('Are you sure you want to request a revision for this order? The seller will be notified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Request Revision'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _workspaceService.updateOrderStatus(orderId, 'reopen');
      if (success) {
        _loadOrders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Revision requested')),
          );
        }
      }
    }
  }

  void _showReviewDialog(Map<String, dynamic> order) {
    // TODO: Implement review dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review feature coming soon')),
    );
  }

  Future<void> _showDisputeDialog(String orderId) async {
    String? selectedReason;
    final descriptionController = TextEditingController();
    
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Row(
                    children: [
                      Icon(Icons.report_problem, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Raise a Dispute',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select a reason and provide details.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 14),
                  // Reason dropdown
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    isDense: true,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      labelStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: WorkspaceService.disputeReasons.map((reason) {
                      return DropdownMenuItem(
                        value: reason['value'],
                        child: Text(reason['label']!, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedReason = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Description field
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: const TextStyle(fontSize: 13),
                      hintText: 'Describe your issue (min 20 chars)',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedReason == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select a reason')),
                              );
                              return;
                            }
                            if (descriptionController.text.trim().length < 20) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Description must be at least 20 characters')),
                              );
                              return;
                            }
                            Navigator.pop(context, true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Submit', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result == true && selectedReason != null) {
      final response = await _workspaceService.createDispute(
        orderId: orderId,
        reason: selectedReason!,
        description: descriptionController.text.trim(),
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Dispute raised successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadOrders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['error'] ?? 'Failed to raise dispute'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildFilterButton(entry.value, entry.key),
                  );
                }).toList(),
              ),
            ),
          ),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(_orders[index]);
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
      onTap: () {
        setState(() => _selectedFilter = filter);
        _loadOrders();
      },
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
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final gig = order['gig'] as Map<String, dynamic>?;
    final seller = order['seller'] as Map<String, dynamic>?;
    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    final price = order['price']?.toString() ?? '0';
    final createdAt = order['created_at'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Text(
                  'Order #${order['id'].toString().substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                _buildStatusBadge(status),
              ],
            ),
          ),
          
          // Order Content
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gig Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: CachedNetworkImage(
                      imageUrl: _getImageUrl(gig?['image_url'] ?? gig?['image']),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                
                // Order Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => GigDetailScreen(gigId: gig?['id']?.toString() ?? '')),
                        ),
                        child: Text(
                          gig?['title'] ?? 'Unknown Gig',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF8B5CF6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Seller Info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 8,
                            backgroundImage: seller?['avatar'] != null
                                ? CachedNetworkImageProvider(_getImageUrl(seller!['avatar']))
                                : null,
                            child: seller?['avatar'] == null
                                ? Text(
                                    (seller?['name'] ?? 'S')[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 7),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'from ${seller?['name'] ?? 'Unknown'}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (seller?['kyc'] == true)
                            const Padding(
                              padding: EdgeInsets.only(left: 3),
                              child: Icon(Icons.verified, size: 12, color: Colors.blue),
                            ),
                          if (seller?['is_pro'] == true)
                            Container(
                              margin: const EdgeInsets.only(left: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFF97316)]),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '৳$price',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons (including Chat)
          if (_canTakeAction(status))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: _buildActionButtons(
                  order, 
                  status,
                  hasDispute: order['has_dispute'] == true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _canTakeAction(String status) {
    return status != 'cancelled';
  }

  List<Widget> _buildActionButtons(Map<String, dynamic> order, String status, {bool hasDispute = false}) {
    final orderId = order['id'].toString();
    final buttons = <Widget>[];
    
    // Chat button - always show first (except cancelled)
    final unreadCount = order['unread_messages'] ?? 0;
    buttons.add(
      Stack(
        clipBehavior: Clip.none,
        children: [
          OutlinedButton(
            onPressed: () => _openChat(order),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[200]!),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/chat_icon.png',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 4),
                const Text('Chat', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 14,
                  minHeight: 14,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
    
    if (status == 'pending') {
      buttons.add(const SizedBox(width: 6));
      buttons.add(
        OutlinedButton(
          onPressed: () => _cancelOrder(orderId),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('Cancel', style: TextStyle(fontSize: 12)),
        ),
      );
    } else if (status == 'delivered') {
      buttons.add(const SizedBox(width: 6));
      buttons.add(
        OutlinedButton(
          onPressed: () => _reopenOrder(orderId),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange[600],
            side: BorderSide(color: Colors.orange[200]!),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('Reopen', style: TextStyle(fontSize: 12)),
        ),
      );
      buttons.add(const SizedBox(width: 6));
      buttons.add(
        ElevatedButton(
          onPressed: () => _completeOrder(orderId),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('Complete', style: TextStyle(fontSize: 12)),
        ),
      );
    } else if (status == 'in_progress' || status == 'revision') {
      if (!hasDispute) {
        buttons.add(const SizedBox(width: 6));
        buttons.add(
          OutlinedButton(
            onPressed: () => _showDisputeDialog(orderId),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Dispute', style: TextStyle(fontSize: 12)),
          ),
        );
      }
    } else if (status == 'disputed') {
      buttons.add(const SizedBox(width: 6));
      buttons.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber, size: 12, color: Colors.red[700]),
              const SizedBox(width: 4),
              Text(
                'Disputed',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (status == 'completed') {
      buttons.add(const SizedBox(width: 6));
      buttons.add(
        ElevatedButton(
          onPressed: () => _showReviewDialog(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('Write Review', style: TextStyle(fontSize: 12)),
        ),
      );
    }
    
    return buttons;
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        label = 'Pending';
        break;
      case 'in_progress':
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        label = 'In Progress';
        break;
      case 'delivered':
        bgColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        label = 'Delivered';
        break;
      case 'completed':
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        label = 'Completed';
        break;
      case 'cancelled':
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        label = 'Cancelled';
        break;
      case 'disputed':
        bgColor = Colors.deepOrange.withValues(alpha: 0.1);
        textColor = Colors.deepOrange;
        label = 'Disputed';
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your ordered gigs will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
