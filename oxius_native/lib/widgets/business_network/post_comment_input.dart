import 'package:flutter/material.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import '../../services/auth_service.dart';
import '../../services/user_search_service.dart';
import '../../models/user_model.dart' as UserModel;
import 'diamond_gift_bottom_sheet.dart';

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
    // Use plain text instead of markup - it shows the display names
    final plainText = _mentionKey.currentState?.controller?.text ?? '';
    if (plainText.trim().isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      print('📝 Submitting comment: $plainText');
      
      // The flutter_mentions widget shows mentions with special character
      // We need to preserve the full name and add double space after for parsing
      // Match @Name (including spaces in name) until we hit double space or regular text
      final formattedText = plainText.replaceAllMapped(
        RegExp(r'@([A-Za-z][A-Za-z\s]+?)(?=\s{2,}|[.!?,;:]|\s+[^A-Z]|$)'),
        (match) {
          final name = match.group(1)?.trim() ?? '';
          return '@$name  ';
        },
      ).trim();
      
      print('✅ Formatted text: $formattedText');
      
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
        'id': user.id ?? user.name,
        'display': user.name,
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
              child: widget.userAvatar != null
                  ? Image.network(
                      widget.userAvatar!,
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
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: Icon(
                        Icons.person,
                        color: Colors.grey.shade400,
                        size: 18,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          // Comment Input with Mentions
          Expanded(
            child: FlutterMentions(
                key: _mentionKey,
                suggestionPosition: SuggestionPosition.Top,
                maxLines: 3,
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
                    vertical: 10,
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
                                    child: data['photo'] != null
                                        ? Image.network(
                                            data['photo'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.person,
                                                color: Colors.grey.shade400,
                                                size: 18,
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.person,
                                            color: Colors.grey.shade400,
                                            size: 18,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    data['display'] ?? '',
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
