import 'package:flutter/material.dart';
import 'dart:async';
import 'adsy_connect_chat_interface.dart';
import '../services/adsyconnect_service.dart';
import '../widgets/chat_list_skeleton.dart';
import '../config/app_config.dart';
import '../utils/network_error_handler.dart';

class AdsyConnectScreen extends StatefulWidget {
  const AdsyConnectScreen({super.key});

  @override
  State<AdsyConnectScreen> createState() => _AdsyConnectScreenState();
}

class _AdsyConnectScreenState extends State<AdsyConnectScreen> {
  bool _isLoadingChats = true;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _chatConversations = [];
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _pollingTimer;
  Timer? _onlineStatusTimer;

  final TextEditingController _chatSearchController = TextEditingController();
  String _chatSearchQuery = '';

  static const int _pageSize = 20;

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadChats();
    _startRealTimePolling();
    _startOnlineStatusPolling();
    _chatSearchController.addListener(_onChatSearchChanged);
  }

  void _onChatSearchChanged() {
    final next = _chatSearchController.text;
    if (next == _chatSearchQuery) return;
    if (!mounted) return;
    setState(() {
      _chatSearchQuery = next;
    });
  }

  void _startOnlineStatusPolling() {
    _onlineStatusTimer?.cancel();
    _onlineStatusTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _refreshOnlineStatuses();
    });
  }

  Future<void> _refreshOnlineStatuses() async {
    try {
      if (!mounted) return;
      if (_chatConversations.isEmpty) return;

      final userIds = _chatConversations
          .map((c) => (c['userId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (userIds.isEmpty) return;

      final statuses = await AdsyConnectService.getOnlineStatusList(userIds);
      if (!mounted) return;
      if (statuses.isEmpty) return;

      final Map<String, Map<String, dynamic>> statusByUserId = {};
      for (final item in statuses) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final id = (map['user_id'] ?? map['userId'] ?? map['id'])?.toString();
          if (id != null && id.isNotEmpty) {
            statusByUserId[id] = map;
          }
        }
      }

      if (statusByUserId.isEmpty) return;

      setState(() {
        for (var i = 0; i < _chatConversations.length; i++) {
          final uid = (_chatConversations[i]['userId'] ?? '').toString();
          final status = statusByUserId[uid];
          if (status == null) continue;

          final isOnline = _parseBool(status['is_online'] ?? status['isOnline']);
          _chatConversations[i]['isOnline'] = isOnline;
        }
      });
    } catch (_) {}
  }

  void _startRealTimePolling() {
    // Poll for new messages every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _refreshChatsInBackground();
      }
    });
  }

  Future<void> _refreshChatsInBackground() async {
    try {
      final chatRooms = await AdsyConnectService.getChatRooms(page: 1, pageSize: _pageSize);
      
      if (mounted) {
        setState(() {
          // Only update the first page to refresh unread counts
          final newChats = _parseChatRooms(chatRooms);
          
          // Update existing chats with new data
          for (var newChat in newChats) {
            final index = _chatConversations.indexWhere((c) => c['id'] == newChat['id']);
            if (index != -1) {
              final existingOnline = _chatConversations[index]['isOnline'];
              _chatConversations[index] = newChat;
              if (existingOnline != null) {
                _chatConversations[index]['isOnline'] = existingOnline;
              }
            } else {
              // New chat arrived, add it to the top
              _chatConversations.insert(0, newChat);
            }
          }
        });
      }
    } catch (e) {
      print('🔴 Error refreshing chats in background: $e');
      // Silent fail - don't show error to user
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _onlineStatusTimer?.cancel();
    _chatSearchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredChats {
    final q = _chatSearchQuery.trim().toLowerCase();
    if (q.isEmpty) return _chatConversations;

    return _chatConversations.where((chat) {
      final name = (chat['userName'] ?? '').toString().toLowerCase();
      final msg = (chat['lastMessage'] ?? '').toString().toLowerCase();
      return name.contains(q) || msg.contains(q);
    }).toList();
  }

  Future<void> _loadChats({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoadingChats = true;
        _currentPage = 1;
      });
    } else {
      // Prevent multiple simultaneous loads
      if (_isLoadingMore || !_hasMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    }
    
    try {
      final pageToLoad = loadMore ? _currentPage + 1 : 1;
      print('🔵 Loading chat rooms, page: $pageToLoad');
      final chatRooms = await AdsyConnectService.getChatRooms(page: pageToLoad, pageSize: _pageSize);
      print('🟢 Loaded ${chatRooms.length} chat rooms');
      
      if (mounted) {
        final newChats = _parseChatRooms(chatRooms);
        
        setState(() {
          if (loadMore) {
            // Get existing chat IDs to prevent duplicates
            final existingIds = _chatConversations.map((c) => c['id']).toSet();
            
            // Only add chats that don't already exist
            final uniqueNewChats = newChats.where((chat) => !existingIds.contains(chat['id'])).toList();
            
            print('📊 Adding ${uniqueNewChats.length} unique chats (filtered ${newChats.length - uniqueNewChats.length} duplicates)');
            _chatConversations.addAll(uniqueNewChats);
            
            // Move to the page we just successfully loaded
            _currentPage = pageToLoad;
          } else {
            _chatConversations = newChats;
            _currentPage = 1;
          }
          
          _isLoadingChats = false;
          _isLoadingMore = false;
          _hasMore = chatRooms.length >= _pageSize;
        });

        if (!loadMore) {
          _refreshOnlineStatuses();
        }
      }
    } catch (e) {
      print('🔴 Error loading chats: $e');
      if (mounted) {
        setState(() {
          _isLoadingChats = false;
          _isLoadingMore = false;
        });

        final customMessage = NetworkErrorHandler.isNetworkError(e)
            ? null
            : (loadMore ? 'Failed to load more chats' : 'Failed to load chats');

        NetworkErrorHandler.showErrorSnackbar(
          context,
          e,
          customMessage: customMessage,
          onRetry: () => _loadChats(loadMore: loadMore),
        );
      }
    }
  }

  List<Map<String, dynamic>> _parseChatRooms(List<dynamic> chatRooms) {
    return chatRooms
        .where((room) {
          // Filter out chats with no messages
          final lastMessage = room['last_message'];
          final lastMessagePreview = room['last_message_preview'];
          
          // Include chats that have:
          // 1. A last message (even if deleted)
          // 2. OR a last message preview
          return (lastMessage != null) ||
                 (lastMessagePreview != null && lastMessagePreview.toString().isNotEmpty);
        })
        .map((room) {
          final otherUser = room['other_user'] ?? {};
          final lastMessage = room['last_message'];
          
          // Check if last message is deleted
          final isDeleted = lastMessage?['is_deleted'] == true;
          final messageContent = lastMessage?['content']?.toString() ?? room['last_message_preview']?.toString() ?? '';
          
          // Show "Message removed" if deleted OR if content says "Message deleted"
          String displayMessage;
          if (isDeleted || messageContent == 'Message deleted') {
            displayMessage = 'Message removed';
          } else if (messageContent.isEmpty) {
            displayMessage = 'No messages yet';
          } else {
            displayMessage = messageContent;
          }
          
          return {
            'id': room['id'],
            'userId': otherUser['id']?.toString() ?? '',
            'userName': _getFullName(otherUser),
            'userAvatar': otherUser['avatar'],
            'profession': otherUser['profession'] ?? '',
            'lastMessage': displayMessage,
            'timestamp': lastMessage?['created_at'] != null 
                ? DateTime.parse(lastMessage['created_at'])
                : DateTime.parse(room['last_message_at'] ?? DateTime.now().toIso8601String()),
            'unreadCount': room['unread_count'] ?? 0,
            'isOnline': _parseBool(otherUser['is_online'] ?? otherUser['isOnline']),
            'isTyping': false,
            'isVerified': otherUser['is_verified'] ?? false,
          };
        }).toList();
  }

  String _getFullName(Map<String, dynamic> user) {
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final username = user['username'] ?? 'User';
    
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    }
    return username;
  }

  Future<void> _refreshChats() async {
    await _loadChats();
  }

  void _loadMoreChats() {
    if (!_isLoadingChats && _hasMore) {
      _loadChats(loadMore: true);
    }
  }

  void _openChat(Map<String, dynamic> chat) async {
    try {
      await AdsyConnectService.markChatroomAsRead(chat['id']);
    } catch (e) {
      print('Error marking chatroom as read: $e');
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdsyConnectChatInterface(
            chatroomId: chat['id'],
            userId: chat['userId'],
            userName: chat['userName'],
            userAvatar: chat['userAvatar'],
            profession: chat['profession'],
            isOnline: chat['isOnline'],
          ),
        ),
      ).then((_) => _refreshChats());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingChats && _chatConversations.isEmpty) {
      return const ChatListSkeleton();
    }

    if (_chatConversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/chat_icon.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 48,
                      color: Color(0xFF3B82F6),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No conversations yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start chatting with other users',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final chatsToShow = _filteredChats;
    final isFiltering = _chatSearchQuery.trim().isNotEmpty;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: _chatSearchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20),
                    hintText: 'Search chats',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: chatsToShow.isEmpty && isFiltering
                  ? Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshChats,
                      color: const Color(0xFF3B82F6),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (!isFiltering &&
                              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                            _loadMoreChats();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          itemCount: chatsToShow.length + (isFiltering ? 0 : 1),
                          itemBuilder: (context, index) {
                            if (!isFiltering && index == chatsToShow.length) {
                              if (_isLoadingMore) {
                                return const ChatListSkeleton(itemCount: 3);
                              } else if (!_hasMore && chatsToShow.isNotEmpty) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF3B82F6),
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'All chats loaded',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF6B7280),
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'You\'re all caught up!',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }

                            final chat = chatsToShow[index];
                            return _buildChatItem(chat);
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
        // Floating Action Button for New Chat
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () {
              // TODO: Navigate to user search/select screen to start new chat
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search for users in Business Network to start chatting'),
                  backgroundColor: Color(0xFF3B82F6),
                ),
              );
            },
            backgroundColor: const Color(0xFF3B82F6),
            child: Image.asset(
              'assets/images/chat_icon.png',
              width: 24,
              height: 24,
              color: Colors.white,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.chat_bubble_outline, color: Colors.white);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final bool hasUnread = chat['unreadCount'] > 0;
    final bool isOnline = chat['isOnline'] ?? false;
    final bool isTyping = chat['isTyping'] ?? false;

    return InkWell(
      onTap: () => _openChat(chat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: hasUnread ? const Color(0xFF3B82F6).withOpacity(0.02) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFE5E7EB).withOpacity(0.4),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.08),
                        const Color(0xFF6366F1).withOpacity(0.08),
                      ],
                    ),
                    border: Border.all(
                      color: hasUnread ? const Color(0xFF3B82F6).withOpacity(0.25) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: chat['userAvatar'] != null &&
                            AppConfig.getAbsoluteUrl(chat['userAvatar']).isNotEmpty
                        ? Image.network(
                            AppConfig.getAbsoluteUrl(chat['userAvatar']),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  chat['userName'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF3B82F6),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              chat['userName'][0].toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isOnline ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: isOnline ? [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ] : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                chat['userName'],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                  color: const Color(0xFF1F2937),
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isTyping) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'typing',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(chat['timestamp']),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  // Only show profession if it exists and is not empty
                  if (chat['profession'] != null && chat['profession'].toString().isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      chat['profession'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                        letterSpacing: -0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    chat['lastMessage'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                      color: hasUnread ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Unread badge
            if (hasUnread)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  chat['unreadCount'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
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
