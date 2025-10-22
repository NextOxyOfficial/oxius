import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
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
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(text);
      _controller.clear();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
          // Comment Input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 20,
                maxHeight: 40,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 0,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSubmit(),
                    ),
                  ),
                  if (_isSubmitting)
                    const Padding(
                      padding: EdgeInsets.only(right: 12, bottom: 10),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: IconButton(
                        onPressed: _handleSubmit,
                        icon: Icon(
                          Icons.send,
                          size: 18,
                          color: _hasText
                              ? const Color(0xFF3B82F6)
                              : Colors.grey.shade400,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Gift Button (only show if not the post author)
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
