import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../services/business_network_service.dart';
import '../../models/business_network_models.dart';
import '../../services/auth_service.dart';
import '../../utils/image_compressor.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  List<String> _selectedImages = [];
  List<String> _hashtags = [];
  String _visibility = 'public'; // public or private
  bool _isLoading = false;
  bool _isCompressing = false;
  int _compressionProgress = 0;
  String _compressionStatus = '';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
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
    // Check if at least one field has content
    final hasTitle = _titleController.text.trim().isNotEmpty;
    final hasContent = _contentController.text.trim().isNotEmpty;
    final hasImages = _selectedImages.isNotEmpty;
    final hasTags = _hashtags.isNotEmpty;
    
    if (!hasTitle && !hasContent && !hasImages && !hasTags) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least a title, content, image, or hashtag'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final post = await BusinessNetworkService.createPost(
        title: hasTitle ? _titleController.text.trim() : null,
        content: hasContent ? _contentController.text.trim() : null,
        images: hasImages ? _selectedImages : null,
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
    
    return Scaffold(
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

            // Title Input
            TextField(
              controller: _titleController,
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
              maxLines: null,
            ),
            
            const SizedBox(height: 12),

            // Content Input
            TextField(
              controller: _contentController,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Share more details...',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
              minLines: 3,
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

            // Media Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.photo_library_rounded, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Photos',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedImages.length >= 12
                            ? Colors.orange.shade50
                            : const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedImages.length >= 12
                              ? Colors.orange.shade300
                              : const Color(0xFF3B82F6).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${_selectedImages.length}/12',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _selectedImages.length >= 12
                              ? Colors.orange.shade700
                              : const Color(0xFF3B82F6),
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
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _compressionStatus,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: _compressionProgress / 100,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_compressionProgress%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Image Grid
                  if (_selectedImages.isNotEmpty) ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: 1,
                      ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
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
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  
                  // Add Image Button
                  if (_selectedImages.length < 12)
                    InkWell(
                      onTap: _pickImage,
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
                              'Add Photos',
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
                ],
              ),

            // Safe area bottom padding for devices with gesture navigation
            SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
          ],
        ),
      ),
    );
  }
}
