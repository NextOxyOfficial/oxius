import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'dart:convert';
import 'dart:io';
import 'package:video_player/video_player.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_search_service.dart';
import '../../utils/mention_parser.dart';
import '../../utils/image_compressor.dart';
import '../../utils/network_error_handler.dart';
import '../../utils/api_error.dart';
import '../../widgets/api_error_ui.dart';
import '../../widgets/link_preview_card.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';
import '../../config/app_config.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _hashtagController = TextEditingController();
  final GlobalKey<FlutterMentionsState> _contentMentionKey =
      GlobalKey<FlutterMentionsState>();
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _mentionUserData = [];

  final List<String> _selectedImages = [];
  final List<Map<String, dynamic>> _selectedVideos = []; // {path, name}
  final List<String> _hashtags = [];
  String _visibility = 'public'; // public | followers | private
  bool _isLoading = false;
  bool _isCompressing = false;
  String _compressionStatus = '';
  // 0..1 while the post (with videos) is uploading, null otherwise.
  double? _uploadProgress;

  static const int _maxPhotos = 12;
  static const int _maxVideos = 2;
  static const int _maxVideoDurationSeconds = 180; // 3 minutes

  @override
  void initState() {
    super.initState();
    _loadInitialUsers();
  }

  Future<void> _loadInitialUsers() async {
    final users = await _searchUsers('');
    if (mounted) {
      setState(() {
        _mentionUserData = users;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _searchUsers(String query) async {
    try {
      final users = await UserSearchService.searchUsers(query);
      return users
          .map((user) => {
                'id': user.id.toString(),
                'display': user.name.replaceAll(' ', '\u00A0'),
                'full_name': user.name,
                'photo': user.image ?? user.avatar,
              })
          .toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _hashtagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Check if we've reached the limit
      if (_selectedImages.length >= 12) {
        if (mounted) {
          AdsyToast.warning(context, 'Maximum 12 photos allowed');
        }
        return;
      }

      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isNotEmpty) {
        // Calculate how many images we can add
        final remainingSlots = 12 - _selectedImages.length;
        final imagesToAdd = images.take(remainingSlots).toList();

        // Show warning if some images were skipped
        if (images.length > remainingSlots && mounted) {
          AdsyToast.warning(
              context, 'Only $remainingSlots photos added (12 max)');
        }

        setState(() {
          _isCompressing = true;
          _compressionStatus = 'Compressing images...';
        });

        // Compress images using the image compressor utility
        for (int i = 0; i < imagesToAdd.length; i++) {
          final image = imagesToAdd[i];

          setState(() {
            ((i + 1) / imagesToAdd.length * 100).round();
            _compressionStatus = 'Processing ${i + 1}/${imagesToAdd.length}';
          });

          // Use ImageCompressor utility for aggressive compression (80KB target)
          final compressedBase64 = await ImageCompressor.compressToBase64(
            image,
            targetSize: 100 * 1024, // 100KB target
            initialQuality: 78,
            maxDimension: 1920,
            verbose: true,
          );

          if (compressedBase64 != null && mounted) {
            setState(() {
              _selectedImages.add(compressedBase64);
            });
          }
        }

        setState(() {
          _isCompressing = false;
          _compressionStatus = '';
        });

        if (mounted) {
          AdsyToast.success(
              context, '${imagesToAdd.length} images compressed successfully');
        }
      }
    } catch (e) {
      setState(() {
        _isCompressing = false;
      });

      if (mounted) {
        AdsyToast.error(context, 'ছবি বাছাই করা যায়নি');
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _pickVideo() async {
    // Check video limit
    if (_selectedVideos.length >= _maxVideos) {
      if (mounted) {
        AdsyToast.warning(
            context, 'Maximum $_maxVideos videos allowed per post');
      }
      return;
    }

    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: _maxVideoDurationSeconds),
      );

      if (video == null) return;

      setState(() {
        _isCompressing = true;
        _compressionStatus = 'Processing video...';
      });

      // Enforce duration limit (max 3 minutes)
      try {
        final controller = VideoPlayerController.file(File(video.path));
        await controller.initialize();
        final duration = controller.value.duration;
        await controller.dispose();

        if (duration > const Duration(seconds: _maxVideoDurationSeconds)) {
          if (mounted) {
            AdsyToast.warning(
                context, 'ভিডিওটি খুব বড় — সর্বোচ্চ ৩ মিনিটের ভিডিও দেওয়া যাবে');
          }
          setState(() {
            _isCompressing = false;
            _compressionStatus = '';
          });
          return;
        }
      } catch (_) {
        // If we fail to read duration, allow selection to proceed
      }

      setState(() {
        _selectedVideos.add({
          'path': video.path,
          'name': video.name,
        });
        _isCompressing = false;
        _compressionStatus = '';
      });

      if (mounted) {
        AdsyToast.success(context, 'Video added');
      }
    } catch (e) {
      setState(() {
        _isCompressing = false;
        _compressionStatus = '';
      });

      if (mounted) {
        AdsyToast.error(context, 'ভিডিও বাছাই করা যায়নি');
      }
    }
  }

  void _removeVideo(int index) {
    setState(() {
      _selectedVideos.removeAt(index);
    });
  }

  void _addHashtag() {
    final input = _hashtagController.text.trim();
    if (input.isEmpty) return;

    // People often paste several tags at once ("#offer#sale" or
    // "offer, sale #new") — split on #, commas and whitespace so each
    // becomes its own tag instead of one glued-together tag.
    final parts = input
        .split(RegExp(r'[#,\s]+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return;

    setState(() {
      for (final tag in parts) {
        if (!_hashtags.contains(tag)) _hashtags.add(tag);
      }
      _hashtagController.clear();
    });
  }

  void _removeHashtag(String hashtag) {
    setState(() {
      _hashtags.remove(hashtag);
    });
  }

  Future<void> _createPost() async {
    final contentController = _contentMentionKey.currentState?.controller;

    final rawContent = contentController?.text ?? '';
    final contentMarkup = contentController?.markupText ?? '';
    final contentText =
        MentionParser.markupToDelimitedText(contentMarkup).trim();

    // Single description field \u2014 title was removed from the design.
    final hasContent = contentText.isNotEmpty || rawContent.trim().isNotEmpty;
    final hasImages = _selectedImages.isNotEmpty;
    final hasVideos = _selectedVideos.isNotEmpty;
    final hasTags = _hashtags.isNotEmpty;

    if (!hasContent && !hasImages && !hasVideos && !hasTags) {
      AdsyToast.warning(context,
          'Please write something, or add an image, video, or hashtag');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final videoPathList = hasVideos
          ? _selectedVideos.map((v) => v['path'] as String).toList()
          : null;

      final post = await BusinessNetworkService.createPost(
        title: null,
        content: hasContent
            ? (contentText.isNotEmpty
                ? contentText
                : rawContent.replaceAll('\u00A0', ' ').trim())
            : null,
        images: hasImages ? _selectedImages : null,
        videoPaths: videoPathList,
        tags: hasTags ? _hashtags : null,
        visibility: _visibility,
        onProgress: (hasVideos || hasImages)
            ? (p) {
                if (mounted) setState(() => _uploadProgress = p);
              }
            : null,
      );

      if (mounted) {
        if (post != null) {
          Navigator.pop(context, post);
          AdsyToast.success(context, 'Post created successfully!');
        } else {
          AdsyToast.error(context, 'Failed to create post');
        }
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiError) {
          // Real backend reason — KYC opens a verification sheet, others toast.
          ApiErrorUI.show(context, message: e.message, code: e.code);
        } else if (NetworkErrorHandler.isNetworkError(e)) {
          NetworkErrorHandler.showErrorSnackbar(context, e,
              onRetry: _createPost);
        } else {
          ApiErrorUI.fromError(context, e);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;

    return Portal(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Create Post',
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
                onPressed: _isLoading ? null : _createPost,
                style: TextButton.styleFrom(
                  backgroundColor: _isLoading
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
                child: _isLoading
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: AdsyLoadingIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Post',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info & Visibility Section
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                    ),
                    child: currentUser?.profilePicture != null
                        ? ClipOval(
                            child: Image.network(
                              currentUser!.profilePicture!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person,
                                    color: Colors.grey.shade400, size: 24);
                              },
                            ),
                          )
                        : Icon(Icons.person,
                            color: Colors.grey.shade400, size: 24),
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
                                currentUser != null &&
                                        currentUser.firstName != null &&
                                        currentUser.lastName != null
                                    ? '${currentUser.firstName} ${currentUser.lastName}'
                                    : currentUser?.username ?? 'User',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (currentUser?.isPro == true) ...[
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
                        // Visibility Selector
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
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
                                    Icon(
                                      Icons.public,
                                      size: 14,
                                      color: Colors.grey.shade700,
                                    ),
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
                                    Icon(
                                      Icons.group_outlined,
                                      size: 14,
                                      color: Colors.grey.shade700,
                                    ),
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
                                    Icon(
                                      Icons.lock,
                                      size: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('Only me'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _visibility = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Post text (description) — single field; title was removed to
              // avoid confusing users about title vs description.
              // Content Input with Mentions
              FlutterMentions(
                key: _contentMentionKey,
                // Opens as a compact dropdown directly BELOW the field. The
                // list shrinks to its content (no dead space) and is styled
                // like a proper menu card.
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
                maxLines: 6,
                minLines: 3,
                // Rebuild on every keystroke so the URL preview below reacts
                // in real time as a link is typed/pasted.
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontSize: 15.5,
                  color: Colors.grey.shade800,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind? Use @ to mention someone',
                  hintStyle: TextStyle(
                    fontSize: 15.5,
                    color: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSearchChanged: (trigger, value) async {
                  if (trigger == '@') {
                    final users = await _searchUsers(value);
                    if (mounted) {
                      setState(() {
                        _mentionUserData = users;
                      });
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
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
                                  final avatarUrl =
                                      AppConfig.getAbsoluteUrl(data['photo']);
                                  if (avatarUrl.isNotEmpty) {
                                    return Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(Icons.person,
                                            color: Colors.grey.shade400,
                                            size: 20);
                                      },
                                    );
                                  }
                                  return Icon(Icons.person,
                                      color: Colors.grey.shade400, size: 20);
                                }(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                data['full_name'] ?? data['display'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
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

              Builder(
                builder: (context) {
                  final contentText =
                      _contentMentionKey.currentState?.controller?.text ?? '';
                  return FirstLinkPreview(
                    text: contentText,
                    margin: const EdgeInsets.only(top: 12),
                  );
                },
              ),

              const SizedBox(height: 18),

              // Hashtags Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tag_rounded,
                          size: 17, color: Colors.grey.shade500),
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
                  // Pill-shaped input with the add action inside it — reads as
                  // one control, the way native composers do.
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
                            controller: _hashtagController,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Type a hashtag',
                              hintStyle: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 14),
                              prefixIcon: Icon(Icons.tag,
                                  size: 18, color: Colors.grey.shade400),
                              prefixIconConstraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 0),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 11),
                            ),
                            onSubmitted: (_) => _addHashtag(),
                          ),
                        ),
                        TextButton(
                          onPressed: _addHashtag,
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
                  if (_hashtags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _hashtags.map((hashtag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
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
                                hashtag,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _removeHashtag(hashtag),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6)
                                        .withValues(alpha: 0.2),
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
              ),

              const SizedBox(height: 18),

              // Combined Media Section (Photos + Videos)
              Column(
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_selectedImages.length}/$_maxPhotos photos',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_selectedVideos.length}/$_maxVideos videos',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Compression Progress
                  if (_isCompressing) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: AdsyLoadingIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _compressionStatus,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Upload progress — video posts can take a while, so show a
                  // real percentage instead of an anonymous spinner.
                  if (_uploadProgress != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cloud_upload_outlined,
                                  size: 16, color: Color(0xFF2563EB)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _uploadProgress! >= 0.99
                                      ? 'প্রসেস হচ্ছে...'
                                      : 'আপলোড হচ্ছে... ${(_uploadProgress! * 100).round()}%',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _uploadProgress,
                              minHeight: 5,
                              backgroundColor:
                                  const Color(0xFF3B82F6).withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF2563EB)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Combined Media Grid (Images + Videos)
                  if (_selectedImages.isNotEmpty ||
                      _selectedVideos.isNotEmpty) ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: 1,
                      ),
                      itemCount:
                          _selectedImages.length + _selectedVideos.length,
                      itemBuilder: (context, index) {
                        // Show images first, then videos
                        if (index < _selectedImages.length) {
                          final image = _selectedImages[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(
                                  base64Decode(image.split(',')[1]),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Video item
                          final videoIndex = index - _selectedImages.length;
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.grey.shade800,
                                  child: const Center(
                                    child: Icon(
                                      Icons.play_circle_fill,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.videocam,
                                          color: Colors.white, size: 10),
                                      SizedBox(width: 2),
                                      Text(
                                        'VIDEO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeVideo(videoIndex),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Direct photo / video actions — no intermediate bottom
                  // sheet, the way native composers work.
                  Row(
                    children: [
                      Expanded(
                        child: _mediaActionButton(
                          icon: Icons.photo_library_outlined,
                          iconColor: const Color(0xFF16A34A),
                          label: 'ছবি',
                          onTap: _pickImage,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _mediaActionButton(
                          icon: Icons.videocam_outlined,
                          iconColor: const Color(0xFFDC2626),
                          label: 'ভিডিও',
                          onTap: _pickVideo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Limits, stated plainly so nobody discovers them by error.
                  Text(
                    'প্রতি পোস্টে সর্বোচ্চ $_maxPhotos টি ছবি এবং $_maxVideos টি ভিডিও দেওয়া যাবে, এবং প্রতি ভিডিও সর্বোচ্চ ৩ মিনিটের মধ্যে হতে হবে',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),

              // Safe area bottom padding for devices with gesture navigation
              SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
            ],
          ),
        ),
      ),
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
}
