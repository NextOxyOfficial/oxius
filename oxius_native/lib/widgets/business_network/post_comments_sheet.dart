import 'package:flutter/material.dart';

import '../../models/business_network_models.dart';
import '../../services/auth_service.dart';
import '../../services/business_network_service.dart';
import '../../config/app_config.dart';
import '../../widgets/login_prompt_dialog.dart';
import '../common/adsy_loading.dart';

/// Comments for a BN post in a bottom sheet.
///
/// Used by promoted (boosted) posts in the feed, which read like ordinary posts
/// but must not carry the always-open comment section a normal feed post has —
/// same treatment AdsyNews gets: the count is visible, tapping it opens this.
/// A new comment appears immediately and the host card's count updates through
/// [onCountChanged], so nothing needs a reload.
class PostCommentsSheet extends StatefulWidget {
  final BusinessNetworkPost post;
  final ValueChanged<int>? onCountChanged;

  const PostCommentsSheet({
    super.key,
    required this.post,
    this.onCountChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required BusinessNetworkPost post,
    ValueChanged<int>? onCountChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostCommentsSheet(
        post: post,
        onCountChanged: onCountChanged,
      ),
    );
  }

  @override
  State<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<PostCommentsSheet> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  List<BusinessNetworkComment> _comments = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await BusinessNetworkService.getPostComments(
      postId: int.tryParse(widget.post.id.toString()) ?? 0,
    );
    if (!mounted) return;
    setState(() {
      _comments = rows;
      _loading = false;
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (AuthService.currentUser == null) {
      LoginPromptDialog.show(context, action: 'comment on this post');
      return;
    }
    setState(() => _sending = true);
    final created = await BusinessNetworkService.addComment(
      postId: int.tryParse(widget.post.id.toString()) ?? 0,
      content: text,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (created != null) {
        // Show it straight away rather than refetching — that round-trip is
        // what made a comment look like it needed a reload.
        _comments = [..._comments, created];
        _controller.clear();
      }
    });
    if (created != null) {
      widget.onCountChanged?.call(_comments.length);
      // Let the new row lay out before scrolling to it.
      await Future.delayed(const Duration(milliseconds: 60));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.8;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Text(
                  _comments.isEmpty
                      ? 'মন্তব্য'
                      : 'মন্তব্য (${_comments.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded,
                        size: 20, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF2F6)),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: AdsyLoadingIndicator(),
                  )
                : _comments.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Text(
                          'এখনো কোনো মন্তব্য নেই — প্রথম মন্তব্যটি করুন',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7B8798),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _comments.length,
                        itemBuilder: (_, i) => _row(_comments[i]),
                      ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF2F6)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'মন্তব্য লিখুন…',
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade600,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded,
                          size: 20, color: Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BusinessNetworkComment c) {
    final avatar = AppConfig.getAbsoluteUrl(c.user.image ?? '');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: const Color(0xFFF1F5F9),
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty
                ? const Icon(Icons.person, size: 16, color: Color(0xFF94A3B8))
                : null,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.user.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.content,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Color(0xFF2C3949),
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
}
