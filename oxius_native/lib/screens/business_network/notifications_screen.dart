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
  bool _isRefreshing = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadNotifications(isInitial: true);
  }

  Future<void> _loadNotifications({bool isInitial = false}) async {
    print('📱 Loading notifications... isInitial: $isInitial');
    
    // Only show loading indicator on initial load
    if (isInitial) {
      setState(() => _isLoading = true);
    } else {
      _isRefreshing = true;
    }
    
    try {
      final result = await NotificationService.getNotifications(page: 1);
      print('📱 Got result from service: ${result['notifications']?.length} notifications');
      
      if (mounted) {
        final notifications = result['notifications'];
        print('📱 Notifications type: ${notifications.runtimeType}');
        print('📱 Notifications value: $notifications');
        
        setState(() {
          if (notifications is List<NotificationModel>) {
            _notifications = notifications;
          } else if (notifications is List) {
            _notifications = List<NotificationModel>.from(notifications);
          } else {
            _notifications = [];
          }
          
          _hasMore = result['hasMore'] ?? false;
          _unreadCount = result['unreadCount'] ?? 0;
          _currentPage = 1;
          _isLoading = false;
        });
        
        print('📱 State updated: ${_notifications.length} notifications, $_unreadCount unread, loading: $_isLoading');
        print('📱 Notifications list: $_notifications');
        
        // Show success message only when manually refreshing
        if (!isInitial && _isRefreshing) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Refreshed ${_notifications.length} notification${_notifications.length != 1 ? 's' : ''}'),
                ],
              ),
              backgroundColor: const Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
        _isRefreshing = false;
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        if (!isInitial) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('Failed to refresh notifications'),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
        _isRefreshing = false;
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

    // Navigate based on notification type (matching Vue implementation)
    switch (notification.type) {
      case NotificationType.follow:
        // Navigate to user profile
        if (notification.actor != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(
                userId: notification.actor!.id.toString(),
              ),
            ),
          );
        }
        break;
        
      case NotificationType.likePost:
      case NotificationType.comment:
      case NotificationType.mention:
        // Navigate to post detail
        if (notification.targetId != null) {
          Navigator.pushNamed(
            context,
            '/business-network/post/${notification.targetId}',
          );
        }
        break;
        
      case NotificationType.likeComment:
      case NotificationType.reply:
        // Navigate to post detail using parent_id
        if (notification.parentId != null) {
          Navigator.pushNamed(
            context,
            '/business-network/post/${notification.parentId}',
          );
        }
        break;
        
      case NotificationType.solution:
        // Navigate to MindForce post
        if (notification.targetId != null) {
          Navigator.pushNamed(
            context,
            '/business-network/mindforce/${notification.targetId}',
          );
        }
        break;
        
      case NotificationType.giftDiamonds:
        // Navigate to post detail for gift diamonds
        if (notification.targetId != null) {
          Navigator.pushNamed(
            context,
            '/business-network/post/${notification.targetId}',
          );
        }
        break;
        
      default:
        // Default to business network home
        Navigator.pushNamed(context, '/business-network');
    }
  }

  void _handleNavTap(int index) {
    switch (index) {
      case 0:
        // Recent - Navigate to business network feed
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/business-network',
          (route) => route.settings.name == '/',
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: currentUser.id),
            ),
          );
        } else {
          Navigator.pushNamed(context, '/login');
        }
        break;
      case 4:
        // AdsyClub/Home - Navigate to main home screen
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
      body: Column(
        children: [
          // Compact Professional Header
          Container(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 2),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (_unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Container(
              color: const Color(0xFFF9FAFB),
              child: Builder(
                builder: (context) {
                  print('📱 Building content: isLoading=$_isLoading, count=${_notifications.length}, isEmpty=${_notifications.isEmpty}');
                  
                  if (_isLoading) {
                    return _buildLoadingState();
                  } else if (_notifications.isEmpty) {
                    return _buildEmptyState();
                  } else {
                    return _buildNotificationsList();
                  }
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? BusinessNetworkBottomNavBar(
              currentIndex: 1, // Notifications tab
              isLoggedIn: AuthService.isAuthenticated,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF3B82F6).withOpacity(0.1), const Color(0xFF6366F1).withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF3B82F6),
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 40,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withOpacity(0.1),
                          const Color(0xFF6366F1).withOpacity(0.15),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 56,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'When someone interacts with your\ncontent or mentions you, you\'ll see it here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swipe_down_rounded,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pull down to refresh',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 40,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        itemCount: _notifications.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return _buildLoadMoreButton();
          }
          
          final notification = _notifications[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            child: NotificationItem(
              notification: notification,
              onTap: () => _handleNotificationTap(notification),
              onMarkAsRead: () => _markAsRead(notification.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Center(
        child: _isLoadingMore
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF3B82F6).withOpacity(0.1), const Color(0xFF6366F1).withOpacity(0.1)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : TextButton.icon(
                onPressed: _loadMoreNotifications,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                icon: const Icon(Icons.expand_more_rounded, size: 18),
                label: const Text(
                  'Load More',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}
