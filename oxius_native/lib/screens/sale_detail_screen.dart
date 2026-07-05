import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sale_post.dart';
import '../services/sale_post_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/adsyconnect_service.dart';
import '../services/translation_service.dart';
import '../widgets/linkify_text.dart';
import '../widgets/common/adsy_report_sheet.dart';
import '../widgets/common/adsy_share_sheet.dart';
import 'adsy_connect_chat_interface.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

/// Sale Post Detail Screen - View full post details with image gallery and all features
class SaleDetailScreen extends StatefulWidget {
  final String? slug;
  final String? id;

  const SaleDetailScreen({
    super.key,
    this.slug,
    this.id,
  });

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) =>
      _i18n.translate(key, fallback: fallback);

  late SalePostService _postService;
  SalePost? _post;
  List<SalePost> _similarPosts = [];
  bool _isLoading = true;
  bool _isLoadingSimilar = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

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
      debugPrint('Error fetching post details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchSimilarPosts(String categoryId) async {
    setState(() => _isLoadingSimilar = true);
    try {
      debugPrint('Fetching similar posts for category: $categoryId');
      final response = await _postService.fetchPosts(
        categoryId: categoryId,
        pageSize:
            8, // Fetch more to ensure we have 4 after filtering current post
      );
      debugPrint('Fetched ${response.results.length} posts');
      if (mounted) {
        final filtered =
            response.results.where((p) => p.id != _post?.id).take(4).toList();
        debugPrint('After filtering current post: ${filtered.length} similar posts');
        setState(() {
          _similarPosts = filtered;
          _isLoadingSimilar = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching similar posts: $e');
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

  AdsyShareData? _shareData() {
    final post = _post;
    if (post == null) return null;

    final imageUrl = post.images != null && post.images!.isNotEmpty
        ? post.images!.first.image
        : null;

    return AdsyShareData(
      title: post.title,
      description: [
        _formatPrice(post.price),
        if ((post.description ?? '').trim().isNotEmpty)
          post.description!.trim(),
      ].join(' - '),
      url: 'https://adsyclub.com/sale/${post.slug}',
      imageUrl: imageUrl,
      subject: post.title,
      eyebrow: _t('sale_listing_eyebrow', 'পুরাতন কেনাবেচা'),
    );
  }

  Future<void> _openShareSheet() async {
    final data = _shareData();
    if (data == null) return;
    await AdsyShareSheet.show(context, data: data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _post?.title ?? _t('sale_listing_details', 'বিজ্ঞাপনের ডিটেইলস'),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 21),
            onPressed: _openShareSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: AdsyLoadingIndicator(color: Color(0xFF10B981)))
              : _post == null
                  ? _buildErrorState()
                  : _buildContent(),
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
            _t('sale_post_not_found', 'পোস্টটা পাওয়া যায়নি'),
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('sale_go_back', 'ফিরে যান')),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasImages) _buildImageGallery(images),
          if (hasImages) const SizedBox(height: 8),
          _buildProductInfoSection(),
          Container(height: 1, color: Colors.grey.shade200),
          _buildDeliveryCoverageSection(),
          Container(height: 1, color: Colors.grey.shade200),
          if (_post!.description != null && _post!.description!.isNotEmpty) ...[
            _buildDescriptionSection(),
            Container(height: 1, color: Colors.grey.shade200),
          ],
          if (_post!.user != null) ...[
            _buildSellerInfoSection(),
            Container(height: 1, color: Colors.grey.shade200),
          ],
          _buildSafetyTipsSection(),
          Container(height: 1, color: Colors.grey.shade200),
          _buildSimilarListings(),
          const SizedBox(height: 80),
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
            color: Colors.black.withValues(alpha: 0.08),
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
                          child: AdsyLoadingIndicator(color: Color(0xFF10B981)),
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
                          backgroundColor: Colors.black.withValues(alpha: 0.42),
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
                          backgroundColor: Colors.black.withValues(alpha: 0.42),
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
                      color: Colors.black.withValues(alpha: 0.6),
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

  Widget _buildProductInfoSection() {
    final post = _post!;
    // Prefer the backend-computed location string so what shows is driven by
    // the server; fall back to the local parts / "All Over Bangladesh".
    final deliveryLocation = (post.location != null &&
            post.location!.trim().isNotEmpty)
        ? post.location!.trim()
        : post.division != null && post.district != null && post.area != null
            ? '${post.division}, ${post.district}, ${post.area}'
            : post.division != null && post.district != null
                ? '${post.division}, ${post.district}'
                : _t('sale_all_over_bangladesh', 'সারা বাংলাদেশ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price + Negotiable badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                post.price > 0
                    ? _formatPrice(post.price)
                    : _t('sale_negotiable', 'দামাদামি করা যাবে'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              if (post.negotiable && post.price > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    _t('sale_negotiable', 'দামাদামি করা যাবে'),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Title
          Text(
            _capitalizeTitle(post.title),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          // Meta row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (deliveryLocation.trim().isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      deliveryLocation,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_rounded,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${post.viewsCount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(post.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _openReportSheet,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_outlined,
                        size: 13, color: Color(0xFFDC2626)),
                    const SizedBox(width: 4),
                    Text(
                      _t('sale_report', 'রিপোর্ট করুন'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Spec tiles
          Wrap(
            spacing: 0,
            runSpacing: 0,
            children: [
              _buildSpecTile(
                  Icons.shield_rounded,
                  _t('sale_condition', 'কন্ডিশন'),
                  _conditionLabel(post.condition),
                  const Color(0xFFF59E0B)),
              _buildSpecTile(
                  Icons.category_rounded,
                  _t('sale_category', 'ক্যাটাগরি'),
                  post.categoryName ?? _t('sale_not_available', 'নেই'),
                  const Color(0xFF10B981)),
              if (post.subcategoryName != null)
                _buildSpecTile(
                    Icons.layers_rounded,
                    _t('sale_subcategory', 'সাব-ক্যাটাগরি'),
                    post.subcategoryName!,
                    const Color(0xFF3B82F6)),
              _buildSpecTile(
                  Icons.local_shipping_rounded,
                  _t('sale_delivery', 'ডেলিভারি'),
                  deliveryLocation,
                  const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecTile(
      IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.75)),
              ),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    height: 1.2),
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

  String _conditionLabel(String condition) {
    switch (condition) {
      case 'brand-new':
      case 'new':
        return _t('sale_condition_brand_new', 'একদম নতুন');
      case 'like-new':
      case 'like_new':
        return _t('sale_condition_like_new', 'নতুনের মতো');
      case 'good':
        return _t('sale_condition_good', 'ভালো');
      case 'fair':
        return _t('sale_condition_fair', 'মোটামুটি');
      case 'for-parts':
        return _t('sale_condition_for_parts', 'পার্টসের জন্য');
      case 'poor':
        return _t('sale_condition_poor', 'পুরনো');
      default:
        return condition.replaceAll('-', ' ').replaceAll('_', ' ');
    }
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

  /// Where the seller delivers. Empty list = all over Bangladesh.
  Widget _buildDeliveryCoverageSection() {
    final locations = _post!.deliveryLocations;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 17, color: Color(0xFF059669)),
              const SizedBox(width: 6),
              Text(
                _t('sale_delivers_to', 'যেসব জায়গায় ডেলিভারি হয়'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (locations.isEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public_rounded,
                      size: 14, color: Color(0xFF059669)),
                  const SizedBox(width: 5),
                  Text(
                    _t('sale_delivers_all_bd', 'সারা বাংলাদেশে'),
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF065F46)),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: locations.map((loc) {
                final division = (loc['division'] ?? '').toString();
                final district = (loc['district'] ?? '').toString();
                final label = district.isNotEmpty
                    ? '$district, $division'
                    : '$division (${_t('sale_dl_whole_division', 'পুরো বিভাগ')})';
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: Color(0xFF059669)),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF065F46)),
                      ),
                    ],
                  ),
                );
              }).toList(),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('sale_description', 'ডিটেইলস'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          LinkifyText(
            _stripHtmlTags(post.description!),
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF374151), height: 1.6),
          ),
          if (post.detailedAddress != null &&
              post.detailedAddress!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_rounded,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    post.detailedAddress!,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF4B5563), height: 1.45),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSafetyTipsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      color: const Color(0xFFFFFBEB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded,
                  color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 8),
              Text(
                _t('sale_safety_tips_title', 'নিরাপত্তার টিপস'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSafetyTip(_t('sale_safety_tip_meet',
              'পরিচিত আর লোকজন আছে এমন জায়গায় দেখা করুন')),
          _buildSafetyTip(_t('sale_safety_tip_verify',
              'জিনিসটা ভালো করে দেখে ও যাচাই করে কিনুন')),
          _buildSafetyTip(_t('sale_safety_tip_no_advance',
              'জিনিস হাতে পাওয়ার আগে টাকা দেবেন না')),
          _buildSafetyTip(_t('sale_safety_tip_bkash',
              'আগেই বিকাশ/নগদে টাকা চাইলে সাবধান হোন')),
          _buildSafetyTip(_t('sale_safety_tip_links',
              'অচেনা লিংকে ক্লিক করবেন না, নিজের তথ্যও শেয়ার করবেন না')),
          _buildSafetyTip(_t('sale_safety_tip_police',
              'প্রতারণার শিকার হলে সাথে সাথে পুলিশকে জানান')),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_in_talk_rounded,
                    size: 15, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _t('sale_emergency_call',
                        'জরুরি দরকারে ৯৯৯ নম্বরে কল করুন'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
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
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfoSection() {
    final post = _post!;
    if (post.user == null) return const SizedBox.shrink();
    final user = post.user!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('sale_seller_info', 'বিক্রেতার তথ্য'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 46,
                width: 46,
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                          context, '/seller-profile', arguments: {
                        'userId': user.id,
                        'userName': user.displayName
                      }),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.kyc == true) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                size: 15, color: Color(0xFF2563EB)),
                          ],
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 11, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                    if (user.phone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            _showPhone
                                ? user.phone!
                                : _maskPhoneNumber(user.phone!),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827)),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _showPhone = !_showPhone),
                            child: Icon(
                                _showPhone
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 14,
                                color: const Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (user.salePostCount != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${user.salePostCount}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            height: 1),
                      ),
                      const SizedBox(height: 2),
                      Text(_t('sale_listings', 'টি বিজ্ঞাপন'),
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: const Color(0xFF10B981).withValues(alpha: 0.1),
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
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 2)}';
  }

  Widget _buildSimilarListings() {
    if (_similarPosts.isEmpty && !_isLoadingSimilar) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _t('sale_similar_listings', 'এরকম আরও বিজ্ঞাপন'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/sale'),
                child: Text(
                  _t('sale_view_all', 'সব দেখুন'),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _isLoadingSimilar
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: AdsyLoadingIndicator(
                        strokeWidth: 2, color: Color(0xFF10B981)),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
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
        : _t('sale_bangladesh', 'বাংলাদেশ');

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
              aspectRatio: 1.3,
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: post.images![0].image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Center(
                            child: AdsyLoadingIndicator(
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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
                      post.price > 0
                    ? _formatPrice(post.price)
                    : _t('sale_negotiable', 'দামাদামি করা যাবে'),
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

  Widget _buildBottomBar() {
    final post = _post!;
    final user = post.user;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          children: [
            if (user?.phone != null) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final p = _post;
                    if (p?.user?.phone != null) {
                      try {
                        await launchUrl(Uri.parse('tel:${p!.user!.phone}'),
                            mode: LaunchMode.externalApplication);
                      } catch (_) {
                        if (mounted) {
                          AdsyToast.error(
                              context,
                              _t('sale_dialer_failed',
                                  'ফোনের ডায়ালার খোলা গেল না'));
                        }
                      }
                    } else {
                      if (mounted) {
                        AdsyToast.info(
                            context,
                            _t('sale_phone_not_available',
                                'ফোন নাম্বার পাওয়া যায়নি'));
                      }
                    }
                  },
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  label: Text(_t('sale_call_seller', 'কল করুন'),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  if (!AuthService.isAuthenticated) {
                    _showLoginRequiredDialog();
                    return;
                  }
                  final u = _post?.user;
                  if (u != null) await _openChatWithSeller(u);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0284C7),
                  side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                  backgroundColor: const Color(0xFFF0F9FF),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/chat_icon.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Text(_t('sale_chat_now', 'চ্যাট করুন'),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openReportSheet() {
    final post = _post;
    final slug = post?.slug ?? widget.slug ?? widget.id;
    if (slug == null || slug.isEmpty) return;

    AdsyReportSheet.show(
      context,
      title: _t('sale_report_listing', 'বিজ্ঞাপনটা রিপোর্ট করুন'),
      prompt: _t('sale_report_prompt', 'কেন রিপোর্ট করছেন সেটা বেছে নিন।'),
      options: AdsyReportSheet.saleOptions,
      successMessage: _t('sale_report_success',
          'রিপোর্ট করার জন্য ধন্যবাদ। আমরা বিজ্ঞাপনটা দেখে ব্যবস্থা নেব।'),
      onSubmit: (option, details) {
        return _postService.reportPost(
          slug,
          option.value,
          details: details,
        );
      },
    );
  }

  Future<void> _openChatWithSeller(SaleUser user) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: AdsyLoadingIndicator(color: Color(0xFF10B981)),
        ),
      );

      // Get or create chatroom
      final chatroom =
          await AdsyConnectService.getOrCreateChatRoom(user.id.toString());

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Open chat (with stack-deduplication: returns to existing chat if open)
      if (mounted) {
        AdsyConnectChatInterface.open(
          context,
          chatroomId: chatroom['id'].toString(),
          userId: user.id.toString(),
          userName: user.displayName,
          userAvatar: user.profilePicture,
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
        AdsyToast.error(context,
            _t('sale_chat_open_failed', 'চ্যাট খোলা গেল না, আবার চেষ্টা করুন।'));
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
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _t('sale_login_required', 'লগইন করতে হবে'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('sale_login_required_msg',
                  'বিক্রেতার সাথে চ্যাট করতে হলে আগে লগইন করতে হবে।'),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _t('sale_login_or_signup',
                  'লগইন করুন বা নতুন একাউন্ট খুলে নিন।'),
              style: const TextStyle(
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
            child: Text(
              _t('sale_cancel', 'ক্যান্সেল'),
              style: const TextStyle(
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
            child: Text(
              _t('sale_login', 'লগইন'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
