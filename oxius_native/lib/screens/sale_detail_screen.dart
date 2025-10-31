import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/sale_post.dart';
import '../services/sale_post_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/adsyconnect_service.dart';
import 'adsy_connect_chat_interface.dart';

/// Sale Post Detail Screen - View full post details with image gallery and all features
class SaleDetailScreen extends StatefulWidget {
  final String? slug;
  final String? id;

  const SaleDetailScreen({
    Key? key,
    this.slug,
    this.id,
  }) : super(key: key);

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  late SalePostService _postService;
  SalePost? _post;
  List<SalePost> _similarPosts = [];
  bool _isLoading = true;
  bool _isLoadingSimilar = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  
  // Dialog states
  bool _showShareDialog = false;
  bool _showReportDialog = false;
  String _reportReason = '';
  String _reportDetails = '';
  bool _copied = false;
  bool _showPhone = false;

  @override
  void initState() {
    super.initState();
    _postService = SalePostService(baseUrl: ApiService.baseUrl);
    _fetchPostDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchPostDetails() async {
    if (widget.slug == null && widget.id == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final post = await _postService.fetchPostBySlug(widget.slug ?? widget.id!);
      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
        // Fetch similar posts after getting the main post
        if (post != null && post.categoryId != null) {
          _fetchSimilarPosts(post.categoryId!);
        }
      }
    } catch (e) {
      print('Error fetching post details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _fetchSimilarPosts(String categoryId) async {
    setState(() => _isLoadingSimilar = true);
    try {
      print('Fetching similar posts for category: $categoryId');
      final response = await _postService.fetchPosts(
        categoryId: categoryId,
        pageSize: 8, // Fetch more to ensure we have 4 after filtering current post
      );
      print('Fetched ${response.results.length} posts');
      if (mounted) {
        final filtered = response.results.where((p) => p.id != _post?.id).take(4).toList();
        print('After filtering current post: ${filtered.length} similar posts');
        setState(() {
          _similarPosts = filtered;
          _isLoadingSimilar = false;
        });
      }
    } catch (e) {
      print('Error fetching similar posts: $e');
      if (mounted) {
        setState(() => _isLoadingSimilar = false);
      }
    }
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,##,###');
    return '৳${formatter.format(price)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM d, yyyy').format(date);
  }

  void _sharePost() {
    if (_post != null) {
      Share.share(
        'Check out this product: ${_post!.title}\nPrice: ${_formatPrice(_post!.price)}\nView more details in our app!',
        subject: _post!.title,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: _post != null
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  _post!.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              )
            : const Text(
                'Product Details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 22),
            onPressed: () => setState(() => _showShareDialog = true),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 22),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.flag_outlined, color: Color(0xFF10B981)),
                        title: const Text('Report Ad'),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _showReportDialog = true);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.share, color: Color(0xFF10B981)),
                        title: const Text('Share'),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _showShareDialog = true);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : _post == null
                  ? _buildErrorState()
                  : _buildContent(),
          
          // Share Dialog
          if (_showShareDialog) _buildShareDialog(),
          
          // Report Dialog  
          if (_showReportDialog) _buildReportDialog(),
        ],
      ),
      bottomNavigationBar: _post != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Post not found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final post = _post!;
    final images = post.images ?? [];
    final hasImages = images.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Gallery
          if (hasImages) _buildImageGallery(images) else _buildNoImagePlaceholder(),

          // Product Info Card with Financing Banner
          _buildProductInfoCard(),

          const SizedBox(height: 8),

          // Description
          _buildDescriptionSection(),

          const SizedBox(height: 8),

          // Seller Info
          _buildSellerInfoCard(),

          const SizedBox(height: 8),

          // Safety Tips
          _buildSafetyTips(),

          const SizedBox(height: 8),

          // Similar Listings
          _buildSimilarListings(),

          const SizedBox(height: 80), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<SaleImage> images) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Main Image with PageView
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: images[index].image,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, size: 80),
                      ),
                    );
                  },
                ),
                
                // Navigation Buttons
                if (images.length > 1) ...[
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left, size: 32),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.5),
                        ),
                        onPressed: () {
                          if (_currentImageIndex > 0) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right, size: 32),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.5),
                        ),
                        onPressed: () {
                          if (_currentImageIndex < images.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
                
                // Image Counter
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Thumbnail Gallery
          if (images.length > 1)
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final isSelected = _currentImageIndex == index;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: CachedNetworkImage(
                          imageUrl: images[index].image,
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

  Widget _buildProductInfoCard() {
    final post = _post!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with Share button
          Row(
            children: [
              Expanded(
                child: Text(
                  _capitalizeTitle(post.title),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 20, color: Color(0xFF9CA3AF)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _showShareDialog = true),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Ad ID and Date
          Row(
            children: [
              Text(
                'Ad ID: ${post.id}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey.shade600),
              const SizedBox(width: 3),
              Text(
                _formatDate(post.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Price
          Text(
            post.price > 0 ? _formatPrice(post.price) : 'Negotiable',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
              letterSpacing: -0.3,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 2-column Grid Info
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
            children: [
              _buildInfoGridItem(Icons.tag_rounded, 'Category', post.categoryName ?? 'N/A'),
              _buildInfoGridItem(Icons.layers_rounded, 'Sub-Category', post.subcategoryName ?? 'N/A'),
              _buildInfoGridItem(Icons.shield_rounded, 'Condition', _capitalizeCondition(post.condition)),
              _buildInfoGridItem(Icons.location_on_rounded, 'Delivery to', 
                post.division != null && post.district != null && post.area != null
                  ? '${post.division}, ${post.district}, ${post.area}'
                  : 'All Over Bangladesh'),
            ],
          ),
          
          // Financing Banner
          const SizedBox(height: 12),
          _buildFinancingBanner(post.price),
          
          // Report and Share buttons
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showReportDialog = true),
                  icon: const Icon(Icons.flag_outlined, size: 11, color: Color(0xFF6B7280)),
                  label: const Text(
                    'Report Ad',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: BorderSide(color: Colors.grey.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showShareDialog = true),
                  icon: const Icon(Icons.share_rounded, size: 11, color: Color(0xFF6B7280)),
                  label: const Text(
                    'Share',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: BorderSide(color: Colors.grey.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _capitalizeTitle(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _buildInfoGridItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF10B981)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF1F2937),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _capitalizeCondition(String condition) {
    return condition.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Widget _buildFinancingBanner(double price) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Need financing?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Get Free consultation from our experts',
                                style: TextStyle(
                                  color: Color(0xFFD1FAE5),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ...List.generate(
                                    3,
                                    (index) => Container(
                                      margin: const EdgeInsets.only(right: 4),
                                      height: 24,
                                      width: 24,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          index == 0 ? '\$' : index == 1 ? '%' : '✓',
                                          style: const TextStyle(
                                            color: Color(0xFF059669),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Flexible(
                                    child: Text(
                                      'Competitive rates available',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Navigate to contact page
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Contact feature coming soon!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF059669),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Contact Support',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
              ],
            ),
          ),
          Container(
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF059669),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final post = _post!;
    if (post.description == null || post.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt_rounded, color: const Color(0xFF10B981), size: 18),
              const SizedBox(width: 6),
              const Text(
                'Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.description!.replaceAll(RegExp(r'<p>|</p>'), '').trim(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          
          // Address Section
          if (post.detailedAddress != null && post.detailedAddress!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade100, thickness: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_rounded, color: const Color(0xFF10B981), size: 15),
                const SizedBox(width: 6),
                const Text(
                  'Item/Property Address',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.detailedAddress!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSafetyTips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_rounded, color: const Color(0xFF10B981), size: 18),
              const SizedBox(width: 6),
              const Text(
                'Safety Tips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSafetyTip('Meet in a safe, public place'),
          _buildSafetyTip('Don\'t pay or transfer money in advance'),
          _buildSafetyTip('Inspect the item before purchasing'),
          _buildSafetyTip('Be wary of unrealistic offers or prices'),
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
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, size: 11, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfoCard() {
    final post = _post!;
    if (post.user == null) return const SizedBox.shrink();

    final user = post.user!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.person_rounded, color: const Color(0xFF10B981), size: 18),
              const SizedBox(width: 6),
              const Text(
                'Seller Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Profile Section
          Row(
            children: [
              // Avatar
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipOval(
                  child: user.profilePicture != null
                      ? CachedNetworkImage(
                          imageUrl: user.profilePicture!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Text(
                                user.displayName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Text(
                              user.displayName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Name and Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/seller-profile',
                                arguments: {'userId': user.id},
                              );
                            },
                            child: Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (user.kyc == true) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                        ],
                        if (user.isPro == true) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.shield, size: 10, color: Colors.white),
                                SizedBox(width: 2),
                                Text(
                                  'Pro',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since ${_formatDate(user.dateJoined)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                // Total Listings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Listings',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${user.salePostCount ?? 0}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Phone Number
                if (user.phone != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Phone',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                _showPhone ? user.phone! : _maskPhoneNumber(user.phone!),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                                textAlign: TextAlign.right,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showPhone = !_showPhone;
                                });
                              },
                              child: Icon(
                                _showPhone ? Icons.visibility_off : Icons.visibility,
                                size: 16,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // View More Listings Link (text link, not button)
          InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/seller-profile',
                arguments: {'userId': user.id},
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'View more listings from this seller',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _maskPhoneNumber(String phone) {
    if (phone.length <= 4) return phone;
    return phone.substring(0, 3) + '****' + phone.substring(phone.length - 2);
  }

  String _formatMemberSince(DateTime date) {
    return '${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildSimilarListings() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.grid_view, color: const Color(0xFF10B981), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: const Text(
                          'Similar Listings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/sale');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'View all',
                        style: TextStyle(fontSize: 13, color: Color(0xFF10B981)),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 12, color: Color(0xFF10B981)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _isLoadingSimilar
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  ),
                )
              : _similarPosts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No similar listings found',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    )
                  : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _similarPosts.length > 4 ? 4 : _similarPosts.length,
            itemBuilder: (context, index) {
              final post = _similarPosts[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/sale/detail',
                    arguments: {'slug': post.slug},
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        child: AspectRatio(
                          aspectRatio: 1.1,
                          child: post.images != null && post.images!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: post.images![0].image,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey.shade100,
                                    child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey.shade400),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey.shade100,
                                  child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
                                ),
                        ),
                      ),
                      // Info
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/sale/detail',
                                  arguments: {'slug': post.slug},
                                );
                              },
                              child: Text(
                                _capitalizeTitle(post.title),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (post.division != null && post.district != null && post.area != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${post.division}, ${post.district}, ${post.area}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    post.price > 0 ? _formatPrice(post.price) : 'Negotiable',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 14,
                                  color: Colors.grey.shade400,
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
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      height: 300,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.image, size: 80, color: Colors.grey),
      ),
    );
  }

  Widget _buildBottomBar() {
    final post = _post!;
    final user = post.user;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (user?.phone != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement call functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Call: ${user!.phone}')),
                  );
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          if (user?.phone != null) const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                if (!AuthService.isAuthenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please login to chat with seller'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                  return;
                }
                
                final user = _post?.user;
                if (user != null) {
                  await _openChatWithSeller(user);
                }
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareDialog() {
    final post = _post!;
    final shareUrl = 'https://oxius.com/sale/${post.slug}';
    
    return GestureDetector(
      onTap: () => setState(() => _showShareDialog = false),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Share this listing',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _showShareDialog = false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Copy Link
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.link, color: Color(0xFF10B981)),
                    ),
                    title: const Text('Copy Link', style: TextStyle(fontSize: 14)),
                    trailing: _copied 
                        ? const Icon(Icons.check, color: Color(0xFF10B981))
                        : null,
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: shareUrl));
                      setState(() => _copied = true);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) setState(() => _copied = false);
                      });
                    },
                  ),
                  
                  const Divider(height: 1),
                  
                  // Social Media Options
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                    ),
                    title: const Text('Share on Facebook', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      // TODO: Implement Facebook share
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Facebook share coming soon!')),
                      );
                    },
                  ),
                  
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chat, color: Color(0xFF25D366)),
                    ),
                    title: const Text('Share on WhatsApp', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      // TODO: Implement WhatsApp share
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('WhatsApp share coming soon!')),
                      );
                    },
                  ),
                  
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DA1F2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.share, color: Color(0xFF1DA1F2)),
                    ),
                    title: const Text('Share on Twitter', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      // TODO: Implement Twitter share
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Twitter share coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportDialog() {
    return GestureDetector(
      onTap: () => setState(() {
        _showReportDialog = false;
        _reportReason = '';
        _reportDetails = '';
      }),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Report this listing',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _showReportDialog = false;
                          _reportReason = '';
                          _reportDetails = '';
                        }),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Select a reason:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildReportOption('Spam or misleading', 'spam'),
                  _buildReportOption('Inappropriate content', 'inappropriate'),
                  _buildReportOption('Duplicate listing', 'duplicate'),
                  _buildReportOption('Fraudulent', 'fraud'),
                  _buildReportOption('Other', 'other'),
                  
                  if (_reportReason == 'other') ...[
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Please provide details...',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                      style: const TextStyle(fontSize: 12),
                      onChanged: (value) => _reportDetails = value,
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() {
                            _showReportDialog = false;
                            _reportReason = '';
                            _reportDetails = '';
                          }),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _reportReason.isEmpty ? null : () {
                            // TODO: Implement report submission
                            setState(() {
                              _showReportDialog = false;
                              _reportReason = '';
                              _reportDetails = '';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thank you for reporting. We will review this listing.'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Submit', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label, style: const TextStyle(fontSize: 13)),
      value: value,
      groupValue: null,
      dense: true,
    );
  }

  Future<void> _openChatWithSeller(SaleUser user) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );

      // Get or create chatroom
      final chatroom = await AdsyConnectService.getOrCreateChatRoom(user.id.toString());
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Open chat bottom sheet
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: AdsyConnectChatInterface(
                chatroomId: chatroom['id'].toString(),
                userId: user.id.toString(),
                userName: user.displayName,
                userAvatar: user.profilePicture,
                profession: null,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
