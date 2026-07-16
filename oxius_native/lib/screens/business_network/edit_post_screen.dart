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
  // Media edits: existing media marked for removal + freshly-picked photos.
  final Set<int> _removedMediaIds = {};
  final List<String> _newImages = []; // base64
  bool _isCompressing = false;

  static const int _maxPhotos = 12;

  bool get _hasChanges {
    return _titleText.trim() != widget.post.title.trim() ||
        _contentText.trim() != widget.post.content.trim() ||
        _visibility != widget.post.visibility ||
        _removedMediaIds.isNotEmpty ||
        _newImages.isNotEmpty ||
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
      setState(() => _mentionUserData = users);
    }
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
      final updated = await BusinessNetworkService.updatePost(
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
          padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 80),
          child: _buildEditCard(),
        ),
      ),
    );
  }

  Widget _buildEditCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuthorStrip(),
          _sectionDivider(),
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          _buildMentionField(
            mentionKey: _contentMentionKey,
            defaultText: widget.post.content,
            hint: 'What do you want to share? Use @ to mention people',
            minLines: 4,
            maxLines: 8,
            onChanged: (value) => setState(() => _contentText = value),
          ),
          // Live link preview for the first URL in the content, like create.
          if (_contentText.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FirstLinkPreview(text: _contentText),
            ),
          _sectionDivider(),
          _buildTagsEditor(),
          _sectionDivider(),
          _buildMediaPreview(),
        ],
      ),
    );
  }

  Widget _buildAuthorStrip() {
    final avatar = widget.post.user.avatar ?? widget.post.user.image ?? '';

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 48,
            height: 48,
            color: const Color(0xFFEAF1F8),
            child: avatar.isNotEmpty
                ? Image.network(
                    avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(),
                  )
                : _avatarFallback(),
          ),
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
                        color: Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (widget.post.user.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified,
                        size: 15, color: Color(0xFF2563EB)),
                  ],
                  if (widget.post.user.isPro) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Pro',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Update your post details',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _buildVisibilityPill(),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: FlutterMentions(
        key: mentionKey,
        defaultText: defaultText,
        // Keep suggestions beside the caret (see create_post_screen).
        suggestionPosition: SuggestionPosition.Top,
        suggestionListHeight: 220,
        minLines: minLines,
        maxLines: maxLines,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 14,
          height: 1.45,
          color: Color(0xFF111827),
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onSearchChanged: (trigger, value) async {
          if (trigger == '@') {
            final users = await _searchUsers(value);
            if (mounted) {
              setState(() => _mentionUserData = users);
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
  Widget _buildVisibilityPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<String>(
        value: _visibility,
        isDense: true,
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(
          Icons.arrow_drop_down,
          size: 18,
          color: Color(0xFF64748B),
        ),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
        items: const [
          DropdownMenuItem(
            value: 'public',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public, size: 14, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text('Public'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'followers',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group_outlined, size: 14, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text('Followers'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'private',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 14, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text('Only me'),
              ],
            ),
          ),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _visibility = value);
        },
      ),
    );
  }

  Widget _sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Container(height: 1, color: const Color(0xFFEDF2F7)),
    );
  }

  Widget _buildTagsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hashtags',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: Color(0xFF2563EB)),
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

  Widget _buildMediaPreview() {
    final existing = widget.post.media
        .where((m) => !_removedMediaIds.contains(m.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library_rounded,
                size: 18, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            const Text(
              'Attached media',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
            const Spacer(),
            if (_isCompressing)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                '${existing.length + _newImages.length}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
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
              // Add-photo tile.
              InkWell(
                onTap: _isCompressing ? null : _pickImage,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 24, color: Color(0xFF64748B)),
                      SizedBox(height: 4),
                      Text(
                        'ছবি যোগ',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
