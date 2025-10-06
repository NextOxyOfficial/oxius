import 'package:flutter/material.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeTab = 'updates';
  String _ticketStatusFilter = 'all';
  String _updatesFilter = 'all';
  int _newMessageCount = 0;
  int _newTicketCount = 0;
  
  // Mock data - replace with actual API calls
  final List<Map<String, dynamic>> _updates = [
    {
      'id': 1,
      'title': 'Welcome to Oxius!',
      'message': 'Thank you for joining our platform.',
      'isRead': false,
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'type': 'system'
    },
    {
      'id': 2,
      'title': 'Profile Verification Required',
      'message': 'Please complete your profile verification.',
      'isRead': true,
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'type': 'verification'
    }
  ];

  final List<Map<String, dynamic>> _tickets = [
    {
      'id': 1,
      'title': 'Payment Issue',
      'message': 'I am having trouble with my payment.',
      'status': 'open',
      'isRead': false,
      'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
      'priority': 'high'
    },
    {
      'id': 2,
      'title': 'Account Access',
      'message': 'Cannot access my account.',
      'status': 'resolved',
      'isRead': true,
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'priority': 'medium'
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _activeTab = _tabController.index == 0 ? 'updates' : 'support';
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper methods
  int get updatesCount => _updates.where((u) => !u['isRead']).length;
  int get supportTicketsCount => _tickets.where((t) => !t['isRead']).length;
  bool get hasUnreadMessages =>
      _activeTab == 'updates' ? updatesCount > 0 : supportTicketsCount > 0;

  List<Map<String, dynamic>> get filteredUpdates {
    return _updates.where((update) {
      if (_updatesFilter == 'all') return true;
      if (_updatesFilter == 'unread') return !update['isRead'];
      if (_updatesFilter == 'read') return update['isRead'];
      return update['type'] == _updatesFilter;
    }).toList();
  }

  List<Map<String, dynamic>> get filteredTickets {
    return _tickets.where((ticket) {
      if (_ticketStatusFilter == 'all') return true;
      return ticket['status'] == _ticketStatusFilter;
    }).toList();
  }

  void _setActiveTab(String tab) {
    setState(() {
      _activeTab = tab;
      _tabController.animateTo(tab == 'updates' ? 0 : 1);
    });
  }

  void _setTicketStatusFilter(String filter) {
    setState(() {
      _ticketStatusFilter = filter;
    });
  }

  void _setUpdatesFilter(String filter) {
    setState(() {
      _updatesFilter = filter;
    });
  }

  void _openNewTicketModal() {
    // Implement ticket creation modal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Support Ticket'),
        content: const Text('Feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      if (_activeTab == 'updates') {
        for (var update in _updates) {
          update['isRead'] = true;
        }
      } else {
        for (var ticket in _tickets) {
          ticket['isRead'] = true;
        }
      }
    });
  }

  void _clearNotifications() {
    setState(() {
      _newMessageCount = 0;
      _newTicketCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Message Center',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            margin: EdgeInsets.all(isMobile ? 16 : 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF9FAFB), Color(0xFFF3F4F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Icon
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.inbox,
                      color: Color(0xFF059669),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Message Center',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Manage your notifications and support tickets',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Message count badge
                  if (_updates.length + _tickets.length > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_updates.length + _tickets.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openNewTicketModal,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Open Ticket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasUnreadMessages ? _markAllAsRead : null,
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: Text(isMobile ? 'Mark All Read' : 'Mark All Read'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF059669),
              labelColor: const Color(0xFF059669),
              unselectedLabelColor: const Color(0xFF6B7280),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications, size: 18),
                      const SizedBox(width: 8),
                      const Text('Updates'),
                      if (updatesCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            updatesCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.support_agent, size: 18),
                      const SizedBox(width: 8),
                      const Text('Support'),
                      if (supportTicketsCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            supportTicketsCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          Container(
            height: 60,
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 32,
              vertical: 12,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_activeTab == 'support') ...[
                    _buildFilterChip('All Tickets', _ticketStatusFilter == 'all',
                        () => _setTicketStatusFilter('all')),
                    _buildFilterChip('Open', _ticketStatusFilter == 'open',
                        () => _setTicketStatusFilter('open')),
                    _buildFilterChip(
                        'In Progress',
                        _ticketStatusFilter == 'in_progress',
                        () => _setTicketStatusFilter('in_progress')),
                    _buildFilterChip('Resolved', _ticketStatusFilter == 'resolved',
                        () => _setTicketStatusFilter('resolved')),
                    _buildFilterChip('Closed', _ticketStatusFilter == 'closed',
                        () => _setTicketStatusFilter('closed')),
                  ] else ...[
                    _buildFilterChip('All Updates', _updatesFilter == 'all',
                        () => _setUpdatesFilter('all')),
                    _buildFilterChip('Unread', _updatesFilter == 'unread',
                        () => _setUpdatesFilter('unread')),
                    _buildFilterChip('Read', _updatesFilter == 'read',
                        () => _setUpdatesFilter('read')),
                    _buildFilterChip('System', _updatesFilter == 'system',
                        () => _setUpdatesFilter('system')),
                    _buildFilterChip('Verification', _updatesFilter == 'verification',
                        () => _setUpdatesFilter('verification')),
                  ],
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpdatesList(),
                _buildTicketsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: const Color(0xFFF9FAFB),
        selectedColor: const Color(0xFF059669),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF6B7280),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdatesList() {
    final updates = filteredUpdates;
    
    if (updates.isEmpty) {
      return _buildEmptyState('No updates found');
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 768 ? 16 : 32,
      ),
      itemCount: updates.length,
      itemBuilder: (context, index) {
        final update = updates[index];
        return _buildUpdateItem(update);
      },
    );
  }

  Widget _buildTicketsList() {
    final tickets = filteredTickets;
    
    if (tickets.isEmpty) {
      return _buildEmptyState('No tickets found');
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 768 ? 16 : 32,
      ),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _buildTicketItem(ticket);
      },
    );
  }

  Widget _buildUpdateItem(Map<String, dynamic> update) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: update['isRead'] ? Colors.white : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: update['isRead'] ? const Color(0xFFE5E7EB) : const Color(0xFF059669),
          width: update['isRead'] ? 1 : 2,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: update['isRead'] 
              ? const Color(0xFFF3F4F6) 
              : const Color(0xFF059669),
          child: Icon(
            update['type'] == 'system' ? Icons.settings : Icons.verified_user,
            color: update['isRead'] ? const Color(0xFF6B7280) : Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          update['title'],
          style: TextStyle(
            fontWeight: update['isRead'] ? FontWeight.w500 : FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              update['message'],
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(update['timestamp']),
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            update['isRead'] = true;
          });
        },
      ),
    );
  }

  Widget _buildTicketItem(Map<String, dynamic> ticket) {
    Color statusColor;
    switch (ticket['status']) {
      case 'open':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'in_progress':
        statusColor = const Color(0xFF3B82F6);
        break;
      case 'resolved':
        statusColor = const Color(0xFF10B981);
        break;
      case 'closed':
        statusColor = const Color(0xFF6B7280);
        break;
      default:
        statusColor = const Color(0xFF6B7280);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ticket['isRead'] ? Colors.white : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ticket['isRead'] ? const Color(0xFFE5E7EB) : const Color(0xFF059669),
          width: ticket['isRead'] ? 1 : 2,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(
            Icons.support_agent,
            color: statusColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                ticket['title'],
                style: TextStyle(
                  fontWeight: ticket['isRead'] ? FontWeight.w500 : FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ticket['status'].toString().toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              ticket['message'],
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(ticket['timestamp']),
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            ticket['isRead'] = true;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}