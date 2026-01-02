import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/mindforce_models.dart';
import '../../services/mindforce_service.dart';
import '../../services/auth_service.dart';
import '../../utils/time_utils.dart';
import '../../utils/image_compressor.dart';
import '../../config/app_config.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/linkify_text.dart';
import '../../widgets/link_preview_card.dart';

class MindForceDetailScreen extends StatefulWidget {
  final String problemId;

  const MindForceDetailScreen({
    super.key,
    required this.problemId,
  });

  @override
  State<MindForceDetailScreen> createState() => _MindForceDetailScreenState();
}

class _MindForceDetailScreenState extends State<MindForceDetailScreen> {
  MindForceProblem? _problem;
  List<MindForceComment> _comments = [];
  bool _isLoading = true;
  bool _isSubmittingComment = false;
  final TextEditingController _commentController = TextEditingController();
  final List<File> _commentImages = [];
  final List<String> _compressedImages = [];
  bool _isCompressing = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProblemDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProblemDetails() async {
    setState(() => _isLoading = true);

    final problems = await MindForceService.getProblems();
    final problem = problems.firstWhere(
      (p) => p.id == widget.problemId,
      orElse: () => throw Exception('Problem not found'),
    );

    final comments = await MindForceService.getComments(widget.problemId);

    if (mounted) {
      setState(() {
        _problem = problem;
        _comments = comments;
        _isLoading = false;
      });
      
      // Increment view count after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _problem != null) {
          MindForceService.incrementViews(widget.problemId, _problem!.views);
        }
      });
    }
  }

  Future<void> _pickImage() async {
    if (_commentImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 images allowed')),
      );
      return;
    }

    setState(() => _isCompressing = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final compressedBase64 = await ImageCompressor.compressToBase64(
          pickedFile,
          targetSize: 80 * 1024,
          initialQuality: 78,
          maxDimension: 1200,
          verbose: true,
        );

        if (compressedBase64 != null) {
          setState(() {
            _commentImages.add(File(pickedFile.path));
            _compressedImages.add(compressedBase64);
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    } finally {
      setState(() => _isCompressing = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _commentImages.removeAt(index);
      _compressedImages.removeAt(index);
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty && _compressedImages.isEmpty) {
      return;
    }

    setState(() => _isSubmittingComment = true);

    try {
      final comment = await MindForceService.addComment(
        problemId: widget.problemId,
        content: _commentController.text.trim(),
        images: _compressedImages,
      );

      if (comment != null && mounted) {
        setState(() {
          _comments.add(comment);
          _commentController.clear();
          _commentImages.clear();
          _compressedImages.clear();
        });

        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Advice posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error submitting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post advice'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  Future<void> _markAsSolved() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Solved'),
        content: const Text('Are you sure this problem has been solved?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Mark as Solved'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await MindForceService.markProblemAsSolved(widget.problemId);
      if (success && mounted) {
        setState(() {
          _problem = _problem!.copyWith(status: 'solved');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Problem marked as solved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _markCommentAsSolution(String commentId) async {
    final success = await MindForceService.markCommentAsSolution(commentId);
    if (success && mounted) {
      await _loadProblemDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment marked as solution!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  bool get isOwner {
    final user = AuthService.currentUser;
    return user != null && _problem != null && user.id == _problem!.userDetails.id;
  }

  bool _isCommentAuthor(MindForceComment comment) {
    final user = AuthService.currentUser;
    return user != null && user.id == comment.userDetails.id;
  }

  bool _canDeleteComment(MindForceComment comment) {
    return isOwner || _isCommentAuthor(comment);
  }

  bool _canEditComment(MindForceComment comment) {
    return _isCommentAuthor(comment);
  }

  void _showCommentActions(MindForceComment comment) {
    final canEdit = _canEditComment(comment);
    final canDelete = _canDeleteComment(comment);

    if (!canEdit && !canDelete) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit, color: Color(0xFF3B82F6)),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    _editComment(comment);
                  },
                ),
              if (canEdit && canDelete) const Divider(height: 1),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteComment(comment);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editComment(MindForceComment comment) async {
    final controller = TextEditingController(text: comment.content);
    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Edit advice'),
            content: TextField(
              controller: controller,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Update your advice',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (shouldSave != true) return;
      final newText = controller.text.trim();
      if (newText.isEmpty) return;

      final updated = await MindForceService.updateComment(
        commentId: comment.id,
        content: newText,
      );

      if (!mounted) return;

      if (updated != null) {
        await _loadProblemDetails();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment updated')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update comment'), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deleteComment(MindForceComment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete advice'),
          content: const Text('Are you sure you want to delete this advice?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final success = await MindForceService.deleteComment(comment.id);
    if (!mounted) return;

    if (success) {
      await _loadProblemDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete comment'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Problem Details',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (isOwner && _problem!.status != 'solved')
            TextButton.icon(
              onPressed: _markAsSolved,
              icon: const Icon(Icons.check_circle, size: 18, color: Colors.green),
              label: const Text(
                'Mark as Solved',
                style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? SkeletonLoader.detailPage()
          : _problem == null
              ? const Center(child: Text('Problem not found'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Compact Header Card
                            _buildCompactHeader(),
                            
                            // Problem Content
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.white,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProblemContent(),
                                  if (_problem!.media.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    _buildMediaGallery(),
                                  ],
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Comments Section
                            _buildCommentsSection(),
                          ],
                        ),
                      ),
                    ),
                    if (AuthService.currentUser != null && _problem!.status != 'solved')
                      _buildCommentInput()
                    else if (AuthService.currentUser == null && _problem!.status != 'solved')
                      _buildLoginPrompt()
                    else if (_problem!.status == 'solved')
                      _buildSolvedMessage(),
                  ],
                ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipOval(
                  child: () {
                    final avatarUrl = AppConfig.getAbsoluteUrl(_problem!.userDetails.image);
                    if (avatarUrl.isNotEmpty) {
                      return Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
                      );
                    }
                    return _buildAvatarFallback();
                  }(),
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
                            _problem!.userDetails.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_problem!.userDetails.kyc) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 14, color: Color(0xFF3B82F6)),
                        ],
                        if (_problem!.userDetails.isPro) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7f00ff), Color(0xFFe100ff)],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      TimeUtils.formatTimeAgo(_problem!.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Title
          Text(
            _problem!.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Badges Row
          Row(
            children: [
              if (_problem!.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category, size: 12, color: Colors.purple.shade700),
                      const SizedBox(width: 4),
                      Text(
                        _problem!.category!.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _problem!.paymentOption == 'paid' ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _problem!.paymentOption == 'paid' ? Icons.payments : Icons.volunteer_activism,
                      size: 12,
                      color: _problem!.paymentOption == 'paid' ? Colors.green.shade700 : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _problem!.paymentOption == 'paid' && _problem!.paymentAmount != null
                          ? '৳${_problem!.paymentAmount!.toStringAsFixed(0)}'
                          : 'Free',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _problem!.paymentOption == 'paid' ? Colors.green.shade700 : Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Stats
              Row(
                children: [
                  Icon(Icons.visibility, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    '${_problem!.views}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    '${_comments.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    final name = _problem!.userDetails.name;
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name[0].toUpperCase();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.blue.shade200],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.blue.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildProblemContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_problem!.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3)),
        const SizedBox(height: 12),
        LinkifyText(_problem!.description, style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5)),
        FirstLinkPreview(text: _problem!.description),
      ],
    );
  }

  Widget _buildMediaGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image, size: 20, color: Colors.blue.shade500),
            const SizedBox(width: 8),
            const Text('Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _problem!.media.length,
          itemBuilder: (context, index) {
            final imageUrl = AppConfig.getAbsoluteUrl(_problem!.media[index].image);
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image, color: Colors.grey.shade400),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.chat_bubble, size: 20, color: Colors.blue.shade500),
            const SizedBox(width: 8),
            Text('Advice (${_comments.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 16),
        if (_comments.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No advice has been posted yet.\nBe the first to help!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (context, index) => _buildCommentItem(_comments[index]),
          ),
      ],
    );
  }

  Widget _buildCommentItem(MindForceComment comment) {
    return InkWell(
      onLongPress: (_canEditComment(comment) || _canDeleteComment(comment))
          ? () => _showCommentActions(comment)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: comment.isSolved ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: comment.isSolved ? Colors.green.shade200 : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipOval(
                  child: () {
                    final avatarUrl = AppConfig.getAbsoluteUrl(comment.userDetails.image);
                    if (avatarUrl.isNotEmpty) {
                      return Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(Icons.person, color: Colors.grey.shade400),
                        ),
                      );
                    }
                    return Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.person, color: Colors.grey.shade400),
                    );
                  }(),
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
                            comment.userDetails.name, 
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (comment.userDetails.kyc) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 14, color: Color(0xFF3B82F6)),
                        ],
                        if (comment.userDetails.isPro) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        if (comment.isSolved) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.green.shade500, Colors.green.shade600]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Solution', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(TimeUtils.formatTimeAgo(comment.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (isOwner && _problem!.status != 'solved' && !comment.isSolved)
                OutlinedButton.icon(
                  onPressed: () => _markCommentAsSolution(comment.id),
                  icon: const Icon(Icons.check_circle, size: 14),
                  label: const Text('Mark Solution', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LinkifyText(comment.content, style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4)),
          FirstLinkPreview(text: comment.content),
          if (comment.media.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: comment.media.map((mediaItem) {
                final image = mediaItem.image;
                final imageUrl = AppConfig.getAbsoluteUrl(image);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image, color: Colors.grey.shade400),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.send, size: 16, color: Colors.blue.shade500),
              const SizedBox(width: 8),
              const Text('Write an advice', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your solution or ask for clarification...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _isCompressing ? null : _pickImage,
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: const Text('Add Photo'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
              const SizedBox(width: 8),
              Text('${_commentImages.length}/3 images', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isSubmittingComment ? null : _submitComment,
                icon: _isSubmittingComment
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, size: 18),
                label: Text(_isSubmittingComment ? 'Submitting...' : 'Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          if (_commentImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commentImages.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(entry.value, width: 80, height: 80, fit: BoxFit.cover)),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(entry.key),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border(top: BorderSide(color: Colors.amber.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
            child: Icon(Icons.lock, size: 20, color: Colors.amber.shade700),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Authentication Required', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('Please login to add your advice', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolvedMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(top: BorderSide(color: Colors.green.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
            child: Icon(Icons.check_circle, size: 20, color: Colors.green.shade700),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This problem has been marked as solved', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('New advice cannot be added to solved problems', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
