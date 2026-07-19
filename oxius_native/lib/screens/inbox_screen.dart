import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/adsyconnect_service.dart';
import '../services/app_notification_service.dart';
import '../services/deep_link_service.dart';
import '../config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'adsy_connect_screen.dart';
import 'adsy_connect_chat_interface.dart';
import 'support/create_ticket_screen.dart';
import 'support/ticket_detail_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class InboxScreen extends StatefulWidget {
  final int initialTab;
  final String? initialChatId;
  final String? initialTicketId;

  const InboxScreen({
    super.key,
    this.initialTab = 0, // 0 = AdsyConnect, 1 = Updates, 2 = Support
    this.initialChatId,
    this.initialTicketId,
  });

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeTab = 'updates';
  String _ticketStatusFilter = 'all';
  String _updatesFilter = 'all';
  final int _newChatCount = 0;
  bool _isLoadingUpdates = true;
  bool _isLoadingTickets = true;

  // Pagination
  int _updatesPage = 1;
  int _ticketsPage = 1;
  bool _hasMoreUpdates = true;
  bool _hasMoreTickets = true;
  bool _isLoadingMoreUpdates = false;
  bool _isLoadingMoreTickets = false;

  // Real data from backend
  List<Map<String, dynamic>> _updates = [];
  List<Map<String, dynamic>> _tickets = [];

  // Scroll controllers
  final ScrollController _updatesScrollController = ScrollController();
  final ScrollController _ticketsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
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

    // Set initial active tab based on initialIndex
    if (widget.initialTab == 0) {
      _activeTab = 'chat';
    } else if (widget.initialTab == 1) {
      _activeTab = 'updates';
    } else {
      _activeTab = 'support';
    }

    // Add scroll listeners for pagination
    _updatesScrollController.addListener(_onUpdatesScroll);
    _ticketsScrollController.addListener(_onTicketsScroll);

    _loadInboxData();

    // Handle deep linking to specific chat or ticket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleDeepLink();
    });
  }

  void _handleDeepLink() {
    // If we have an initial chat ID, navigate to that chat
    if (widget.initialChatId != null && widget.initialChatId!.isNotEmpty) {
      debugPrint('📱 Deep linking to chat: ${widget.initialChatId}');
      // The AdsyConnectScreen will handle opening the specific chat
      // We just need to make sure we're on the chat tab
    }

    // If we have an initial ticket ID, navigate to that ticket
    if (widget.initialTicketId != null && widget.initialTicketId!.isNotEmpty) {
      debugPrint('📱 Deep linking to ticket: ${widget.initialTicketId}');
      // Navigate to ticket detail
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TicketDetailScreen(
            ticketId: widget.initialTicketId!,
          ),
        ),
      );
    }
  }

  void _onUpdatesScroll() {
    if (_updatesScrollController.position.pixels >=
        _updatesScrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMoreUpdates && _hasMoreUpdates) {
        _loadMoreUpdates();
      }
    }
  }

  void _onTicketsScroll() {
    if (_ticketsScrollController.position.pixels >=
        _ticketsScrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMoreTickets && _hasMoreTickets) {
        _loadMoreTickets();
      }
    }
  }

  Future<void> _loadInboxData() async {
    await Future.wait([
      _loadUpdates(),
      _loadTickets(),
    ]);
  }

  Future<void> _loadUpdates() async {
    setState(() {
      _isLoadingUpdates = true;
      _updatesPage = 1;
      _updates = [];
    });

    try {
      final headers = await ApiService.getHeaders();
      final combined = <Map<String, dynamic>>[];

      // 1) Existing admin notices (no "Visit" button).
      final response = await http.get(
        Uri.parse(ApiService.getApiUrl('admin-notice/?page=$_updatesPage')),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> notifications =
            data is List ? data : (data['results'] ?? []);
        final String? next = data is Map ? data['next'] : null;
        _hasMoreUpdates = next != null;
        combined.addAll(notifications.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'title': item['title'] ?? 'System Notification',
            'message': item['message'] ?? '',
            'isRead': item['is_read'] ?? false,
            'timestamp': DateTime.parse(
                item['created_at'] ?? DateTime.now().toIso8601String()),
            'type': item['notification_type'] ?? 'system',
            'amount': item['amount'],
            'referenceId': item['reference_id'],
            'has_visit': false,
            'deep_link': '',
          };
        }));
      }

      // 2) Saved push notifications — these carry a "Visit" button when they
      //    have a deep link.
      try {
        final pushRes = await AppNotificationService.getNotifications(page: 1);
        for (final AppNotification n
            in (pushRes['items'] as List<AppNotification>)) {
          combined.add({
            'id': 'push_${n.id}',
            'push_id': n.id,
            'title': n.title,
            'message': n.body,
            'isRead': n.isRead,
            'timestamp': n.createdAt ?? DateTime.now(),
            'type': n.notificationType,
            'amount': null,
            'referenceId': null,
            'has_visit': n.hasVisit,
            'deep_link': n.deepLink,
          });
        }
      } catch (e) {
        debugPrint('Error loading push notifications: $e');
      }

      // Newest first across both sources.
      combined.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      if (mounted) {
        setState(() {
          _updates = combined;
          _isLoadingUpdates = false;
        });
        // Persist "seen" for saved push notifications so they don't re-appear as
        // unread after a reload (broadcasts have no per-user read flag of their
        // own — this records a per-user read receipt on the backend).
        _markPushUpdatesSeen();
      }
    } catch (e) {
      debugPrint('Error loading updates: $e');
      if (mounted) {
        setState(() => _isLoadingUpdates = false);
      }
    }
  }

  Future<void> _markPushUpdatesSeen() async {
    final hasUnreadPush =
        _updates.any((u) => u['push_id'] is int && u['isRead'] != true);
    if (!hasUnreadPush) return;
    try {
      await AppNotificationService.markAllRead();
      if (mounted) {
        setState(() {
          for (final u in _updates) {
            if (u['push_id'] is int) u['isRead'] = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error marking push updates seen: $e');
    }
  }

  Future<void> _loadMoreUpdates() async {
    if (_isLoadingMoreUpdates || !_hasMoreUpdates) return;

    setState(() {
      _isLoadingMoreUpdates = true;
      _updatesPage++;
    });

    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse(ApiService.getApiUrl('admin-notice/?page=$_updatesPage')),
        headers: headers,
      );

      debugPrint('=== Load More Updates Page $_updatesPage ===');
      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> notifications =
            data is List ? data : (data['results'] ?? []);
        final String? next = data is Map ? data['next'] : null;

        if (mounted) {
          setState(() {
            _updates.addAll(notifications.map((item) {
              return {
                'id': item['id'],
                'title': item['title'] ?? 'System Notification',
                'message': item['message'] ?? '',
                'isRead': item['is_read'] ?? false,
                'timestamp': DateTime.parse(
                    item['created_at'] ?? DateTime.now().toIso8601String()),
                'type': item['notification_type'] ?? 'system',
                'amount': item['amount'],
                'referenceId': item['reference_id'],
              };
            }).toList());
            _hasMoreUpdates = next != null;
            _isLoadingMoreUpdates = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingMoreUpdates = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading more updates: $e');
      if (mounted) {
        setState(() => _isLoadingMoreUpdates = false);
      }
    }
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoadingTickets = true;
      _ticketsPage = 1;
      _tickets = [];
    });

    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse(ApiService.getApiUrl('tickets/?page=$_ticketsPage')),
        headers: headers,
      );

      debugPrint('=== Load Tickets Page $_ticketsPage ===');
      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> ticketsJson =
            data is List ? data : (data['results'] ?? []);
        final String? next = data is Map ? data['next'] : null;

        if (mounted) {
          setState(() {
            _tickets = ticketsJson
                .map((item) => {
                      'id': item['id'],
                      'title': item['title'] ?? 'Support Ticket',
                      'message': item['message'] ?? '',
                      'status': item['status'] ?? 'open',
                      'isRead': !(item['is_unread'] ?? true),
                      'timestamp': DateTime.parse(item['created_at'] ??
                          DateTime.now().toIso8601String()),
                      'replyCount': item['reply_count'] ?? 0,
                    })
                .toList();
            _hasMoreTickets = next != null;
            _isLoadingTickets = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingTickets = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading tickets: $e');
      if (mounted) {
        setState(() => _isLoadingTickets = false);
      }
    }
  }

  Future<void> _loadMoreTickets() async {
    if (_isLoadingMoreTickets || !_hasMoreTickets) return;

    setState(() {
      _isLoadingMoreTickets = true;
      _ticketsPage++;
    });

    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse(ApiService.getApiUrl('tickets/?page=$_ticketsPage')),
        headers: headers,
      );

      debugPrint('=== Load More Tickets Page $_ticketsPage ===');
      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> ticketsJson =
            data is List ? data : (data['results'] ?? []);
        final String? next = data is Map ? data['next'] : null;

        if (mounted) {
          setState(() {
            _tickets.addAll(ticketsJson
                .map((item) => {
                      'id': item['id'],
                      'title': item['title'] ?? 'Support Ticket',
                      'message': item['message'] ?? '',
                      'status': item['status'] ?? 'open',
                      'isRead': !(item['is_unread'] ?? true),
                      'timestamp': DateTime.parse(item['created_at'] ??
                          DateTime.now().toIso8601String()),
                      'replyCount': item['reply_count'] ?? 0,
                    })
                .toList());
            _hasMoreTickets = next != null;
            _isLoadingMoreTickets = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingMoreTickets = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading more tickets: $e');
      if (mounted) {
        setState(() => _isLoadingMoreTickets = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _updatesScrollController.removeListener(_onUpdatesScroll);
    _ticketsScrollController.removeListener(_onTicketsScroll);
    _updatesScrollController.dispose();
    _ticketsScrollController.dispose();
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

  Future<void> _openNewTicketModal() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTicketScreen(),
      ),
    );

    // Reload tickets if a new ticket was created
    if (result == true) {
      _loadTickets();
    }
  }

  Future<void> _markAllAsRead() async {
    if (_activeTab == 'updates') {
      // Mark all unread updates as read
      final unreadUpdates = _updates.where((u) => !u['isRead']).toList();

      if (unreadUpdates.isEmpty) return;

      // Show loading
      AdsyToast.info(context, 'Marking all as read...');

      try {
        final headers = await ApiService.getHeaders();

        // Saved push notifications (id like "push_4") use the notifications API;
        // admin notices use the admin-notice endpoint. Sending a push id to the
        // admin-notice endpoint silently failed, so they never persisted.
        bool markedPush = false;
        for (var update in unreadUpdates) {
          final pushId = update['push_id'];
          if (pushId is int) {
            if (!markedPush) {
              await AppNotificationService.markAllRead();
              markedPush = true;
            }
          } else {
            await http.post(
              Uri.parse(ApiService.getApiUrl(
                  'admin-notice/${update['id']}/mark-read/')),
              headers: headers,
            );
          }
        }

        // Update UI
        if (mounted) {
          setState(() {
            for (var update in _updates) {
              update['isRead'] = true;
            }
          });

          AdsyToast.success(context, 'All updates marked as read');
        }
      } catch (e) {
        debugPrint('Error marking updates as read: $e');
        if (mounted) {
          AdsyToast.error(context, 'Failed to mark all as read');
        }
      }
    } else {
      // For tickets, just update locally (tickets auto-mark as read when opened)
      setState(() {
        for (var ticket in _tickets) {
          ticket['isRead'] = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Color(0xFF3B82F6).withValues(alpha: 0.02),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
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
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Color(0xFF3B82F6), size: 20),
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
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/chat_icon.png',
                      width: 20,
                      height: 20,
                      color: Colors.white,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.forum_rounded,
                          color: Colors.white,
                          size: 20,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title Section
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AdsyConnect',
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                  // Settings shortcut (top-right).
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: Color(0xFF64748B), size: 20),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/settings'),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      tooltip: 'Settings',
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
              indicatorWeight: 3,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2),
              tabAlignment: TabAlignment.fill,
              isScrollable: false,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/chat_icon.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.chat_bubble_rounded,
                              size: 20);
                        },
                      ),
                      const SizedBox(width: 4),
                      const Text('AdsyConnect'),
                      if (chatsCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          constraints: const BoxConstraints(minWidth: 17),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            borderRadius:
                                BorderRadius.all(Radius.circular(999)),
                          ),
                          child: Text(
                            chatsCount.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
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
                      const Icon(Icons.notifications_rounded, size: 20),
                      const SizedBox(width: 4),
                      const Text('Updates'),
                      if (updatesCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          constraints: const BoxConstraints(minWidth: 17),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            borderRadius:
                                BorderRadius.all(Radius.circular(999)),
                          ),
                          child: Text(
                            updatesCount.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
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
                      const Icon(Icons.support_agent_rounded, size: 20),
                      const SizedBox(width: 4),
                      const Text('Support'),
                      if (supportTicketsCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          constraints: const BoxConstraints(minWidth: 17),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            borderRadius:
                                BorderRadius.all(Radius.circular(999)),
                          ),
                          child: Text(
                            supportTicketsCount.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
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
                          value: _activeTab == 'support'
                              ? _ticketStatusFilter
                              : _updatesFilter,
                          icon: const Icon(Icons.arrow_drop_down_rounded,
                              size: 20),
                          isExpanded: true,
                          isDense: true,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                          items: _activeTab == 'support'
                              ? [
                                  const DropdownMenuItem(
                                      value: 'all', child: Text('All Tickets')),
                                  const DropdownMenuItem(
                                      value: 'open', child: Text('Open')),
                                  const DropdownMenuItem(
                                      value: 'in_progress',
                                      child: Text('In Progress')),
                                  const DropdownMenuItem(
                                      value: 'resolved',
                                      child: Text('Resolved')),
                                  const DropdownMenuItem(
                                      value: 'closed', child: Text('Closed')),
                                ]
                              : [
                                  const DropdownMenuItem(
                                      value: 'all', child: Text('All Updates')),
                                  const DropdownMenuItem(
                                      value: 'order_received',
                                      child: Text('Orders')),
                                  const DropdownMenuItem(
                                      value: 'withdraw_successful',
                                      child: Text('Withdrawals')),
                                  const DropdownMenuItem(
                                      value: 'mobile_recharge_successful',
                                      child: Text('Recharges')),
                                  const DropdownMenuItem(
                                      value: 'pro_subscribed',
                                      child: Text('Pro')),
                                  const DropdownMenuItem(
                                      value: 'pro_expiring',
                                      child: Text('Expiring')),
                                  const DropdownMenuItem(
                                      value: 'gig_posted', child: Text('Gigs')),
                                  const DropdownMenuItem(
                                      value: 'transfer_sent',
                                      child: Text('Transfers Sent')),
                                  const DropdownMenuItem(
                                      value: 'transfer_received',
                                      child: Text('Transfers Received')),
                                  const DropdownMenuItem(
                                      value: 'deposit_successful',
                                      child: Text('Deposits')),
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
                            textStyle: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
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
                          label: const Text('New Ticket'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
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
                AdsyConnectScreen(initialChatId: widget.initialChatId),
                _buildUpdatesList(),
                _buildTicketsList(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _activeTab == 'chat'
          ? FloatingActionButton(
              onPressed: _showNewChatModal,
              backgroundColor: const Color(0xFF3B82F6),
              child: Image.asset(
                'assets/images/chat_icon.png',
                width: 24,
                height: 24,
                color: Colors.white,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.chat_bubble_rounded,
                      color: Colors.white);
                },
              ),
            )
          : null,
    );
  }

  Widget _buildUpdatesList() {
    if (_isLoadingUpdates) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: AdsyLoadingIndicator(),
        ),
      );
    }

    final updates = filteredUpdates;

    if (updates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No updates yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _updatesScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: updates.length + (_isLoadingMoreUpdates ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == updates.length) {
          // Loading skeleton at bottom
          return Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 200,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
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
          child: AdsyLoadingIndicator(),
        ),
      );
    }

    final tickets = filteredTickets;

    if (tickets.isEmpty) {
      return AdsyRefreshIndicator(
        onRefresh: _loadTickets,
        color: const Color(0xFF3B82F6),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildEmptyState('No tickets found'),
          ),
        ),
      );
    }

    return AdsyRefreshIndicator(
      onRefresh: _loadTickets,
      color: const Color(0xFF3B82F6),
      child: ListView.builder(
        controller: _ticketsScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: tickets.length + (_isLoadingMoreTickets ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == tickets.length) {
            // Loading skeleton at bottom
            return Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 200,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          final ticket = tickets[index];
          return _buildTicketItem(ticket);
        },
      ),
    );
  }

  void _visitUpdate(Map<String, dynamic> update) {
    final link = (update['deep_link'] ?? '').toString().trim();
    final pushId = update['push_id'];
    if (pushId is int && update['isRead'] != true) {
      AppNotificationService.markRead(pushId);
      setState(() => update['isRead'] = true);
    }
    if (link.isNotEmpty) {
      DeepLinkService.instance.openInternalLink(link);
    }
  }

  bool _canVisitUpdate(Map<String, dynamic> update) {
    return update['has_visit'] == true &&
        (update['deep_link'] ?? '').toString().trim().isNotEmpty;
  }

  Widget _buildUpdateItem(Map<String, dynamic> update) {
    final bool isUnread = !update['isRead'];

    return InkWell(
      onTap: () {
        _showUpdateDetailsBottomSheet(update);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isUnread
              ? const Color(0xFFF0FDF4).withValues(alpha: 0.5)
              : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFE5E7EB).withValues(alpha: 0.4),
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
                    ? const Color(0xFF059669).withValues(alpha: 0.1)
                    : const Color(0xFFF3F4F6),
                border: Border.all(
                  color: isUnread
                      ? const Color(0xFF059669).withValues(alpha: 0.25)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(
                update['type'] == 'system'
                    ? Icons.settings_rounded
                    : Icons.verified_user_rounded,
                color: isUnread
                    ? const Color(0xFF059669)
                    : const Color(0xFF6B7280),
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
                            fontSize: 15,
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w600,
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
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    update['message'],
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
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
      onTap: () async {
        setState(() {
          ticket['isRead'] = true;
        });

        // Navigate to ticket detail screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailScreen(
              ticketId: ticket['id'].toString(),
            ),
          ),
        );

        // Reload tickets after returning from detail screen
        _loadTickets();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isUnread
              ? const Color(0xFFF0FDF4).withValues(alpha: 0.5)
              : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFE5E7EB).withValues(alpha: 0.4),
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
                color: statusColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.25),
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
                            fontSize: 15,
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: const Color(0xFF1F2937),
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ticket #${ticket['id']}',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3B82F6),
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ticket['message'],
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
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
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
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

  void _showNewChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewChatModal(parentContext: this.context),
    );
  }

  void _showUpdateDetailsBottomSheet(Map<String, dynamic> update) {
    // Mark as read immediately
    _markUpdateAsRead(update);
    final canVisit = _canVisitUpdate(update);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      update['type'] == 'system'
                          ? Icons.settings_rounded
                          : Icons.verified_user_rounded,
                      color: const Color(0xFF059669),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          update['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(update['timestamp']),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message
                    Text(
                      update['message'],
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.6,
                        color: Color(0xFF374151),
                      ),
                    ),

                    // Additional details if available
                    if (update['referenceId'] != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reference ID',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    update['referenceId'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  if (canVisit) ...[
                    // Secondary action — a tonal blue "Visit" that reads as a
                    // clear link-out without competing with the primary button.
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _visitUpdate(update);
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Visit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            backgroundColor: const Color(0xFFEFF6FF),
                            side: const BorderSide(
                              color: Color(0xFFBFDBFE),
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Primary action — solid green with a soft glow so it stands
                  // out as the main "dismiss / acknowledge" control.
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF059669).withValues(alpha: 0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon:
                              const Icon(Icons.check_circle_rounded, size: 19),
                          label: const Text('Got it'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markUpdateAsRead(Map<String, dynamic> update) async {
    // Update UI immediately
    setState(() {
      update['isRead'] = true;
    });

    // Mark as read via API
    try {
      final headers = await ApiService.getHeaders();
      await http.post(
        Uri.parse(
            ApiService.getApiUrl('admin-notice/${update['id']}/mark-read/')),
        headers: headers,
      );
    } catch (e) {
      debugPrint('Error marking update as read: $e');
    }
  }
}

class _NewChatModal extends StatefulWidget {
  final BuildContext parentContext;

  const _NewChatModal({required this.parentContext});

  @override
  State<_NewChatModal> createState() => _NewChatModalState();
}

class _NewChatModalState extends State<_NewChatModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String? _getUserImageUrl(Map<String, dynamic> user) {
    // Check for image field (backend returns this)
    final imageUrl =
        user['image']?.toString() ?? user['profile_picture']?.toString();
    if (imageUrl == null || imageUrl.isEmpty) return null;

    // Convert to absolute URL using AppConfig
    return AppConfig.getAbsoluteUrl(imageUrl);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPeople(query);
    });
  }

  Future<void> _searchPeople(String query) async {
    try {
      final token = await AuthService.getValidToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final params = {
        'q': query,
        'page_size': '10',
        // You can't chat with yourself — don't offer yourself in the picker.
        'exclude_self': '1',
      };

      final uri = Uri.parse('${ApiService.baseUrl}/bn/users/search/').replace(
        queryParameters: params,
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final List<Map<String, dynamic>> results = [];
        final selfId = AuthService.currentUser?.id ?? '';

        if (data['results'] != null && data['results'] is List) {
          for (var item in data['results']) {
            final user = Map<String, dynamic>.from(item);
            // Client-side guard too, for older servers.
            if (selfId.isNotEmpty && user['id'].toString() == selfId) continue;
            results.add(user);
          }
        }

        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching people: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _openChatWithUser(Map<String, dynamic> user) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: AdsyLoadingIndicator(),
        ),
      );

      // Get or create chatroom
      final chatroom = await AdsyConnectService.getOrCreateChatRoom(
        user['id'].toString(),
      );

      // Close loading
      if (mounted) Navigator.pop(context);
      // Close search modal
      if (mounted) Navigator.pop(context);

      // Open chat (stack-deduplicated)
      if (widget.parentContext.mounted) {
        AdsyConnectChatInterface.open(
          widget.parentContext,
          chatroomId: chatroom['id'].toString(),
          userId: user['id'].toString(),
          userName: user['first_name'] != null && user['last_name'] != null
              ? '${user['first_name']} ${user['last_name']}'
              : user['username'] ?? 'User',
          userAvatar: user['profile_picture'],
          profession: user['profession'],
          isOnline: false,
        );
      }
    } catch (e) {
      // Close loading if still open
      if (mounted) Navigator.pop(context);

      if (mounted) {
        // AdsyChatException carries a clean user-facing (Bangla) message;
        // anything else gets a generic line — never raw backend output.
        final message = e is AdsyChatException
            ? e.message
            : 'চ্যাট খোলা যায়নি, একটু পরে আবার চেষ্টা করুন।';
        AdsyToast.error(context, message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Compact header with search
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'New Chat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Compact search bar
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Icon(
                          Icons.search_rounded,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          autofocus: true,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search people...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: Colors.grey.shade400,
                            size: 16,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults.clear();
                              _isSearching = false;
                            });
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Results
          Expanded(
            child: _isSearching
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: AdsyLoadingIndicator(strokeWidth: 2),
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchController.text.isEmpty
                                  ? Icons.people_outline_rounded
                                  : Icons.search_off_rounded,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Search for people to start chatting'
                                  : 'No results found',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _searchResults.length,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey.shade100,
                        ),
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final userName = user['first_name'] != null &&
                                  user['last_name'] != null
                              ? '${user['first_name']} ${user['last_name']}'
                              : user['username'] ?? 'User';
                          final userInitial = (user['first_name']?[0] ??
                                  user['username']?[0] ??
                                  'U')
                              .toUpperCase();

                          return InkWell(
                            onTap: () => _openChatWithUser(user),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 4),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFF3B82F6)
                                        .withValues(alpha: 0.1),
                                    backgroundImage: _getUserImageUrl(user) !=
                                            null
                                        ? NetworkImage(_getUserImageUrl(user)!)
                                        : null,
                                    child: _getUserImageUrl(user) == null
                                        ? Text(
                                            userInitial,
                                            style: const TextStyle(
                                              color: Color(0xFF3B82F6),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  // Name and profession
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                userName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1F2937),
                                                  letterSpacing: -0.2,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // Verified badge — same source
                                            // the feed uses (kyc).
                                            if (user['kyc'] == true ||
                                                user['is_verified'] ==
                                                    true) ...[
                                              const SizedBox(width: 4),
                                              const Icon(Icons.verified,
                                                  size: 15,
                                                  color: Color(0xFF3B82F6)),
                                            ],
                                            // Pro pill — same as the feed.
                                            if (user['is_pro'] == true) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF3B82F6),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  'Pro',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (user['profession'] != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            user['profession'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Chat icon
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6)
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.asset(
                                      'assets/images/chat_icon.png',
                                      width: 16,
                                      height: 16,
                                      color: const Color(0xFF3B82F6),
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          color: const Color(0xFF3B82F6),
                                          size: 16,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
