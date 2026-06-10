import 'package:flutter/material.dart';

import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';

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
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagController;
  late final List<String> _tags;
  late String _visibility;
  bool _isSaving = false;

  bool get _hasChanges {
    return _titleController.text.trim() != widget.post.title.trim() ||
        _contentController.text.trim() != widget.post.content.trim() ||
        _visibility != widget.post.visibility ||
        !_listEquals(_tags, widget.post.tags.map((tag) => tag.tag).toList());
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    _tagController = TextEditingController();
    _tags = widget.post.tags
        .map((tag) => _normalizeTag(tag.tag))
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
    _visibility = widget.post.visibility.trim().isEmpty
        ? 'public'
        : widget.post.visibility;
    // Re-evaluate _hasChanges (Save button state) as the user types.
    _titleController.addListener(_onFieldChanged);
    _contentController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_onFieldChanged);
    _contentController.removeListener(_onFieldChanged);
    _titleController.dispose();
    _contentController.dispose();
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
    final tag = _normalizeTag(_tagController.text);
    if (tag.isEmpty) return;
    if (_tags.any((existing) => existing.toLowerCase() == tag.toLowerCase())) {
      _tagController.clear();
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _savePost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Edit Post',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_titleController, _contentController]),
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
            child: _buildEditCard(),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(12, 10, 12, bottomInset + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFD8E1EC)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving || !_hasChanges ? null : _savePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: const Color(0xFFCAD7EA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditCard() {
    return _panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuthorStrip(),
          _sectionDivider(),
          const Text(
            'Post title',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _titleController,
            hint: 'Add a short title',
            minLines: 1,
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _contentController,
            hint: 'What do you want to share?',
            minLines: 8,
            maxLines: 14,
          ),
          const SizedBox(height: 14),
          _buildVisibilitySelector(),
          _sectionDivider(),
          _buildTagsEditor(),
          if (widget.post.media.isNotEmpty) ...[
            _sectionDivider(),
            _buildMediaPreview(),
          ],
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
              Text(
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int minLines,
    required int maxLines,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction:
          maxLines > 2 ? TextInputAction.newline : TextInputAction.done,
      style: const TextStyle(
        fontSize: 14,
        height: 1.45,
        color: Color(0xFF111827),
        letterSpacing: 0,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
        ),
      ),
    );
  }

  Widget _buildVisibilitySelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildVisibilityOption(
            value: 'public',
            label: 'Public',
            icon: Icons.public_rounded,
          ),
          _buildVisibilityOption(
            value: 'private',
            label: 'Private',
            icon: Icons.lock_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityOption({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final selected = _visibility == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _visibility = value),
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityPill() {
    final isPrivate = _visibility == 'private';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isPrivate ? const Color(0xFFFFF7ED) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isPrivate ? const Color(0xFFFED7AA) : const Color(0xFFA7F3D0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrivate ? Icons.lock_outline_rounded : Icons.public_rounded,
            size: 14,
            color:
                isPrivate ? const Color(0xFFEA580C) : const Color(0xFF059669),
          ),
          const SizedBox(width: 4),
          Text(
            isPrivate ? 'Private' : 'Public',
            style: TextStyle(
              color:
                  isPrivate ? const Color(0xFFEA580C) : const Color(0xFF047857),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
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
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addTag(),
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Add a hashtag and press +',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade400,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 38,
              height: 38,
              child: Material(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _addTag,
                  borderRadius: BorderRadius.circular(12),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
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

  Widget _buildMediaPreview() {
    final media = widget.post.media.take(6).toList();

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
            Text(
              '${widget.post.media.length}',
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
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: media.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return _buildMediaThumb(media[index]);
            },
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

  Widget _panel({
    required Widget child,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EDF7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
