import 'package:flutter/material.dart';
import '../../models/notification_models.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/business_network/business_network_header.dart';
import '../../widgets/business_network/business_network_drawer.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import '../../widgets/notifications/notification_item.dart';
import '../business_network/profile_screen.dart';
import '../business_network/post_detail_screen.dart';
import '../business_network/create_post_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  int _unreadCount = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('Loading notifications...');
      final result = await NotificationService.getNotifications(page: 1);
      print('Notifications loaded: ${result['notifications']?.length ?? 0}');
      
      if (mounted) {
        setState(() {
          _notifications = result['notifications'] ?? [];
          _hasMore = result['hasMore'] ?? false;
          _unreadCount = result['unreadCount'] ?? 0;
          _currentPage = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _notifications = [];
        });
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() => _isLoadingMore = true);
    
    final nextPage = _currentPage + 1;
    final result = await NotificationService.getNotifications(page: nextPage);
    
    if (mounted) {
      setState(() {
        _notifications.addAll(result['notifications']);
        _hasMore = result['hasMore'];
        _currentPage = nextPage;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    final success = await NotificationService.markAsRead(notificationId);
    
    if (success && mounted) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(read: true);
          if (_unreadCount > 0) _unreadCount--;
        }
      });
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    if (!notification.read) {
      _markAsRead(notification.id);
    }

    // Navigate based on notification type
    if (notification.targetType == 'post' && notification.targetId != null) {
      // Navigate to post detail
      // Navigator.push(context, MaterialPageRoute(...));
    } else if (notification.type == NotificationType.follow && notification.actor != null) {
      // Navigate to user profile
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            userId: notification.actor!.id.toString(),
          ),
        ),
      );
    }
  }

  void _handleNavTap(int index) {
    switch (index) {
      case 0:
        // Recent - Navigate to business network feed
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/business-network',
          (route) => false,
        );
        break;
      case 1:
        // Notifications - already here, do nothing
        break;
      case 2:
        // Create Post
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreatePostScreen(),
          ),
        );
        break;
      case 3:
        // Profile
        final currentUser = AuthService.currentUser;
        if (currentUser != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: currentUser.id),
            ),
          );
        }
        break;
      case 4:
        // AdsyClub/Home
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: BusinessNetworkHeader(
        onMenuTap: () {
          if (isMobile) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scaffoldKey.currentState != null) {
                _scaffoldKey.currentState!.openDrawer();
              }
            });
          }
        },
        onSearchTap: () {
          // TODO: Implement search
        },
        onQRCodeTap: () {
          // TODO: Show QR code modal
        },
        onProfileTap: () {
          final user = AuthService.currentUser;
          if (user != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: user.id),
              ),
            );
          }
        },
      ),
      drawer: isMobile ? const BusinessNetworkDrawer(currentRoute: '/business-network/notifications') : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'All Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade500,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _notifications.isEmpty
                        ? _buildEmptyState()
                        : _buildNotificationsList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isMobile
          ? BusinessNetworkBottomNavBar(
              currentIndex: 1, // Notifications tab
              onTap: _handleNavTap,
              unreadCount: _unreadCount,
            )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              color: Colors.grey.shade600,
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 48,
              color: Colors.blue.shade500,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When someone interacts with your content\nor mentions you, you\'ll see it here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF3B82F6),
      child: ListView.builder(
        itemCount: _notifications.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return _buildLoadMoreButton();
          }
          
          final notification = _notifications[index];
          return NotificationItem(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onMarkAsRead: () => _markAsRead(notification.id),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              )
            : ElevatedButton(
                onPressed: _loadMoreNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade500,
                  side: BorderSide(color: Colors.blue.shade200),
                  elevation: 0,
                ),
                child: const Text('Load more'),
              ),
      ),
    );
  }
}
