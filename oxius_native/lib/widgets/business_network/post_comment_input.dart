import 'package:flutter/material.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import '../../services/auth_service.dart';
import '../../services/user_search_service.dart';
import '../../utils/mention_parser.dart';
import '../../widgets/login_prompt_dialog.dart';
import 'diamond_gift_bottom_sheet.dart';
import '../../config/app_config.dart';

class PostCommentInput extends StatefulWidget {
  final Function(String) onSubmit;
  final String? userAvatar;
  final String postId;
  final String postAuthorId;
  final String postAuthorName;
  final VoidCallback? onGiftSent;

  const PostCommentInput({
    super.key,
    required this.onSubmit,
    this.userAvatar,
    required this.postId,
    required this.postAuthorId,
    required this.postAuthorName,
    this.onGiftSent,
  });

  @override
  State<PostCommentInput> createState() => _PostCommentInputState();
}

class _PostCommentInputState extends State<PostCommentInput> {
  final GlobalKey<FlutterMentionsState> _mentionKey = GlobalKey<FlutterMentionsState>();
  
  bool _isSubmitting = false;
  bool _hasText = false;
  String _commentText = '';
  List<Map<String, dynamic>> _userData = [];

  @override
  void initState() {
    super.initState();
    _loadInitialUsers();
  }

  Future<void> _loadInitialUsers() async {
    // Load some initial users for the mention list
    final users = await _searchUsers('');
    if (mounted) {
      setState(() {
        _userData = users;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final controller = _mentionKey.currentState?.controller;
    final plainText = controller?.text ?? '';
    if (plainText.trim().isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final markup = controller?.markupText ?? '';
      // Convert markup -> deterministic "@Full Name  " format.
      // This keeps multi-word names inside the mention span.
      final formattedText = MentionParser.markupToDelimitedText(markup).trim();

      await widget.onSubmit(formattedText);
      _mentionKey.currentState?.controller?.clear();
      setState(() {
        _commentText = '';
        _hasText = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _searchUsers(String query) async {
    try {
      final users = await UserSearchService.searchUsers(query);
      return users.map((user) => {
        'id': user.id.toString(),
        // Replace spaces with non-breaking space (U+00A0) to keep full name as single token
        'display': user.name.replaceAll(' ', '\u00A0'),
        'full_name': user.name,
        'photo': user.image ?? user.avatar,
      }).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthService.currentUser != null;
    
    // Show login prompt for non-logged-in users
    if (!isLoggedIn) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: InkWell(
          onTap: () {
            LoginPromptDialog.show(context, action: 'comment on this post');
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withOpacity(0.08),
                  const Color(0xFF059669).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Login to join the conversation',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: () {
                final avatarUrl = AppConfig.getAbsoluteUrl(widget.userAvatar);
                
                if (avatarUrl.isNotEmpty) {
                  return Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.person,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                      );
                    },
                  );
                }
                return Container(
                  color: Colors.grey.shade100,
                  child: Icon(
                    Icons.person,
                    color: Colors.grey.shade400,
                    size: 18,
                  ),
                );
              }(),
            ),
          ),
          const SizedBox(width: 8),
          // Comment Input with Mentions
          Expanded(
            child: FlutterMentions(
                key: _mentionKey,
                suggestionPosition: SuggestionPosition.Top,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 0.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  isDense: true,
                  suffixIcon: _isSubmitting
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          onPressed: _handleSubmit,
                          icon: Icon(
                            Icons.send,
                            size: 18,
                            color: _hasText
                                ? const Color(0xFF3B82F6)
                                : Colors.grey.shade400,
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (value) async {
                  setState(() {
                    _hasText = value.trim().isNotEmpty;
                    _commentText = value;
                  });
                  
                  // Check if user is typing a mention
                  if (value.contains('@')) {
                    final lastAtIndex = value.lastIndexOf('@');
                    final textAfterAt = value.substring(lastAtIndex + 1);
                    
                    // If there's text after @ and no space, search for users
                    if (textAfterAt.isNotEmpty && !textAfterAt.contains(' ')) {
                      final users = await _searchUsers(textAfterAt);
                      if (mounted) {
                        setState(() {
                          _userData = users;
                        });
                      }
                    }
                  }
                },
                onMentionAdd: (Map<String, dynamic> mention) {
                  print('✅ Mention added: $mention');
                  setState(() {
                    _hasText = true;
                  });
                },
                mentions: [
                  Mention(
                    trigger: '@',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    data: _userData,
                    matchAll: false,
                    disableMarkup: false,
                    suggestionBuilder: (data) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade100,
                                  ),
                                  child: ClipOval(
                                    child: () {
                                      final avatarUrl = AppConfig.getAbsoluteUrl(data['photo']);
                                      
                                      if (avatarUrl.isNotEmpty) {
                                        return Image.network(
                                          avatarUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              color: Colors.grey.shade400,
                                              size: 18,
                                            );
                                          },
                                        );
                                      }
                                      return Icon(
                                        Icons.person,
                                        color: Colors.grey.shade400,
                                        size: 18,
                                      );
                                    }(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    // Show full_name (with regular spaces) in suggestion list
                                    data['full_name'] ?? data['display'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ],
            ),
          ),
          // Gift Button
          if (AuthService.currentUser != null && 
              AuthService.currentUser!.id != widget.postAuthorId)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: IconButton(
                  onPressed: () {
                    DiamondGiftBottomSheet.show(
                      context,
                      postId: widget.postId,
                      postAuthorId: widget.postAuthorId,
                      postAuthorName: widget.postAuthorName,
                      onGiftSent: widget.onGiftSent,
                    );
                  },
                  icon: Icon(
                    Icons.card_giftcard,
                    size: 20,
                    color: Colors.pink.shade500,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
