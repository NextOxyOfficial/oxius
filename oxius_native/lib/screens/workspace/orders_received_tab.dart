import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/workspace_service.dart';
import '../../services/api_service.dart';
import 'order_chat_screen.dart';

class OrdersReceivedTab extends StatefulWidget {
  const OrdersReceivedTab({super.key});

  @override
  State<OrdersReceivedTab> createState() => _OrdersReceivedTabState();
}

class _OrdersReceivedTabState extends State<OrdersReceivedTab> {
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
      final result = await _workspaceService.fetchSellerOrders(
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
    final buyer = order['buyer'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderChatScreen(
          orderId: order['id'].toString(),
          orderNumber: order['id'].toString().substring(0, 8).toUpperCase(),
          otherUser: {
            'id': buyer?['id']?.toString(),
            'name': buyer?['name'] ?? 'Buyer',
            'avatar': buyer?['avatar'],
            'kyc': buyer?['kyc'] ?? false,
          },
          onMessagesRead: _loadOrders,
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String action) async {
    final success = await _workspaceService.updateOrderStatus(orderId, action);
    if (success) {
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order ${action.replaceAll('_', ' ')}')),
        );
      }
    }
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Row(
                    children: [
                      Icon(Icons.report_problem, color: Colors.orange[700], size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Raise a Dispute',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please select a reason and provide details about your issue.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  // Reason dropdown
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: selectedReason,
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: WorkspaceService.disputeReasons.map((reason) {
                      return DropdownMenuItem(
                        value: reason['value'],
                        child: Text(reason['label']!, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedReason = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Description field
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Please provide detailed information about your issue (min 20 characters)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Submit Dispute'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
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
                        padding: const EdgeInsets.all(12),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final gig = order['gig'] as Map<String, dynamic>?;
    final buyer = order['buyer'] as Map<String, dynamic>?;
    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    final price = order['price']?.toString() ?? '0';
    final createdAt = order['created_at'] ?? '';

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
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text(
                  'Order #${order['id'].toString().substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                _buildStatusBadge(status),
              ],
            ),
          ),
          
          // Order Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gig Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 70,
                    height: 70,
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
                const SizedBox(width: 12),
                
                // Order Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gig?['title'] ?? 'Unknown Gig',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Buyer Info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: buyer?['avatar'] != null
                                ? CachedNetworkImageProvider(_getImageUrl(buyer!['avatar']))
                                : null,
                            child: buyer?['avatar'] == null
                                ? Text(
                                    (buyer?['name'] ?? 'B')[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 8),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'from ${buyer?['name'] ?? 'Unknown'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '৳$price',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
              padding: const EdgeInsets.all(12),
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
    buttons.add(
      OutlinedButton(
        onPressed: () => _openChat(order),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[700],
          side: BorderSide(color: Colors.grey[200]!),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              'https://adsyclub.com/static/frontend/images/chat_icon.png',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.chat_bubble,
                size: 20,
                color: Color(0xFF4DD0E1),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Chat'),
          ],
        ),
      ),
    );
    
    if (status == 'pending') {
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _updateOrderStatus(orderId, 'accept'),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _updateOrderStatus(orderId, 'reject'),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Decline'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      );
    } else if (status == 'in_progress' || status == 'revision') {
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _updateOrderStatus(orderId, 'deliver'),
            icon: const Icon(Icons.local_shipping, size: 16),
            label: Text(status == 'revision' ? 'Re-deliver' : 'Deliver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    } else if (status == 'delivered' && !hasDispute) {
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _showDisputeDialog(orderId),
          icon: const Icon(Icons.flag, size: 16),
          label: const Text('Dispute'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[600],
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      );
    } else if (status == 'disputed') {
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber, size: 16, color: Colors.red[700]),
              const SizedBox(width: 6),
              Text(
                'Under Dispute',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
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
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No orders received',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Orders from buyers will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
