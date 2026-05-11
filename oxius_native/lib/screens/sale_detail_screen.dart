import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sale_post.dart';
import '../services/sale_post_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/adsyconnect_service.dart';
import '../widgets/linkify_text.dart';
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
      final post =
          await _postService.fetchPostBySlug(widget.slug ?? widget.id!);
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
        pageSize:
            8, // Fetch more to ensure we have 4 after filtering current post
      );
      print('Fetched ${response.results.length} posts');
      if (mounted) {
        final filtered =
            response.results.where((p) => p.id != _post?.id).take(4).toList();
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
      final url = 'https://adsyclub.com/sale/${_post!.slug}';
      Share.share(
        '${_post!.title}\n${_formatPrice(_post!.price)}\n$url',
        subject: _post!.title,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Listing Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              icon: const Icon(Icons.share_rounded, size: 21),
              onPressed: () => setState(() => _showShareDialog = true),
            ),
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
                        leading: const Icon(Icons.flag_outlined,
                            color: Color(0xFF10B981)),
                        title: const Text('Report Ad'),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _showReportDialog = true);
                        },
                      ),
                      ListTile(
                        leading:
                            const Icon(Icons.share, color: Color(0xFF10B981)),
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
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF10B981)))
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
    final images = _post!.images ?? [];
    final hasImages = images.isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImages) _buildImageGallery(images),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildMainCard(),
                const SizedBox(height: 8),
                _buildSimilarListings(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    final post = _post!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductInfoCard(flat: true),
          if (post.user != null) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            _buildSellerInfoCard(flat: true),
          ],
          if (post.description != null && post.description!.isNotEmpty) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            _buildDescriptionSection(flat: true),
          ],
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: _buildFinancingBanner(post.price),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          _buildSafetyTips(flat: true),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<SaleImage> images) {
    return Container(
      margin: const EdgeInsets.fromLTRB(2, 8, 2, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 330,
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
                        color: const Color(0xFFF3F4F6),
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF10B981)),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: Icon(Icons.image_not_supported_rounded,
                            size: 72, color: Colors.grey.shade400),
                      ),
                    );
                  },
                ),
                if (images.length > 1) ...[
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left, size: 32),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.42),
                          fixedSize: const Size(42, 42),
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
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right, size: 32),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.42),
                          fixedSize: const Size(42, 42),
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
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${images.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (images.length > 1)
            Container(
              height: 86,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
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
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: CachedNetworkImage(
                          imageUrl: images[index].image,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFF3F4F6),
                            child: Icon(Icons.image_rounded,
                                color: Colors.grey.shade400),
                          ),
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

  Widget _buildProductInfoCard({bool flat = false}) {
    final post = _post!;
    final deliveryLocation =
        post.division != null && post.district != null && post.area != null
            ? '${post.division}, ${post.district}, ${post.area}'
            : 'All Over Bangladesh';

    return _buildCard(
      flat: flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _capitalizeTitle(post.title),
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              height: 1.28,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  post.price > 0 ? _formatPrice(post.price) : 'Negotiable',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF059669),
                    height: 1,
                  ),
                ),
              ),
              if (post.negotiable)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text(
                    'Negotiable',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.tag_rounded, size: 13, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 3),
              Text('Ad #${post.id}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('·', style: TextStyle(color: Color(0xFFD1D5DB))),
              ),
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 3),
              Text(
                _formatDate(post.createdAt).isNotEmpty
                    ? _formatDate(post.createdAt)
                    : '',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('·', style: TextStyle(color: Color(0xFFD1D5DB))),
              ),
              const Icon(Icons.remove_red_eye_outlined,
                  size: 13, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 3),
              Text('${post.viewsCount} views',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _buildSpecTile(
                        Icons.shield_rounded,
                        'Condition',
                        _capitalizeCondition(post.condition),
                        const Color(0xFFF59E0B)),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _buildSpecTile(Icons.category_rounded, 'Category',
                        post.categoryName ?? 'N/A', const Color(0xFF10B981)),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _buildSpecTile(Icons.layers_rounded, 'Sub-category',
                        post.subcategoryName ?? 'N/A', const Color(0xFF3B82F6)),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _buildSpecTile(Icons.local_shipping_rounded,
                        'Delivery', deliveryLocation, const Color(0xFFEF4444)),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSecondaryAction(
                  icon: Icons.share_rounded,
                  label: 'Share Listing',
                  onTap: () => setState(() => _showShareDialog = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSecondaryAction(
                  icon: Icons.flag_outlined,
                  label: 'Report Ad',
                  onTap: () => setState(() => _showReportDialog = true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      {required Widget child,
      EdgeInsetsGeometry padding = const EdgeInsets.all(18),
      bool flat = false}) {
    if (flat) return Padding(padding: padding, child: child);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563))),
        ],
      ),
    );
  }

  Widget _buildSpecTile(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryAction(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF4B5563)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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

  String _capitalizeCondition(String condition) {
    return condition.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _stripHtmlTags(String htmlText) {
    // Remove all HTML tags
    String text = htmlText.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode HTML entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
    // Remove extra whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  Widget _buildFinancingBanner(double price) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    size: 24, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need financial support to this item?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.25),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Talk with support for financing or purchase guidance.',
                      style: TextStyle(
                          color: Color(0xFFD1FAE5), fontSize: 14, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/contact-us'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Contact Support',
                  style: TextStyle(
                      color: Color(0xFF047857),
                      fontSize: 15,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection({bool flat = false}) {
    final post = _post!;
    if (post.description == null || post.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildCard(
      flat: flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              Icons.subject_rounded, 'Description', const Color(0xFF10B981)),
          const SizedBox(height: 14),
          LinkifyText(
            _stripHtmlTags(post.description!),
            style: const TextStyle(
                fontSize: 15, color: Color(0xFF374151), height: 1.6),
          ),
          if (post.detailedAddress != null &&
              post.detailedAddress!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: const Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: Color(0xFFEF4444), size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Item Address',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.detailedAddress!,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                            height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSafetyTips({bool flat = false}) {
    return _buildCard(
      flat: flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.verified_user_rounded, 'Buyer Safety',
              const Color(0xFF10B981)),
          const SizedBox(height: 14),
          _buildSafetyTip('Meet in a safe, public place'),
          _buildSafetyTip('Inspect the item before purchasing'),
          _buildSafetyTip('Do not pay or transfer money in advance'),
          _buildSafetyTip('Be careful with unrealistic prices or offers'),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.check_circle_rounded,
                size: 15, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfoCard({bool flat = false}) {
    final post = _post!;
    if (post.user == null) return const SizedBox.shrink();
    final user = post.user!;

    return _buildCard(
      flat: flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.storefront_rounded, 'Seller Information',
              const Color(0xFF2563EB)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 62,
                width: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                ),
                child: ClipOval(
                  child: user.profilePicture != null
                      ? CachedNetworkImage(
                          imageUrl: user.profilePicture!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey.shade200),
                          errorWidget: (context, url, error) =>
                              _buildAvatarFallback(user.displayName),
                        )
                      : _buildAvatarFallback(user.displayName),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: InkWell(
                            onTap: () => Navigator.pushNamed(
                                context, '/seller-profile',
                                arguments: {'userId': user.id}),
                            child: Text(
                              user.displayName,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (user.kyc == true) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              size: 18, color: Color(0xFF2563EB)),
                        ],
                        if (user.isPro == true) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF4F46E5),
                                Color(0xFF2563EB)
                              ]),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text('PRO',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Member since ${_formatDate(user.dateJoined)}',
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (user.salePostCount != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${user.salePostCount}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                            height: 1),
                      ),
                      const SizedBox(height: 3),
                      const Text('Listings',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          if (user.phone != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_rounded,
                      size: 20, color: Color(0xFF10B981)),
                  const SizedBox(width: 10),
                  const Text('Phone',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280))),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      _showPhone ? user.phone! : _maskPhoneNumber(user.phone!),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() => _showPhone = !_showPhone),
                    child: Icon(
                        _showPhone
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 21,
                        color: const Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/seller-profile',
                arguments: {'userId': user.id}),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('View Seller Profile',
                      style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF047857),
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 18, color: Color(0xFF047857)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: const Color(0xFF10B981).withOpacity(0.1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              fontSize: 24,
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w800),
        ),
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildSimilarListings() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildSectionHeader(Icons.grid_view_rounded,
                      'Similar Listings', const Color(0xFF8B5CF6))),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/sale'),
                child: const Text(
                  'View All',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _isLoadingSimilar
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  ),
                )
              : _similarPosts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Text(
                          'No similar listings found',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount:
                          _similarPosts.length > 4 ? 4 : _similarPosts.length,
                      itemBuilder: (context, index) =>
                          _buildSimilarListingCard(_similarPosts[index]),
                    ),
        ],
      ),
    );
  }

  Widget _buildSimilarListingCard(SalePost post) {
    final hasImage = post.images != null && post.images!.isNotEmpty;
    final location = post.division != null && post.district != null
        ? '${post.division}, ${post.district}'
        : 'Bangladesh';

    return InkWell(
      onTap: () {
        Navigator.pushReplacementNamed(
          context,
          '/sale/detail',
          arguments: {'slug': post.slug},
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.05,
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: post.images![0].image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF10B981))),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: Icon(Icons.image_not_supported_rounded,
                            size: 34, color: Colors.grey.shade400),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF3F4F6),
                      child: Icon(Icons.image_rounded,
                          size: 36, color: Colors.grey.shade400),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalizeTitle(post.title),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          height: 1.25),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 14, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                height: 1.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      post.price > 0 ? _formatPrice(post.price) : 'Negotiable',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF059669)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      height: 280,
      margin: const EdgeInsets.fromLTRB(2, 8, 2, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_rounded, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text(
              'No image available',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final post = _post!;
    final user = post.user;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            if (user?.phone != null)
              Expanded(
                child: _buildBottomAction(
                  label: 'Call Seller',
                  icon: const Icon(Icons.phone_rounded,
                      size: 21, color: Color(0xFF047857)),
                  isPrimary: false,
                  onTap: () async {
                    final post = _post;
                    if (post?.user?.phone != null) {
                      final phoneUrl = 'tel:${post!.user!.phone}';
                      try {
                        await launchUrl(Uri.parse(phoneUrl),
                            mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Could not open phone dialer')),
                          );
                        }
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Phone number not available')),
                        );
                      }
                    }
                  },
                ),
              ),
            if (user?.phone != null) const SizedBox(width: 10),
            Expanded(
              child: _buildBottomAction(
                label: 'Chat Now',
                icon: Image.asset(
                  'assets/images/chat_icon.png',
                  width: 21,
                  height: 21,
                  color: Colors.white,
                ),
                isPrimary: true,
                onTap: () async {
                  if (!AuthService.isAuthenticated) {
                    _showLoginRequiredDialog();
                    return;
                  }

                  final user = _post?.user;
                  if (user != null) {
                    await _openChatWithSeller(user);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color:
                  isPrimary ? const Color(0xFF10B981) : const Color(0xFFA7F3D0),
              width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isPrimary ? Colors.white : const Color(0xFF047857),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareDialog() {
    final post = _post!;
    final shareUrl = 'https://adsyclub.com/sale/${post.slug}';
    final shareText = '${post.title}\n${_formatPrice(post.price)}\n$shareUrl';

    Future<void> launch(String url) async {
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the app')),
          );
        }
      }
    }

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
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Share this listing',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            setState(() => _showShareDialog = false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Native Share
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.ios_share_rounded,
                          color: Color(0xFF10B981)),
                    ),
                    title: const Text('Share via...',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    onTap: () {
                      setState(() => _showShareDialog = false);
                      _sharePost();
                    },
                  ),

                  const Divider(height: 1),

                  // Copy Link
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.link, color: Color(0xFF6B7280)),
                    ),
                    title: const Text('Copy Link',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
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

                  // WhatsApp
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chat_rounded,
                          color: Color(0xFF25D366)),
                    ),
                    title: const Text('Share on WhatsApp',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    onTap: () {
                      setState(() => _showShareDialog = false);
                      launch(
                          'https://wa.me/?text=${Uri.encodeComponent(shareText)}');
                    },
                  ),

                  const Divider(height: 1),

                  // X (formerly Twitter)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '𝕏',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black),
                      ),
                    ),
                    title: const Text('Share on X',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    onTap: () {
                      setState(() => _showShareDialog = false);
                      launch(
                          'https://x.com/intent/tweet?text=${Uri.encodeComponent(post.title)}&url=${Uri.encodeComponent(shareUrl)}');
                    },
                  ),

                  const Divider(height: 1),

                  // Facebook
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                    ),
                    title: const Text('Share on Facebook',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    onTap: () {
                      setState(() => _showShareDialog = false);
                      launch(
                          'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareUrl)}');
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
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
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
                            foregroundColor: const Color(0xFF6B7280),
                            side: const BorderSide(
                                color: Color(0xFFD1D5DB), width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _reportReason.isEmpty
                              ? null
                              : () async {
                                  if (_post?.slug == null) return;

                                  // Show loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Submitting report...'),
                                        ],
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );

                                  // Submit report to backend
                                  final success = await _postService.reportPost(
                                    _post!.slug,
                                    _reportReason,
                                    details: _reportReason == 'other'
                                        ? _reportDetails
                                        : null,
                                  );

                                  setState(() {
                                    _showReportDialog = false;
                                    _reportReason = '';
                                    _reportDetails = '';
                                  });

                                  // Show result
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Thank you for reporting. We will review this listing.'
                                              : 'Failed to submit report. Please try again.',
                                        ),
                                        backgroundColor: success
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFD1D5DB),
                            disabledForegroundColor: const Color(0xFF9CA3AF),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Submit',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
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
      groupValue: _reportReason,
      onChanged: (String? newValue) {
        setState(() {
          _reportReason = newValue ?? '';
        });
      },
      dense: true,
      activeColor: const Color(0xFF10B981),
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
      final chatroom =
          await AdsyConnectService.getOrCreateChatRoom(user.id.toString());

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

      // Check if it's an authentication error
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        if (mounted) {
          _showLoginRequiredDialog();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open chat. Please try again.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Login Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need to be logged in to chat with the seller.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Please login or create an account to continue.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Login',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
