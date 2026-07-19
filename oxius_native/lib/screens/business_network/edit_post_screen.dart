import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';
import '../../utils/image_compressor.dart';
import '../../widgets/link_preview_card.dart';

import '../../config/app_config.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/user_search_service.dart';
import '../../utils/mention_parser.dart';

class EditPostScreen extends StatefulWidget {
  final BusinessNetworkPost post;

  const EditPostScreen({
    super.key,
    required this.post,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final GlobalKey<FlutterMentionsState> _titleMentionKey =
      GlobalKey<FlutterMentionsState>();
  final GlobalKey<FlutterMentionsState> _contentMentionKey =
      GlobalKey<FlutterMentionsState>();
  List<Map<String, dynamic>> _mentionUserData = [];
  // Non-late with safe defaults: late fields crash with
  // LateInitializationError when a hot-reload swaps in this class on an
  // already-mounted State (initState does not re-run).
  String _titleText = '';
  String _contentText = '';
  late final TextEditingController _tagController;
  late final List<String> _tags;
  late String _visibility;
  bool _isSaving = false;
  // Media edits: existing media marked for removal + freshly-picked photos
  // and videos.
  final Set<int> _removedMediaIds = {};
  final List<String> _newImages = []; // base64
  final List<String> _newVideoPaths = []; // local file paths
  bool _isCompressing = false;

  static const int _maxPhotos = 12;
  static const int _maxVideos = 2;
  static const int _maxVideoDurationSeconds = 180; // 3 minutes

  bool get _hasChanges {
    return _titleText.trim() != widget.post.title.trim() ||
        _contentText.trim() != widget.post.content.trim() ||
        _visibility != widget.post.visibility ||
        _removedMediaIds.isNotEmpty ||
        _newImages.isNotEmpty ||
        _newVideoPaths.isNotEmpty ||
        !_listEquals(_tags, widget.post.tags.map((tag) => tag.tag).toList());
  }

  @override
  void initState() {
    super.initState();
    _titleText = widget.post.title;
    _contentText = widget.post.content;
    _tagController = TextEditingController();
    _tags = widget.post.tags
        .map((tag) => _normalizeTag(tag.tag))
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
    // Clamp to the known set — an unexpected value would crash the dropdown.
    const known = {'public', 'followers', 'private'};
    final v = widget.post.visibility.trim();
    _visibility = known.contains(v) ? v : 'public';
    _loadInitialMentionUsers();
  }

  Future<void> _loadInitialMentionUsers() async {
    final users = await _searchUsers('');
    if (mounted) {
      setState(() => _mergeMentionUsers(users));
    }
  }

  /// Accumulate mention candidates instead of replacing them. flutter_mentions
  /// derives its annotations from this `data` list; replacing it on each search
  /// drops previously-inserted mentions from the annotation map, so only the
  /// last-searched user could be mentioned. Deduping by id keeps every inserted
  /// mention recognized while the dropdown still filters by the query.
  void _mergeMentionUsers(List<Map<String, dynamic>> newUsers) {
    final byId = {for (final u in _mentionUserData) u['id']: u};
    for (final u in newUsers) {
      byId[u['id']] = u;
    }
    _mentionUserData = byId.values.toList();
  }

  Future<List<Map<String, dynamic>>> _searchUsers(String query) async {
    try {
      final users = await UserSearchService.searchUsers(query);
      return users
          .map((user) => {
                'id': user.id.toString(),
                // NBSP keeps multi-word names as one mention token.
                'display': user.name.replaceAll(' ', '\u00A0'),
                'full_name': user.name,
                'photo': user.image ?? user.avatar,
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (_normalizeTag(a[i]) != _normalizeTag(b[i])) return false;
    }
    return true;
  }

  String _normalizeTag(String value) {
    return value.trim().replaceFirst(RegExp(r'^#+'), '').trim();
  }

  void _addTag() {
    // Same multi-tag splitting as the create screen: "#a#b" / "a, b" pasted
    // into the field become separate tags.
    final parts = _tagController.text
        .split(RegExp(r'[#,\s]+'))
        .map(_normalizeTag)
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return;
    setState(() {
      for (final tag in parts) {
        if (!_tags
            .any((existing) => existing.toLowerCase() == tag.toLowerCase())) {
          _tags.add(tag);
        }
      }
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _savePost() async {
    final titleMarkup =
        _titleMentionKey.currentState?.controller?.markupText ?? _titleText;
    final contentMarkup =
        _contentMentionKey.currentState?.controller?.markupText ??
            _contentText;
    final title = MentionParser.markupToDelimitedText(titleMarkup).trim();
    final content = MentionParser.markupToDelimitedText(contentMarkup).trim();

    if (title.isEmpty &&
        content.isEmpty &&
        widget.post.media.isEmpty &&
        _tags.isEmpty) {
      _showSnack('Please write something before saving.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      var updated = await BusinessNetworkService.updatePost(
        postId: widget.post.id,
        title: title,
        content: content,
        visibility: _visibility,
        tags: _tags,
        images: _newImages.isNotEmpty ? _newImages : null,
        removeMediaIds:
            _removedMediaIds.isNotEmpty ? _removedMediaIds.toList() : null,
      );

      if (!mounted) return;
      if (updated == null) {
        _showSnack('Could not update the post.', isError: true);
        setState(() => _isSaving = false);
        return;
      }

      // New videos upload separately (multipart, same pipeline as create);
      // each call returns the freshly-updated post.
      for (final path in _newVideoPaths) {
        final withVideo =
            await BusinessNetworkService.addPostVideo(widget.post.id, path);
        if (!mounted) return;
        if (withVideo != null) {
          updated = withVideo;
        } else {
          _showSnack('একটি ভিডিও আপলোড করা যায়নি', isError: true);
        }
      }
      if (!mounted) return;

      Navigator.pop(context, updated);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not update the post.', isError: true);
      setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (isError) {
      AdsyToast.error(context, message);
    } else {
      AdsyToast.success(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Mirrors the create-post chrome: X to dismiss, one pill action in the
    // appbar, no bottom bar.
    return Portal(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87, size: 24),
            onPressed: _isSaving ? null : () => Navigator.pop(context),
          ),
          title: const Text(
            'Edit Post',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _isSaving || !_hasChanges ? null : _savePost,
                style: TextButton.styleFrom(
                  backgroundColor: _isSaving || !_hasChanges
                      ? Colors.grey.shade200
                      : const Color(0xFF2563EB),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _hasChanges
                              ? Colors.white
                              : Colors.grey.shade500,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          // Same 16px screen-side padding as the create screen (the old
          // nested padding doubled it to 32px).
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 80),
          child: _buildEditCard(),
        ),
      ),
    );
  }

  Widget _buildEditCard() {
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuthorStrip(),
          const SizedBox(height: 14),
          // Continuous, label-less flow — exactly like the create screen.
          _buildMentionField(
            mentionKey: _contentMentionKey,
            defaultText: widget.post.content,
            hint: 'What\'s on your mind? Use @ to mention someone',
            minLines: 3,
            maxLines: 6,
            onChanged: (value) => setState(() => _contentText = value),
          ),
          // Live link preview for the first URL in the content, like create.
          if (_contentText.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FirstLinkPreview(text: _contentText),
            ),
          const SizedBox(height: 18),
          _buildTagsEditor(),
          const SizedBox(height: 18),
          _buildMediaPreview(),
        ],
      ),
    );
  }

  Widget _buildAuthorStrip() {
    final avatar = widget.post.user.avatar ?? widget.post.user.image ?? '';

    // Mirrors the create screen's user row exactly: circular avatar, bold
    // name (+verified), and the visibility dropdown pill right under it.
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200, width: 2),
          ),
          child: avatar.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(),
                  ),
                )
              : _avatarFallback(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.post.user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (widget.post.user.isVerified ||
                      widget.post.user.isPro) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: Color(0xFF3B82F6),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<String>(
                  value: _visibility,
                  isDense: true,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(12),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: Colors.grey.shade700,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'public',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.public,
                              size: 14, color: Colors.grey.shade700),
                          const SizedBox(width: 6),
                          const Text('Public'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'followers',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group_outlined,
                              size: 14, color: Colors.grey.shade700),
                          const SizedBox(width: 6),
                          const Text('Followers'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'private',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock,
                              size: 14, color: Colors.grey.shade700),
                          const SizedBox(width: 6),
                          const Text('Only me'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _visibility = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback() {
    return const Icon(Icons.person_rounded, color: Color(0xFF64748B));
  }

  Widget _buildMentionField({
    required GlobalKey<FlutterMentionsState> mentionKey,
    required String defaultText,
    required String hint,
    required int minLines,
    required int maxLines,
    required ValueChanged<String> onChanged,
  }) {
    // Plain page field — no card box — matching the create-post composer.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FlutterMentions(
        key: mentionKey,
        defaultText: defaultText,
        // Compact dropdown that opens BELOW the field (matches create_post).
        suggestionPosition: SuggestionPosition.Bottom,
        suggestionListHeight: 240,
        suggestionListDecoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        minLines: minLines,
        maxLines: maxLines,
        onChanged: onChanged,
        // Same type scale as the create-post composer.
        style: TextStyle(
          fontSize: 15.5,
          color: Colors.grey.shade800,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15.5),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onSearchChanged: (trigger, value) async {
          if (trigger == '@') {
            final users = await _searchUsers(value);
            if (mounted) {
              setState(() => _mergeMentionUsers(users));
            }
          }
        },
        mentions: [
          Mention(
            trigger: '@',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
            data: _mentionUserData,
            matchAll: false,
            disableMarkup: false,
            suggestionBuilder: (data) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade100,
                      ),
                      child: ClipOval(
                        child: () {
                          final avatarUrl =
                              AppConfig.getAbsoluteUrl(data['photo']);
                          if (avatarUrl.isNotEmpty) {
                            return Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person,
                                    color: Colors.grey.shade400, size: 18);
                              },
                            );
                          }
                          return Icon(Icons.person,
                              color: Colors.grey.shade400, size: 18);
                        }(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data['full_name'] ?? data['display'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
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
    );
  }

  // Compact dropdown in the header — same control the create screen uses, so
  // visibility looks and works identically in both places.
  Widget _buildTagsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tag_rounded, size: 17, color: Colors.grey.shade500),
            const SizedBox(width: 7),
            Text(
              'Add Hashtags',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Same pill-shaped input + inline text button as the create screen.
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.only(left: 4, right: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addTag(),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type a hashtag',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.tag,
                        size: 18, color: Colors.grey.shade400),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 36, minHeight: 0),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 11),
                  ),
                ),
              ),
              TextButton(
                onPressed: _addTag,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'যোগ করুন',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          // Chip visuals copied from the create screen.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '#',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // How many photos the post will have after this edit is saved.
  int get _effectivePhotoCount {
    final kept = widget.post.media
        .where((m) => !m.isVideo && !_removedMediaIds.contains(m.id))
        .length;
    return kept + _newImages.length;
  }

  Future<void> _pickImage() async {
    try {
      if (_effectivePhotoCount >= _maxPhotos) {
        AdsyToast.warning(context, 'সর্বোচ্চ $_maxPhotos টি ছবি দেওয়া যাবে');
        return;
      }
      final images = await ImagePicker().pickMultiImage();
      if (images.isEmpty) return;

      final remaining = _maxPhotos - _effectivePhotoCount;
      final toAdd = images.take(remaining).toList();
      if (images.length > remaining && mounted) {
        AdsyToast.warning(
            context, 'শুধু $remaining টি ছবি যোগ হলো ($_maxPhotos সর্বোচ্চ)');
      }

      setState(() => _isCompressing = true);
      for (final image in toAdd) {
        final compressed = await ImageCompressor.compressToBase64(
          image,
          targetSize: 100 * 1024,
          initialQuality: 78,
          maxDimension: 1920,
        );
        if (compressed != null && mounted) {
          setState(() => _newImages.add(compressed));
        }
      }
      if (mounted) setState(() => _isCompressing = false);
    } catch (_) {
      if (mounted) {
        setState(() => _isCompressing = false);
        AdsyToast.error(context, 'ছবি বাছাই করা যায়নি');
      }
    }
  }

  // How many videos the post will have after this edit is saved.
  int get _effectiveVideoCount {
    final kept = widget.post.media
        .where((m) => m.isVideo && !_removedMediaIds.contains(m.id))
        .length;
    return kept + _newVideoPaths.length;
  }

  Future<void> _pickNewVideo() async {
    if (_effectiveVideoCount >= _maxVideos) {
      AdsyToast.warning(context, 'সর্বোচ্চ $_maxVideos টি ভিডিও দেওয়া যাবে');
      return;
    }
    try {
      final XFile? video = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: _maxVideoDurationSeconds),
      );
      if (video == null || !mounted) return;
      setState(() => _newVideoPaths.add(video.path));
    } catch (_) {
      if (mounted) AdsyToast.error(context, 'ভিডিও বাছাই করা যায়নি');
    }
  }

  Widget _buildMediaPreview() {
    final existing = widget.post.media
        .where((m) => !_removedMediaIds.contains(m.id))
        .toList();

    final videoCount = _effectiveVideoCount;

    // Header, count badges, actions and limits copied from the create screen
    // so editing feels identical to composing.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.perm_media_rounded,
                size: 17, color: Colors.grey.shade500),
            const SizedBox(width: 7),
            Text(
              'Media',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_effectivePhotoCount/$_maxPhotos photos',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$videoCount/$_maxVideos videos',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade700,
                ),
              ),
            ),
            const Spacer(),
            if (_isCompressing)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (existing.isNotEmpty ||
            _newImages.isNotEmpty ||
            _newVideoPaths.isNotEmpty) ...[
          SizedBox(
            height: 82,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final m in existing) ...[
                  _removableThumb(
                    child: _buildMediaThumb(m),
                    onRemove: () =>
                        setState(() => _removedMediaIds.add(m.id)),
                  ),
                  const SizedBox(width: 8),
                ],
                for (var i = 0; i < _newImages.length; i++) ...[
                  _removableThumb(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        base64Decode(_newImages[i]),
                        width: 82,
                        height: 82,
                        fit: BoxFit.cover,
                      ),
                    ),
                    onRemove: () => setState(() => _newImages.removeAt(i)),
                  ),
                  const SizedBox(width: 8),
                ],
                // Freshly-picked videos (uploaded on save) — same dark tile
                // with a VIDEO badge as the create screen.
                for (var i = 0; i < _newVideoPaths.length; i++) ...[
                  _removableThumb(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 82,
                        height: 82,
                        color: Colors.grey.shade800,
                        child: const Stack(
                          children: [
                            Center(
                              child: Icon(Icons.play_circle_fill,
                                  color: Colors.white, size: 32),
                            ),
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Text(
                                'VIDEO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    onRemove: () =>
                        setState(() => _newVideoPaths.removeAt(i)),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        // Same direct photo / video actions as the create screen.
        Row(
          children: [
            Expanded(
              child: _mediaActionButton(
                icon: Icons.photo_library_outlined,
                iconColor: const Color(0xFF16A34A),
                label: 'ছবি',
                onTap: _isCompressing ? () {} : _pickImage,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _mediaActionButton(
                icon: Icons.videocam_outlined,
                iconColor: const Color(0xFFDC2626),
                label: 'ভিডিও',
                onTap: _pickNewVideo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Same limits line as the create screen.
        Text(
          'প্রতি পোস্টে সর্বোচ্চ $_maxPhotos টি ছবি এবং $_maxVideos টি ভিডিও দেওয়া যাবে, এবং প্রতি ভিডিও সর্বোচ্চ ৩ মিনিটের মধ্যে হতে হবে',
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.grey.shade500,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _mediaActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A thumbnail with an ✕ badge to remove it from the post.
  Widget _removableThumb({
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaThumb(PostMedia media) {
    final imageUrl = media.bestThumbnailUrl.isNotEmpty
        ? media.bestThumbnailUrl
        : media.bestUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 82,
        height: 82,
        color: const Color(0xFFEAF1F8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: Color(0xFF94A3B8),
                ),
              )
            else
              const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
            if (media.isVideo)
              Center(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}
