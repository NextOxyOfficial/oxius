import 'package:flutter/material.dart';
import 'adsy_connect_chat_interface.dart';
import '../services/adsyconnect_service.dart';

class AdsyConnectScreen extends StatefulWidget {
  const AdsyConnectScreen({super.key});

  @override
  State<AdsyConnectScreen> createState() => _AdsyConnectScreenState();
}

class _AdsyConnectScreenState extends State<AdsyConnectScreen> {
  bool _isLoadingChats = true;
  List<Map<String, dynamic>> _chatConversations = [];
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoadingChats = true;
        _currentPage = 1;
      });
    }
    
    try {
      print('🔵 Loading chat rooms, page: $_currentPage');
      final chatRooms = await AdsyConnectService.getChatRooms(page: _currentPage);
      print('🟢 Loaded ${chatRooms.length} chat rooms');
      
      if (mounted) {
        setState(() {
          if (loadMore) {
            _chatConversations.addAll(_parseChatRooms(chatRooms));
          } else {
            _chatConversations = _parseChatRooms(chatRooms);
          }
          _isLoadingChats = false;
          _hasMore = chatRooms.length >= 20;
          if (loadMore) _currentPage++;
        });
      }
    } catch (e) {
      print('🔴 Error loading chats: $e');
      if (mounted) {
        setState(() {
          _isLoadingChats = false;
          _chatConversations = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load chats: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _parseChatRooms(List<dynamic> chatRooms) {
    return chatRooms.map((room) {
      final otherUser = room['other_user'] ?? {};
      final lastMessage = room['last_message'];
      
      return {
        'id': room['id'],
        'userId': otherUser['id']?.toString() ?? '',
        'userName': _getFullName(otherUser),
        'userAvatar': otherUser['avatar'],
        'profession': otherUser['profession'] ?? '',
        'lastMessage': lastMessage?['content'] ?? room['last_message_preview'] ?? '',
        'timestamp': lastMessage?['created_at'] != null 
            ? DateTime.parse(lastMessage['created_at'])
            : DateTime.parse(room['last_message_at'] ?? DateTime.now().toIso8601String()),
        'unreadCount': room['unread_count'] ?? 0,
        'isOnline': otherUser['is_online'] ?? false,
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
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3B82F6),
        ),
      );
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
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 48,
                  color: Color(0xFF3B82F6),
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

    return RefreshIndicator(
      onRefresh: _refreshChats,
      color: const Color(0xFF3B82F6),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            _loadMoreChats();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          itemCount: _chatConversations.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _chatConversations.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  ),
                ),
              );
            }
            final chat = _chatConversations[index];
            return _buildChatItem(chat);
          },
        ),
      ),
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
                  width: 42,
                  height: 42,
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
                    child: chat['userAvatar'] != null
                        ? Image.network(
                            chat['userAvatar'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  chat['userName'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF3B82F6),
                                    fontSize: 16,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
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
                                  fontSize: 13,
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
                          fontSize: 9,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    chat['profession'] ?? 'Professional',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                      letterSpacing: -0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat['lastMessage'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                      color: hasUnread ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
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
