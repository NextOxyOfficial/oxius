import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/classified_post.dart';
import '../services/classified_post_service.dart';
import '../services/api_service.dart';

class ClassifiedPostDetailsScreen extends StatefulWidget {
  final String postId;
  final String postSlug;

  const ClassifiedPostDetailsScreen({
    Key? key,
    required this.postId,
    required this.postSlug,
  }) : super(key: key);

  @override
  State<ClassifiedPostDetailsScreen> createState() => _ClassifiedPostDetailsScreenState();
}

class _ClassifiedPostDetailsScreenState extends State<ClassifiedPostDetailsScreen> {
  late final ClassifiedPostService _postService;
  
  ClassifiedPost? _post;
  bool _isLoading = true;
  bool _showPhone = false;
  int _currentImageIndex = 0;
  
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _postService = ClassifiedPostService(baseUrl: ApiService.baseUrl);
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() => _isLoading = true);
    
    try {
      final post = await _postService.fetchPostById(widget.postSlug);
      if (mounted && post != null) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load post: $e')),
        );
      }
    }
  }

  String _getNumericServiceId() {
    if (_post == null) return '';
    
    int hash = 0;
    final str = _post!.id.toString();
    
    for (int i = 0; i < str.length; i++) {
      final char = str.codeUnitAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    
    final positiveHash = hash.abs();
    final numericId = positiveHash.toString().padLeft(6, '0').substring(0, 10);
    
    return numericId;
  }

  void _sharePost() {
    if (_post == null) return;
    
    final shareUrl = 'https://adsyclub.com/classified-categories/details/${_post!.slug ?? _post!.id}';
    Share.share(
      '${_post!.title}\n\n$shareUrl',
      subject: _post!.title,
    );
  }

  void _showShareDialog() {
    if (_post == null) return;
    
    final shareUrl = 'https://adsyclub.com/classified-categories/details/${_post!.slug ?? _post!.id}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share this service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shareUrl,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard')),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Share via', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildShareButton('Facebook', Icons.facebook, () {
                  launchUrl(Uri.parse('https://www.facebook.com/sharer/sharer.php?u=$shareUrl'));
                  Navigator.pop(context);
                }),
                _buildShareButton('WhatsApp', Icons.message, () {
                  launchUrl(Uri.parse('https://api.whatsapp.com/send?text=${_post!.title} $shareUrl'));
                  Navigator.pop(context);
                }),
                _buildShareButton('Email', Icons.email, () {
                  launchUrl(Uri.parse('mailto:?subject=${_post!.title}&body=$shareUrl'));
                  Navigator.pop(context);
                }),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    String? reportReason;
    final TextEditingController detailsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please select a reason for reporting this service:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  value: 'spam',
                  groupValue: reportReason,
                  onChanged: (value) => setDialogState(() => reportReason = value),
                  title: const Text('Spam or misleading', style: TextStyle(fontSize: 14)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'inappropriate',
                  groupValue: reportReason,
                  onChanged: (value) => setDialogState(() => reportReason = value),
                  title: const Text('Inappropriate content', style: TextStyle(fontSize: 14)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'fraud',
                  groupValue: reportReason,
                  onChanged: (value) => setDialogState(() => reportReason = value),
                  title: const Text('Fraudulent or scam', style: TextStyle(fontSize: 14)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'other',
                  groupValue: reportReason,
                  onChanged: (value) => setDialogState(() => reportReason = value),
                  title: const Text('Other', style: TextStyle(fontSize: 14)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  decoration: const InputDecoration(
                    hintText: 'Additional details (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reportReason != null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted. We will review it shortly.'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _contactProvider() {
    if (_post?.user == null) return;
    
    final user = _post!.user!;
    
    if (user.phone != null) {
      launchUrl(Uri.parse('tel:${user.phone}'));
    } else if (user.email != null) {
      launchUrl(Uri.parse('mailto:${user.email}'));
    } else if (user.whatsappLink != null) {
      launchUrl(Uri.parse(user.whatsappLink!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact information not available')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Post not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _post!.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main content area
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gallery (60%)
                      Expanded(
                        flex: 3,
                        child: _buildImageGallery(),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Service info (40%)
                      Expanded(
                        flex: 2,
                        child: _buildServiceInfo(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Details section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service details (66%)
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildDetailsCard(),
                            const SizedBox(height: 16),
                            _buildSafetyTipsCard(),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Provider info (33%)
                      Expanded(
                        flex: 1,
                        child: _buildProviderCard(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = _post!.medias?.where((m) => m.image != null).toList() ?? [];
    final hasImages = images.isNotEmpty;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Main image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                if (!hasImages && _post!.categoryDetails?.image == null)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[100]!, Colors.grey[200]!],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No Photo Uploaded',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemCount: hasImages ? images.length : 1,
                    itemBuilder: (context, index) {
                      final imageUrl = hasImages
                          ? images[index].image!
                          : _post!.categoryDetails!.image!;
                      
                      return ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.error,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),
                
                // Navigation buttons
                if (images.length > 1) ...[
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        onPressed: () {
                          if (_currentImageIndex > 0) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        icon: const Icon(Icons.chevron_left),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        onPressed: () {
                          if (_currentImageIndex < images.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        icon: const Icon(Icons.chevron_right),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                  
                  // Page indicator
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${images.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Thumbnail gallery
          if (images.length > 1)
            Container(
              height: 80,
              padding: const EdgeInsets.all(12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 64,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _currentImageIndex == index
                              ? const Color(0xFF10B981)
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: images[index].image!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceInfo() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service ID and Views
            Row(
              children: [
                Text(
                  'Service ID: ${_getNumericServiceId()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.visibility, size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(
                  _post!.viewsCount.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Price
            Text(
              _post!.displayPrice,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF10B981),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Location
            _buildInfoRow(
              Icons.location_on,
              'Location',
              [_post!.upazila, _post!.city, _post!.state]
                  .where((e) => e != null && e.isNotEmpty)
                  .join(', '),
            ),
            
            const SizedBox(height: 12),
            
            // Category
            if (_post!.categoryDetails != null)
              _buildInfoRow(
                Icons.category,
                'Category',
                _post!.categoryDetails!.title,
              ),
            
            const SizedBox(height: 12),
            
            // Posted date
            _buildInfoRow(
              Icons.calendar_today,
              'Posted',
              _post!.getRelativeTime(),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showReportDialog,
                    icon: const Icon(Icons.flag, size: 18),
                    label: const Text('Report'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showShareDialog,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text(
                  'Service Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_post!.instructions != null)
              Html(
                data: _post!.instructions!,
                style: {
                  "body": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                },
              )
            else
              const Text('No description provided.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTipsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text(
                  'Safety Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSafetyTip('Meet in a safe, public place'),
            _buildSafetyTip('Check the item before purchase'),
            _buildSafetyTip('Pay only after collecting the item'),
            _buildSafetyTip('Don\'t share sensitive information'),
            _buildSafetyTip('Report suspicious activity'),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 18,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard() {
    final user = _post!.user;
    
    if (user == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Provider information not available'),
        ),
      );
    }
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text(
                  'Service Provider',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Profile picture and name
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                  backgroundImage: user.profilePicture != null
                      ? CachedNetworkImageProvider(user.profilePicture!)
                      : null,
                  child: user.profilePicture == null
                      ? Text(
                          user.displayName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      if (user.username != null)
                        Text(
                          '@${user.username}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // About
            if (user.about != null) ...[
              Html(
                data: user.about!,
                style: {
                  "body": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(14),
                  ),
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Contact info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.email != null) ...[
                    _buildContactRow(Icons.email, user.email!),
                    const SizedBox(height: 8),
                  ],
                  if (user.phone != null) ...[
                    _buildContactRow(
                      Icons.phone,
                      _showPhone ? user.phone! : user.maskedPhone,
                      trailing: IconButton(
                        icon: Icon(
                          _showPhone ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() => _showPhone = !_showPhone);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (user.createdAt != null)
                    _buildContactRow(
                      Icons.calendar_today,
                      'Member since ${user.createdAt!.year}',
                    ),
                ],
              ),
            ),
            
            // Social links
            if (user.faceLink != null || user.instagramLink != null || user.whatsappLink != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  if (user.faceLink != null)
                    IconButton(
                      icon: const Icon(Icons.facebook),
                      onPressed: () => launchUrl(Uri.parse(user.faceLink!)),
                      color: const Color(0xFF1877F2),
                    ),
                  if (user.instagramLink != null)
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () => launchUrl(Uri.parse(user.instagramLink!)),
                      color: const Color(0xFFE4405F),
                    ),
                  if (user.whatsappLink != null)
                    IconButton(
                      icon: const Icon(Icons.message),
                      onPressed: () => launchUrl(Uri.parse(user.whatsappLink!)),
                      color: const Color(0xFF25D366),
                    ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Contact button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _contactProvider,
                icon: const Icon(Icons.phone),
                label: const Text('Contact Provider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
