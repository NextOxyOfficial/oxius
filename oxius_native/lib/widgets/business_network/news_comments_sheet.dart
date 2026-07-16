import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/news_models.dart';
import '../../services/auth_service.dart';
import '../../services/news_service.dart';
import '../../utils/time_utils.dart';
import '../common/adsy_toast.dart';
import '../login_prompt_dialog.dart';

/// Comments on an Adsy News story, styled to match Business Network comments.
///
/// The news comment API is flat — no replies, likes or gifts — so this is a
/// single-level list plus a composer. Reachable from the feed's news card and
/// from a news reshare, so both surfaces share one implementation.
class NewsCommentsSheet extends StatefulWidget {
  final String newsId;
  final String newsTitle;

  /// Fired whenever the comment count changes (load/new comment), so callers
  /// can live-update their counters without a reload.
  final ValueChanged<int>? onCountChanged;

  const NewsCommentsSheet({
    super.key,
    required this.newsId,
    this.newsTitle = '',
    this.onCountChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required String newsId,
    String newsTitle = '',
    ValueChanged<int>? onCountChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewsCommentsSheet(
        newsId: newsId,
        newsTitle: newsTitle,
        onCountChanged: onCountChanged,
      ),
    );
  }

  @override
  State<NewsCommentsSheet> createState() => _NewsCommentsSheetState();
}

class _NewsCommentsSheetState extends State<NewsCommentsSheet> {
  final _controller = TextEditingController();
  List<NewsComment> _comments = [];
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
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await NewsService.getComments(widget.newsId);
    if (!mounted) return;
    setState(() {
      _comments = rows;
      _loading = false;
    });
    widget.onCountChanged?.call(rows.length);
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    if (!AuthService.isAuthenticated) {
      LoginPromptDialog.show(context, action: 'কমেন্ট করতে');
      return;
    }

    setState(() => _sending = true);
    final created = await NewsService.addComment(widget.newsId, text);
    if (!mounted) return;

    if (created != null) {
      _controller.clear();
      setState(() {
        _comments.insert(0, created);
        _sending = false;
      });
      widget.onCountChanged?.call(_comments.length);
    } else {
      setState(() => _sending = false);
      AdsyToast.error(context, 'কমেন্ট পোস্ট করা যায়নি');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (_comments.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${_comments.length}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _loading
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _comments.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            itemCount: _comments.length,
                            itemBuilder: (_, i) => _buildTile(_comments[i]),
                          ),
              ),
              const Divider(height: 1),
              _buildComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() => ListView(
        children: const [
          SizedBox(height: 48),
          Icon(Icons.mode_comment_outlined,
              size: 34, color: Color(0xFFCBD5E1)),
          SizedBox(height: 10),
          Center(
            child: Text(
              'এখনো কোনো কমেন্ট নেই',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      );

  // Mirrors the Business Network comment look: avatar + grey rounded bubble
  // with the author's name above the text, timestamp underneath.
  Widget _buildTile(NewsComment c) {
    final avatar = AppConfig.getAbsoluteUrl(c.userImage);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE2E8F0),
            ),
            child: ClipOval(
              child: avatar.isNotEmpty
                  ? Image.network(avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: Color(0xFF94A3B8)))
                  : const Icon(Icons.person_rounded,
                      size: 18, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              (c.userName ?? '').isNotEmpty
                                  ? c.userName!
                                  : 'ব্যবহারকারী',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (c.userVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                size: 12, color: Color(0xFF2563EB)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.content,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF334155),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 3),
                  child: Text(
                    TimeUtils.formatTimeAgo(c.createdAt.toIso8601String()),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'কমেন্ট লিখুন...',
                  hintStyle: const TextStyle(
                      fontSize: 16, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: Color(0xFF2563EB)),
            ),
          ],
        ),
      ),
    );
  }
}
