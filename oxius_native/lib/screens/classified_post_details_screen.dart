import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/classified_post.dart';
import '../services/classified_post_service.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

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
    final numericId = positiveHash.toString().padLeft(10, '0');
    
    // Ensure we only return up to 10 digits
    return numericId.length > 10 ? numericId.substring(0, 10) : numericId;
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            _post!.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 22),
            onPressed: _showShareDialog,
            tooltip: 'Share',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Gallery at Top (only if images uploaded)
            if (_post!.medias != null && _post!.medias!.any((m) => m.image != null))
              _buildImageGallery(),
            
            // Content Section
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and Quick Info Bar
                  _buildPriceBar(),
                  
                  const Divider(height: 1),
                  
                  // Title and Basic Info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                [_post!.upazila, _post!.city, _post!.state]
                                    .where((e) => e != null && e.isNotEmpty)
                                    .join(', '),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Views, ID, and Report
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.visibility_rounded, size: 12, color: Color(0xFF6B7280)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${_post!.viewsCount} views',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ID: ${_getNumericServiceId()}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: _showReportDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.flag_outlined, size: 12, color: Color(0xFFDC2626)),
                                    const SizedBox(width: 3),
                                    const Text(
                                      'Report',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFDC2626),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, thickness: 1),
            
            // Description Section
            if (_post!.instructions != null) ...[
              _buildDescriptionCard(),
              const Divider(height: 1, thickness: 1),
            ],
            
            // Provider Card
            _buildProviderCard(),
            
            const Divider(height: 1, thickness: 1),
            
            // Safety Tips
            _buildSafetyTipsCard(),
            
            const SizedBox(height: 70), // Bottom padding for contact bar
          ],
        ),
      ),
      bottomNavigationBar: _buildContactBar(),
    );
  }

  Widget _buildImageGallery() {
    final images = _post!.medias?.where((m) => m.image != null).toList() ?? [];
    final hasImages = images.isNotEmpty;
    
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Main image
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              children: [
                if (!hasImages && _post!.categoryDetails?.image == null)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[800]!, Colors.grey[900]!],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image, size: 64, color: Colors.grey[600]),
                          const SizedBox(height: 8),
                          Text(
                            'No Photo Uploaded',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[400],
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
                      final rawImageUrl = hasImages
                          ? images[index].image!
                          : _post!.categoryDetails!.image!;
                      
                      // Convert to absolute URL using AppConfig
                      final imageUrl = AppConfig.getAbsoluteUrl(rawImageUrl);
                      print('🖼️ Classified Details - Raw: $rawImageUrl → Absolute: $imageUrl');
                      
                      return CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          print('❌ Classified Details - Image load error for $url: $error');
                          return Container(
                            color: Colors.grey[800],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_rounded, color: Colors.grey[400], size: 48),
                                const SizedBox(height: 8),
                                Text(
                                  'Image failed to load',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                
                // Navigation buttons
                if (images.length > 1) ...[
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (_currentImageIndex > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (_currentImageIndex < images.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  
                  // Page indicator (bottom center)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${images.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF059669).withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _post!.displayPrice,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _post!.getRelativeTime(),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Html(
            data: _post!.instructions!,
            style: {
              "body": Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(13),
                lineHeight: const LineHeight(1.5),
                color: const Color(0xFF374151),
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _contactProvider,
              icon: const Icon(Icons.phone_rounded, size: 18),
              label: const Text('Call Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                if (_post!.user?.whatsappLink != null) {
                  launchUrl(Uri.parse(_post!.user!.whatsappLink!));
                } else if (_post!.user?.phone != null) {
                  launchUrl(Uri.parse('https://wa.me/${_post!.user!.phone}'));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('WhatsApp not available')),
                  );
                }
              },
              icon: const Icon(Icons.message_rounded, size: 18),
              label: const Text('Chat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSafetyTipsCard() {
    return Container(
      color: const Color(0xFFFFF3CD),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text(
                'Safety Tips',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSafetyTip('Meet in a safe, public place'),
          _buildSafetyTip('Check the item before purchase'),
          _buildSafetyTip('Pay only after collecting the item'),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF92400E),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                height: 1.3,
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
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: const Text('Provider information not available'),
      );
    }
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Provider',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          
          // Profile row
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                backgroundImage: user.profilePicture != null
                    ? CachedNetworkImageProvider(user.profilePicture!)
                    : null,
                child: user.profilePicture == null
                    ? Text(
                        user.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [_post!.upazila, _post!.city, _post!.state]
                                .where((e) => e != null && e.isNotEmpty)
                                .join(', '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Posted ${_post!.getRelativeTime()}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // About
          if (user.about != null) ...[
            Html(
              data: user.about!,
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(13),
                ),
              },
            ),
            const SizedBox(height: 16),
          ],
          
          // Contact info
          Container(
              padding: const EdgeInsets.all(12),
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
              icon: const Icon(Icons.phone_rounded, size: 18),
              label: const Text('Contact Provider', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
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
