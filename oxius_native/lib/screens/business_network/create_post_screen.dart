import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'dart:convert';
import 'dart:io';
import 'package:video_player/video_player.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_search_service.dart';
import '../../utils/image_compressor.dart';
import '../../widgets/link_preview_card.dart';
import '../../config/app_config.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _hashtagController = TextEditingController();
  final GlobalKey<FlutterMentionsState> _titleMentionKey = GlobalKey<FlutterMentionsState>();
  final GlobalKey<FlutterMentionsState> _contentMentionKey = GlobalKey<FlutterMentionsState>();
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _mentionUserData = [];
  
  List<String> _selectedImages = [];
  List<Map<String, dynamic>> _selectedVideos = []; // {path, name}
  List<String> _hashtags = [];
  String _visibility = 'public'; // public or private
  bool _isLoading = false;
  bool _isCompressing = false;
  int _compressionProgress = 0;
  String _compressionStatus = '';
  
  static const int _maxPhotos = 12;
  static const int _maxVideos = 2;
  static const int _maxVideoDurationSeconds = 120; // 2 minutes

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
      return users.map((user) => {
        'id': user.id.toString(),
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
  void dispose() {
    _hashtagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Check if we've reached the limit
      if (_selectedImages.length >= 12) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 12 photos allowed'),
              backgroundColor: Colors.orange,
            ),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Only $remainingSlots photos added (12 max)'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        setState(() {
          _isCompressing = true;
          _compressionProgress = 0;
          _compressionStatus = 'Compressing images...';
        });

        // Compress images using the image compressor utility
        for (int i = 0; i < imagesToAdd.length; i++) {
          final image = imagesToAdd[i];
          
          setState(() {
            _compressionProgress = ((i + 1) / imagesToAdd.length * 100).round();
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${imagesToAdd.length} images compressed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isCompressing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum $_maxVideos videos allowed per post'),
            backgroundColor: Colors.orange,
          ),
        );
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

      // Enforce duration limit (max 2 minutes)
      try {
        final controller = VideoPlayerController.file(File(video.path));
        await controller.initialize();
        final duration = controller.value.duration;
        await controller.dispose();

        if (duration > const Duration(seconds: _maxVideoDurationSeconds)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video is too long. Maximum length is 2 minutes.'),
                backgroundColor: Colors.orange,
              ),
            );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Video added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCompressing = false;
        _compressionStatus = '';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeVideo(int index) {
    setState(() {
      _selectedVideos.removeAt(index);
    });
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Upload Media',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 20),
              // Photos option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library_rounded, color: Colors.blue.shade600, size: 24),
                ),
                title: const Text('Photos', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${_selectedImages.length}/$_maxPhotos selected', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                enabled: _selectedImages.length < _maxPhotos,
                onTap: _selectedImages.length < _maxPhotos ? () {
                  Navigator.pop(context);
                  _pickImage();
                } : null,
              ),
              const SizedBox(height: 8),
              // Videos option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.videocam_rounded, color: Colors.purple.shade600, size: 24),
                ),
                title: const Text('Video', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${_selectedVideos.length}/$_maxVideos selected (max 2 min)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                enabled: _selectedVideos.length < _maxVideos,
                onTap: _selectedVideos.length < _maxVideos ? () {
                  Navigator.pop(context);
                  _pickVideo();
                } : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _addHashtag() {
    final hashtag = _hashtagController.text.trim();
    if (hashtag.isEmpty) return;
    
    // Remove # if user added it
    final cleanHashtag = hashtag.startsWith('#') ? hashtag.substring(1) : hashtag;
    
    if (!_hashtags.contains(cleanHashtag) && cleanHashtag.isNotEmpty) {
      setState(() {
        _hashtags.add(cleanHashtag);
        _hashtagController.clear();
      });
    }
  }

  void _removeHashtag(String hashtag) {
    setState(() {
      _hashtags.remove(hashtag);
    });
  }

  Future<void> _createPost() async {
    // Get title and content from FlutterMentions and convert non-breaking spaces back to regular spaces
    final rawTitle = _titleMentionKey.currentState?.controller?.text ?? '';
    final titleText = rawTitle.replaceAll('\u00A0', ' ').trim();
    final rawContent = _contentMentionKey.currentState?.controller?.text ?? '';
    final contentText = rawContent.replaceAll('\u00A0', ' ').trim();
    
    // Check if at least one field has content
    final hasTitle = titleText.isNotEmpty;
    final hasContent = contentText.isNotEmpty;
    final hasImages = _selectedImages.isNotEmpty;
    final hasVideos = _selectedVideos.isNotEmpty;
    final hasTags = _hashtags.isNotEmpty;
    
    if (!hasTitle && !hasContent && !hasImages && !hasVideos && !hasTags) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least a title, content, image, video, or hashtag'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final videoPathList = hasVideos
          ? _selectedVideos.map((v) => v['path'] as String).toList()
          : null;
      
      final post = await BusinessNetworkService.createPost(
        title: hasTitle ? titleText : null,
        content: hasContent ? contentText : null,
        images: hasImages ? _selectedImages : null,
        videoPaths: videoPathList,
        tags: hasTags ? _hashtags : null,
        visibility: _visibility,
      );

      if (mounted) {
        if (post != null) {
          Navigator.pop(context, post);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create post'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isLoading ? null : _createPost,
              style: TextButton.styleFrom(
                backgroundColor: _isLoading 
                    ? Colors.grey.shade200
                    : const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
                  width: 48,
                  height: 48,
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
                              return Icon(Icons.person, color: Colors.grey.shade400, size: 24);
                            },
                          ),
                        )
                      : Icon(Icons.person, color: Colors.grey.shade400, size: 24),
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
                              currentUser != null && currentUser.firstName != null && currentUser.lastName != null
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                  const Text('Private'),
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
            
            const SizedBox(height: 24),

            // Title Input with Mentions
            FlutterMentions(
              key: _titleMentionKey,
              suggestionPosition: SuggestionPosition.Bottom,
              maxLines: 5,
              minLines: 1,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1.3,
                letterSpacing: -0.5,
              ),
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                hintStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade300,
                  letterSpacing: -0.5,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
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
                                      return Icon(Icons.person, color: Colors.grey.shade400, size: 20);
                                    },
                                  );
                                }
                                return Icon(Icons.person, color: Colors.grey.shade400, size: 20);
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
            
            const SizedBox(height: 12),

            // Content Input with Mentions
            FlutterMentions(
              key: _contentMentionKey,
              suggestionPosition: SuggestionPosition.Bottom,
              maxLines: 10,
              minLines: 3,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Share more details... Use @ to mention someone',
                hintStyle: TextStyle(
                  fontSize: 16,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
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
                                      return Icon(Icons.person, color: Colors.grey.shade400, size: 20);
                                    },
                                  );
                                }
                                return Icon(Icons.person, color: Colors.grey.shade400, size: 20);
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
                final titleText = _titleMentionKey.currentState?.controller?.text ?? '';
                final contentText = _contentMentionKey.currentState?.controller?.text ?? '';
                final text = '$titleText\n$contentText';
                return FirstLinkPreview(
                  text: text,
                  margin: const EdgeInsets.only(top: 12),
                );
              },
            ),
            
            const SizedBox(height: 24),

            // Hashtags Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tag_rounded, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Add Hashtags',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _hashtagController,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Type a hashtag',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                            prefixIcon: Icon(Icons.tag, size: 20, color: Colors.grey.shade400),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onSubmitted: (_) => _addHashtag(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _addHashtag,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: const Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_hashtags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _hashtags.map((hashtag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withOpacity(0.2),
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
                                  color: const Color(0xFF3B82F6).withOpacity(0.2),
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
            
            const SizedBox(height: 24),

            // Combined Media Section (Photos + Videos)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.perm_media_rounded, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Media',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
                
                // Combined Media Grid (Images + Videos)
                if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty) ...[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 1,
                    ),
                    itemCount: _selectedImages.length + _selectedVideos.length,
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
                                    color: Colors.black.withOpacity(0.7),
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.videocam, color: Colors.white, size: 10),
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
                                    color: Colors.black.withOpacity(0.7),
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
                
                // Single Upload Media Button
                InkWell(
                  onTap: _showMediaPicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 22, color: Colors.grey.shade600),
                        const SizedBox(width: 10),
                        Text(
                          'Upload Media',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Helper text
                Text(
                  'Max $_maxPhotos photos + $_maxVideos videos (2 min)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
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
}
