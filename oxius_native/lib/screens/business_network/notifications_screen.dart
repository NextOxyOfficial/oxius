import 'package:flutter/material.dart';
import '../../models/notification_models.dart';
import '../../services/notification_service.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import '../../widgets/business_network/business_network_header.dart';
import '../../widgets/business_network/business_network_drawer.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import '../../widgets/notifications/notification_item.dart';
import '../business_network/profile_screen.dart';
import '../business_network/post_detail_screen.dart';
import '../business_network/create_post_screen.dart';
import 'profile_options.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications(isInitial: true);
    _markAllNotificationsAsRead();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Infinite scroll: load the next page as the list nears the bottom.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 320 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreNotifications();
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    // Mark all as read after a short delay to let user see the count
    await Future.delayed(const Duration(milliseconds: 800));
    final success = await NotificationService.markAllAsRead();
    if (success && mounted) {
      // Reload to update UI
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications({bool isInitial = false}) async {
    debugPrint('📱 Loading notifications... isInitial: $isInitial');

    // Only show loading indicator on initial load
    if (isInitial) {
      setState(() => _isLoading = true);
    } else {}

    try {
      final result = await NotificationService.getNotifications(page: 1);
      debugPrint(
          '📱 Got result from service: ${result['notifications']?.length} notifications');

      if (mounted) {
        final notifications = result['notifications'];
        debugPrint('📱 Notifications type: ${notifications.runtimeType}');
        debugPrint('📱 Notifications value: $notifications');

        debugPrint('📱 Raw notifications from result: $notifications');
        debugPrint(
            '📱 Notifications is List<NotificationModel>: ${notifications is List<NotificationModel>}');
        debugPrint('📱 Notifications is List: ${notifications is List}');

        setState(() {
          if (notifications is List<NotificationModel>) {
            debugPrint('📱 Case 1: Direct assignment');
            _notifications = notifications;
          } else if (notifications is List) {
            debugPrint(
                '📱 Case 2: Converting list - length: ${notifications.length}');
            _notifications = List<NotificationModel>.from(notifications);
            debugPrint('📱 After conversion: ${_notifications.length}');
          } else {
            debugPrint(
                '📱 Case 3: Empty - notifications is: ${notifications.runtimeType}');
            _notifications = [];
          }

          _hasMore = result['hasMore'] ?? false;
          _unreadCount = result['unreadCount'] ?? 0;
          _currentPage = 1;
          _isLoading = false;
        });

        debugPrint(
            '📱 State updated: ${_notifications.length} notifications, $_unreadCount unread, loading: $_isLoading');
        debugPrint(
            '📱 First notification: ${_notifications.isNotEmpty ? _notifications.first : 'none'}');
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        if (!isInitial) {
          AdsyToast.error(context, 'Failed to refresh notifications');
        }
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
      case NotificationType.share:
        // Navigate to post detail
        if (notification.targetId != null) {
          final postId = int.tryParse(notification.targetId.toString());
          if (postId != null) {
            _navigateToPost(postId);
          }
        }
        break;

      case NotificationType.likeComment:
      case NotificationType.reply:
        // Navigate to post detail using parent_id
        if (notification.parentId != null) {
          final postId = int.tryParse(notification.parentId.toString());
          if (postId != null) {
            _navigateToPost(postId);
          }
        }
        break;

      case NotificationType.solution:
        // Navigate to MindForce post detail
        if (notification.targetId != null) {
          final postId = int.tryParse(notification.targetId.toString());
          if (postId != null) {
            _navigateToPost(postId);
          }
        }
        break;

      case NotificationType.giftDiamonds:
        // Navigate to post detail for gift diamonds
        if (notification.targetId != null) {
          final postId = int.tryParse(notification.targetId.toString());
          if (postId != null) {
            _navigateToPost(postId);
          }
        }
        break;

      default:
        // Default to business network home
        final rootNavigator =
            FCMService.navigatorKey.currentState ?? Navigator.of(context);
        rootNavigator.pushNamed('/business-network');
    }
  }

  Future<void> _navigateToPost(int postId) async {
    try {
      // Show skeleton loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Skeleton header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 10,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Skeleton content lines
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Fetch the post
      final post = await BusinessNetworkService.getPost(postId);

      // Close loading indicator
      if (mounted) {
        Navigator.pop(context);

        // Check if post was fetched successfully
        if (post != null) {
          // Navigate to post detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: post),
            ),
          );
        } else {
          // Show error if post is null
          AdsyToast.error(context, 'Post not found');
        }
      }
    } catch (e) {
      debugPrint('Error fetching post: $e');

      // Close loading indicator
      if (mounted) {
        Navigator.pop(context);

        // Show error message
        AdsyToast.error(context, 'পোস্ট লোড করা যায়নি');
      }
    }
  }

  void _handleNavTap(int index) {
    final rootNavigator =
        FCMService.navigatorKey.currentState ?? Navigator.of(context);

    switch (index) {
      case 0:
        // Recent - Navigate to business network feed
        rootNavigator.pushNamedAndRemoveUntil(
          '/business-network',
          (route) => route.isFirst,
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
        // Profile — the footer opens the profile page itself (the header
        // avatar opens the profile options screen).
        if (AuthService.isAuthenticated) {
          final currentUser = AuthService.currentUser;
          if (currentUser != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: currentUser.id),
              ),
            );
          }
        } else {
          Navigator.pushNamed(context, '/login');
        }
        break;
      case 4:
        // AdsyClub/Home - Navigate to main home screen
        rootNavigator.pushNamedAndRemoveUntil('/', (route) => false);
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
        showFlares: false,
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
        // Header avatar → profile OPTIONS, same as the Business Network feed.
        onProfileTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileOptionsScreen(),
            ),
          );
        },
      ),
      drawer: isMobile
          ? const BusinessNetworkDrawer(
              currentRoute: '/business-network/notifications')
          : null,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                  debugPrint(
                      '📱 Building content: isLoading=$_isLoading, count=${_notifications.length}, isEmpty=${_notifications.isEmpty}');

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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8, // Show 8 skeleton items
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar skeleton
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Content skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name line
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Content line 1
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Content line 2 (shorter)
                    Container(
                      height: 12,
                      width: MediaQuery.of(context).size.width * 0.6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Time line
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return AdsyRefreshIndicator(
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
                          const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          const Color(0xFF6366F1).withValues(alpha: 0.15),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    return AdsyRefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF3B82F6),
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 40,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        // A trailing spinner row appears only while the next page loads.
        itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: AdsyLoadingIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  ),
                ),
              ),
            );
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
}
