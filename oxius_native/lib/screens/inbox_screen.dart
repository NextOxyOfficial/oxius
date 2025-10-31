import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'adsy_connect_screen.dart';

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
  int _newChatCount = 0;
  bool _isLoadingUpdates = true;
  bool _isLoadingTickets = true;
  
  // Real data from backend
  List<Map<String, dynamic>> _updates = [];
  List<Map<String, dynamic>> _tickets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        if (_tabController.index == 0) {
          _activeTab = 'chat';
        } else if (_tabController.index == 1) {
          _activeTab = 'updates';
        } else {
          _activeTab = 'support';
        }
      });
    });
    _activeTab = 'chat'; // Default to chat tab
    _loadInboxData();
  }

  Future<void> _loadInboxData() async {
    await Future.wait([
      _loadUpdates(),
      _loadTickets(),
    ]);
  }

  Future<void> _loadUpdates() async {
    setState(() => _isLoadingUpdates = true);
    
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse(ApiService.getApiUrl('notifications/')),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (mounted) {
          setState(() {
            _updates = data.map((item) => {
              'id': item['id'],
              'title': item['title'] ?? 'Notification',
              'message': item['message'] ?? '',
              'isRead': item['is_read'] ?? false,
              'timestamp': DateTime.parse(item['created_at'] ?? DateTime.now().toIso8601String()),
              'type': item['type'] ?? 'system',
            }).toList();
            _isLoadingUpdates = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingUpdates = false);
        }
      }
    } catch (e) {
      print('Error loading updates: $e');
      if (mounted) {
        setState(() => _isLoadingUpdates = false);
      }
    }
  }


  Future<void> _loadTickets() async {
    setState(() => _isLoadingTickets = true);
    
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse(ApiService.getApiUrl('support-tickets/')),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (mounted) {
          setState(() {
            _tickets = data.map((item) => {
              'id': item['id'],
              'title': item['title'] ?? 'Support Ticket',
              'message': item['message'] ?? '',
              'status': item['status'] ?? 'open',
              'isRead': item['is_read'] ?? false,
              'timestamp': DateTime.parse(item['created_at'] ?? DateTime.now().toIso8601String()),
              'priority': item['priority'] ?? 'medium',
            }).toList();
            _isLoadingTickets = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingTickets = false);
        }
      }
    } catch (e) {
      print('Error loading tickets: $e');
      if (mounted) {
        setState(() => _isLoadingTickets = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper methods
  int get updatesCount => _updates.where((u) => !u['isRead']).length;
  int get chatsCount => _newChatCount; // From AdsyConnectScreen
  int get supportTicketsCount => _tickets.where((t) => !t['isRead']).length;
  bool get hasUnreadMessages {
    if (_activeTab == 'updates') return updatesCount > 0;
    if (_activeTab == 'chat') return chatsCount > 0;
    return supportTicketsCount > 0;
  }

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
      int index = 0;
      if (tab == 'chat') index = 0;
      else if (tab == 'updates') index = 1;
      else if (tab == 'support') index = 2;
      _tabController.animateTo(index);
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFF3B82F6).withOpacity(0.02),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  // Back Button
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF3B82F6), size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  // Icon Badge
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title Section
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Flexible(
                              child: Text(
                                'Message Center',
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (updatesCount + chatsCount + supportTicketsCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  (updatesCount + chatsCount + supportTicketsCount).toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Chats, Notifications & Support',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF3B82F6),
              labelColor: const Color(0xFF3B82F6),
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: -0.2),
              unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: -0.2),
              tabAlignment: TabAlignment.fill,
              isScrollable: false,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_rounded, size: 14),
                      const SizedBox(width: 4),
                      const Text('AdsyConnect'),
                      if (chatsCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            chatsCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_rounded, size: 14),
                      const SizedBox(width: 4),
                      const Text('Updates'),
                      if (updatesCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            updatesCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.support_agent_rounded, size: 14),
                      const SizedBox(width: 4),
                      const Text('Support'),
                      if (supportTicketsCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            supportTicketsCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
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

          // Filters and Actions
          if (_activeTab == 'updates' || _activeTab == 'support')
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Row(
                children: [
                  // Dropdown Filter
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _activeTab == 'support' ? _ticketStatusFilter : _updatesFilter,
                          icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                          isExpanded: true,
                          isDense: true,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                          items: _activeTab == 'support'
                              ? [
                                  const DropdownMenuItem(value: 'all', child: Text('All Tickets')),
                                  const DropdownMenuItem(value: 'open', child: Text('Open')),
                                  const DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                                  const DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                                  const DropdownMenuItem(value: 'closed', child: Text('Closed')),
                                ]
                              : [
                                  const DropdownMenuItem(value: 'all', child: Text('All Updates')),
                                  const DropdownMenuItem(value: 'unread', child: Text('Unread')),
                                  const DropdownMenuItem(value: 'read', child: Text('Read')),
                                  const DropdownMenuItem(value: 'system', child: Text('System')),
                                  const DropdownMenuItem(value: 'verification', child: Text('Verification')),
                                ],
                          onChanged: (value) {
                            if (value != null) {
                              if (_activeTab == 'support') {
                                _setTicketStatusFilter(value);
                              } else {
                                _setUpdatesFilter(value);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  // Tab Actions
                  if (_activeTab == 'updates') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: hasUnreadMessages ? _markAllAsRead : null,
                          icon: const Icon(Icons.done_all_rounded, size: 16),
                          label: const Text('Mark Read'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Support Tab Actions
                  if (_activeTab == 'support') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: _openNewTicketModal,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Open'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: hasUnreadMessages ? _markAllAsRead : null,
                          icon: const Icon(Icons.done_all_rounded, size: 16),
                          label: const Text('Mark'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const AdsyConnectScreen(),
                _buildUpdatesList(),
                _buildTicketsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBadge(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
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
    if (_isLoadingUpdates) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final updates = filteredUpdates;
    
    if (updates.isEmpty) {
      return _buildEmptyState('No updates found');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: updates.length,
      itemBuilder: (context, index) {
        final update = updates[index];
        return _buildUpdateItem(update);
      },
    );
  }

  Widget _buildTicketsList() {
    if (_isLoadingTickets) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final tickets = filteredTickets;
    
    if (tickets.isEmpty) {
      return _buildEmptyState('No tickets found');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _buildTicketItem(ticket);
      },
    );
  }

  Widget _buildUpdateItem(Map<String, dynamic> update) {
    final bool isUnread = !update['isRead'];
    
    return InkWell(
      onTap: () {
        setState(() {
          update['isRead'] = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFF0FDF4).withOpacity(0.5) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFE5E7EB).withOpacity(0.4),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnread 
                    ? const Color(0xFF059669).withOpacity(0.1)
                    : const Color(0xFFF3F4F6),
                border: Border.all(
                  color: isUnread ? const Color(0xFF059669).withOpacity(0.25) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(
                update['type'] == 'system' ? Icons.settings_rounded : Icons.verified_user_rounded,
                color: isUnread ? const Color(0xFF059669) : const Color(0xFF6B7280),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          update['title'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: const Color(0xFF1F2937),
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(update['timestamp']),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    update['message'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                      letterSpacing: -0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Unread indicator
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketItem(Map<String, dynamic> ticket) {
    final bool isUnread = !ticket['isRead'];
    Color statusColor;
    String statusLabel;
    
    switch (ticket['status']) {
      case 'open':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'OPEN';
        break;
      case 'in_progress':
        statusColor = const Color(0xFF3B82F6);
        statusLabel = 'IN PROGRESS';
        break;
      case 'resolved':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'RESOLVED';
        break;
      case 'closed':
        statusColor = const Color(0xFF6B7280);
        statusLabel = 'CLOSED';
        break;
      default:
        statusColor = const Color(0xFF6B7280);
        statusLabel = 'UNKNOWN';
    }

    return InkWell(
      onTap: () {
        setState(() {
          ticket['isRead'] = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFF0FDF4).withOpacity(0.5) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFE5E7EB).withOpacity(0.4),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.1),
                border: Border.all(
                  color: statusColor.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.support_agent_rounded,
                color: statusColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket['title'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: const Color(0xFF1F2937),
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ticket['message'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                      letterSpacing: -0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimestamp(ticket['timestamp']),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Unread indicator
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
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