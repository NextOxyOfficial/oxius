import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/workspace_service.dart';
import '../../utils/html_content_utils.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/adsyconnect_service.dart';
import '../../services/translation_service.dart';
import '../adsy_connect_chat_interface.dart';
import '../wallet/wallet_screen.dart';
import '../../widgets/common/adsy_share_sheet.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class GigDetailScreen extends StatefulWidget {
  final String gigId;

  const GigDetailScreen({super.key, required this.gigId});

  @override
  State<GigDetailScreen> createState() => _GigDetailScreenState();
}

class _GigDetailScreenState extends State<GigDetailScreen> {
  final WorkspaceService _workspaceService = WorkspaceService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _requirementsController = TextEditingController();

  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) =>
      _i18n.translate(key, fallback: fallback);

  Map<String, dynamic>? _gig;
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _relatedGigs = [];
  bool _isLoading = true;
  bool _isLoadingMoreReviews = false;
  int _currentImageIndex = 0;
  final PageController _imageController = PageController();

  // Order flow state
  bool _showOrderFlow = false;
  int _orderStep = 1; // 1: Review, 2: Payment, 3: Complete
  bool _isPlacingOrder = false;
  bool _isRefreshingBalance = false;
  Map<String, dynamic>? _orderResult;
  double _userBalance = 0;

  // Reviews pagination
  int _reviewsPage = 1;
  int _totalReviewsCount = 0;
  bool _hasMoreReviews = false;
  final GlobalKey _reviewsSectionKey = GlobalKey();

  // Fee settings from backend
  double _buyerFeePercent = 2.5; // Default 2.5%
  bool _feesEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadGigDetails();
    _loadUserBalance();
    _loadFeeSettings();
  }

  @override
  void dispose() {
    _imageController.dispose();
    _scrollController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserBalance() async {
    try {
      final user = AuthService.currentUser;
      if (user != null && mounted) {
        setState(() {
          _userBalance = user.balance;
        });
      }
    } catch (e) {
      // Ignore balance loading errors
    }
  }

  Future<void> _refreshBalance() async {
    if (_isRefreshingBalance) return;
    setState(() => _isRefreshingBalance = true);

    try {
      await AuthService.initialize(); // Refresh user data
      final user = AuthService.currentUser;
      if (user != null && mounted) {
        setState(() {
          _userBalance = user.balance;
        });
        _showSnackBar(
            '${_t('workspace_balance_updated', 'ব্যালেন্স আপডেট হয়েছে')}: ৳${_userBalance.toStringAsFixed(2)}',
            Colors.green);
      }
    } catch (e) {
      _showSnackBar(
          _t('workspace_balance_refresh_failed',
              'ব্যালেন্স রিফ্রেশ করা যায়নি'),
          Colors.red);
    } finally {
      if (mounted) setState(() => _isRefreshingBalance = false);
    }
  }

  Future<void> _loadFeeSettings() async {
    try {
      final fees = await _workspaceService.getFeeSettings();
      if (mounted && fees.isNotEmpty) {
        setState(() {
          _buyerFeePercent =
              double.tryParse(fees['buyer_fee_percent']?.toString() ?? '') ??
                  2.5;
          double.tryParse(fees['seller_fee_percent']?.toString() ?? '') ?? 2.5;
          _feesEnabled = fees['fees_enabled'] ?? true;
        });
      }
    } catch (e) {
      // Use default fees
    }
  }

  String _formatFeePercent(double percent) {
    // Show whole number if no decimals, otherwise show one decimal
    if (percent == percent.roundToDouble()) {
      return percent.toStringAsFixed(0);
    }
    return percent.toStringAsFixed(1);
  }

  void _scrollToReviews() {
    final context = _reviewsSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadGigDetails() async {
    setState(() => _isLoading = true);

    try {
      final gig = await _workspaceService.fetchGigDetails(widget.gigId);
      final reviewsResult =
          await _workspaceService.fetchGigReviews(widget.gigId);

      if (mounted) {
        setState(() {
          _gig = gig;
          _reviews =
              List<Map<String, dynamic>>.from(reviewsResult['results'] ?? []);
          _totalReviewsCount = reviewsResult['count'] ?? _reviews.length;
          _hasMoreReviews = _reviews.length < _totalReviewsCount;
          _isLoading = false;
        });

        // Load related gigs
        _loadRelatedGigs();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(
            '${_t('workspace_gig_load_failed', 'গিগ লোড করা যায়নি')}: $e',
            Colors.red);
      }
    }
  }

  Future<void> _loadRelatedGigs() async {
    if (_gig == null) return;

    try {
      final result = await _workspaceService.fetchGigs(
        category: _gig!['category'],
        pageSize: 6,
      );

      if (mounted) {
        final gigs = List<Map<String, dynamic>>.from(result['results'] ?? []);
        setState(() {
          _relatedGigs = gigs
              .where((g) => g['id'].toString() != widget.gigId)
              .take(4)
              .toList();
        });
      }
    } catch (e) {
      // Ignore related gigs loading errors
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingMoreReviews || !_hasMoreReviews) return;

    setState(() => _isLoadingMoreReviews = true);

    try {
      final result = await _workspaceService.fetchGigReviews(widget.gigId,
          page: _reviewsPage + 1);

      if (mounted) {
        final newReviews =
            List<Map<String, dynamic>>.from(result['results'] ?? []);
        setState(() {
          _reviews.addAll(newReviews);
          _reviewsPage++;
          _hasMoreReviews = _reviews.length < _totalReviewsCount;
          _isLoadingMoreReviews = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMoreReviews = false);
    }
  }

  String _getImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiService.baseUrl.replaceAll('/api', '')}$url';
  }

  List<String> get _gigImages {
    if (_gig == null) return [];
    final images = <String>[];

    if (_gig!['image_url'] != null) {
      images.add(_getImageUrl(_gig!['image_url']));
    } else if (_gig!['image'] != null) {
      images.add(_getImageUrl(_gig!['image']));
    }

    if (_gig!['gallery'] != null && _gig!['gallery'] is List) {
      for (var img in _gig!['gallery']) {
        images.add(_getImageUrl(img.toString()));
      }
    }

    return images.isEmpty ? [''] : images;
  }

  double get _gigPrice =>
      double.tryParse(_gig?['price']?.toString() ?? '0') ?? 0;

  // Fee calculations (dynamic from backend)
  double get _serviceFee =>
      _feesEnabled ? _gigPrice * (_buyerFeePercent / 100) : 0;
  double get _totalToPay => _gigPrice + _serviceFee;
  bool get _hasSufficientBalance => _userBalance >= _totalToPay;
  double get _balanceShortfall => _totalToPay - _userBalance;
  double get _balanceAfterPayment => _userBalance - _totalToPay;

  bool get _isOwnGig {
    final user = AuthService.currentUser;
    if (user == null || _gig == null) return false;
    return _gig!['user']?['id']?.toString() == user.id;
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    if (color == Colors.green) {
      AdsyToast.success(context, message);
    } else if (color == Colors.red) {
      AdsyToast.error(context, message);
    } else if (color == Colors.orange) {
      AdsyToast.warning(context, message);
    } else {
      AdsyToast.info(context, message);
    }
  }

  void _startOrder() {
    setState(() {
      _showOrderFlow = true;
      _orderStep = 1;
    });
  }

  void _cancelOrder() {
    setState(() {
      _showOrderFlow = false;
      _orderStep = 1;
      _requirementsController.clear();
      _orderResult = null;
    });
  }

  Future<void> _submitOrder() async {
    if (!_hasSufficientBalance || _isPlacingOrder) return;

    setState(() => _isPlacingOrder = true);

    try {
      final result = await _workspaceService.createOrder(widget.gigId, {
        'requirements': _requirementsController.text,
      });

      if (mounted) {
        setState(() {
          _orderResult = result;
          _orderStep = 3;
          _isPlacingOrder = false;
        });
        _showSnackBar(
            _t('workspace_order_placed', 'অর্ডার হয়ে গেছে!'), Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        _showSnackBar(
            '${_t('workspace_order_place_failed', 'অর্ডার করা যায়নি')}: $e',
            Colors.red);
      }
    }
  }

  Future<void> _contactSeller() async {
    if (_gig == null) return;

    // Check authentication first
    if (!AuthService.isAuthenticated) {
      _showSnackBar(
          _t('workspace_login_to_contact',
              'সেলারের সাথে যোগাযোগ করতে লগইন করুন'),
          Colors.orange);
      return;
    }

    final sellerId = _gig!['user']?['id']?.toString();
    if (sellerId == null) {
      _showSnackBar(
          _t('workspace_seller_info_unavailable', 'সেলারের তথ্য পাওয়া যায়নি'),
          Colors.red);
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: AdsyLoadingIndicator(color: Color(0xFF8B5CF6)),
      ),
    );

    try {
      // Get or create chat room with the seller
      final chatroom = await AdsyConnectService.getOrCreateChatRoom(sellerId);

      // Close loading indicator
      if (mounted) Navigator.pop(context);

      // Open chat interface (stack-deduplicated)
      if (mounted) {
        AdsyConnectChatInterface.open(
          context,
          chatroomId: chatroom['id'].toString(),
          userId: sellerId,
          userName: _gig!['user']?['name'] ?? 'Seller',
          userAvatar: _gig!['user']?['avatar'] != null
              ? _getImageUrl(_gig!['user']['avatar'])
              : null,
          profession: 'Gig Seller',
          isOnline: false,
          isVerified: _gig!['user']?['kyc'] == true,
          isPro: _gig!['user']?['is_pro'] == true,
        );
      }
    } catch (e) {
      // Close loading indicator
      if (mounted) Navigator.pop(context);
      _showSnackBar(
          '${_t('workspace_chat_open_failed', 'চ্যাট খোলা যায়নি')}: $e',
          Colors.red);
    }
  }

  Future<void> _handleShare() async {
    if (_gig == null) return;

    await AdsyShareSheet.show(
      context,
      data: AdsyShareData(
        title: _gig!['title']?.toString() ?? 'Workspace Gig',
        description:
            'Starting at BDT ${_gigPrice.toStringAsFixed(0)} on AdsyClub Workspace.',
        url:
            'https://adsyclub.com/business-network/workspace-details?id=${widget.gigId}',
        imageUrl: _gigImages.isNotEmpty ? _gigImages.first : null,
        subject: _gig!['title']?.toString() ?? 'Workspace Gig',
        eyebrow: 'Workspace Gig',
      ),
    );
  }

  String _getCategoryLabel(String? category) {
    final labels = {
      'design': _t('workspace_cat_design', 'ডিজাইন ও ক্রিয়েটিভ'),
      'development': _t('workspace_cat_development', 'প্রোগ্রামিং ও টেক'),
      'writing': _t('workspace_cat_writing', 'লেখা ও অনুবাদ'),
      'marketing': _t('workspace_cat_marketing', 'ডিজিটাল মার্কেটিং'),
      'business': _t('workspace_cat_business', 'বিজনেস ও কনসালটিং'),
    };
    return labels[category] ?? _t('workspace_cat_other', 'অন্যান্য');
  }

  List<String> _getGigFeatures() {
    if (_gig?['features'] != null &&
        _gig!['features'] is List &&
        (_gig!['features'] as List).isNotEmpty) {
      return List<String>.from(_gig!['features']);
    }

    const features = {
      'design': [
        'Custom design concepts',
        'Unlimited revisions',
        'High-resolution files',
        'Commercial license',
        '24/7 support'
      ],
      'development': [
        'Responsive design',
        'Clean code',
        'Browser compatibility',
        'Performance optimization',
        'Post-launch support'
      ],
      'writing': [
        'Original content',
        'SEO optimization',
        'Multiple revisions',
        'Plagiarism-free',
        'Fast turnaround'
      ],
      'marketing': [
        'Strategy development',
        'Content calendar',
        'Performance analytics',
        'Competitor analysis',
        'Monthly reports'
      ],
      'business': [
        'Market analysis',
        'Strategic planning',
        'ROI projections',
        'Implementation roadmap',
        'Follow-up consultation'
      ],
    };
    return features[_gig?['category']] ??
        ['Professional delivery', 'Quality guarantee', 'Timely completion'];
  }

  List<String> _getGigSkills() {
    const skills = {
      'design': [
        'Adobe Creative Suite',
        'Figma',
        'Brand Identity',
        'Logo Design',
        'UI/UX'
      ],
      'development': [
        'React',
        'Node.js',
        'JavaScript',
        'HTML/CSS',
        'API Integration'
      ],
      'writing': [
        'Content Strategy',
        'SEO Writing',
        'Copywriting',
        'Technical Writing',
        'Proofreading'
      ],
      'marketing': [
        'Social Media',
        'Google Ads',
        'Content Marketing',
        'Analytics',
        'Email Marketing'
      ],
      'business': [
        'Strategic Planning',
        'Market Research',
        'Financial Analysis',
        'Project Management',
        'Leadership'
      ],
    };
    return skills[_gig?['category']] ?? ['Professional Service'];
  }

  String _formatViewCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _getActiveStatus(String? updatedAt) {
    final active = _t('workspace_active', 'চালু');
    if (updatedAt == null) return active;

    try {
      final updated = DateTime.parse(updatedAt);
      final diff = DateTime.now().difference(updated);

      if (diff.inMinutes < 5) {
        return _t('workspace_active_now', 'এখন চালু');
      }
      if (diff.inMinutes < 60) {
        return '$active ${diff.inMinutes}${_t('workspace_min_ago', 'মি আগে')}';
      }
      if (diff.inHours < 24) {
        return '$active ${diff.inHours}${_t('workspace_hour_ago', 'ঘ আগে')}';
      }
      if (diff.inDays < 7) {
        return '$active ${diff.inDays}${_t('workspace_day_ago', 'দি আগে')}';
      }
      return _t('workspace_active_week', 'এই সপ্তাহে চালু');
    } catch (e) {
      return active;
    }
  }

  String _formatReviewDate(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final diff = DateTime.now().difference(date);

      if (diff.inDays == 0) return _t('workspace_today', 'আজ');
      if (diff.inDays == 1) return _t('workspace_yesterday', 'গতকাল');
      if (diff.inDays < 7) {
        return '${diff.inDays} ${_t('workspace_days_ago', 'দিন আগে')}';
      }
      if (diff.inDays < 30) {
        return '${(diff.inDays / 7).floor()} ${_t('workspace_weeks_ago', 'সপ্তাহ আগে')}';
      }
      if (diff.inDays < 365) {
        return '${(diff.inDays / 30).floor()} ${_t('workspace_months_ago', 'মাস আগে')}';
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  String _truncateTitle(String title, int maxLength) {
    if (title.length <= maxLength) return title;
    return '${title.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('workspace_gig_details', 'গিগের বিবরণ'),
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _gig?['is_favorited'] == true
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: _gig?['is_favorited'] == true ? Colors.red : Colors.grey,
              size: 20,
            ),
            onPressed: () async {
              await _workspaceService.toggleFavorite(widget.gigId);
              _loadGigDetails();
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.grey, size: 20),
            onPressed: _handleShare,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AdsyLoadingIndicator())
          : _gig == null
              ? _buildErrorState()
              : _buildContent(),
      bottomNavigationBar:
          _gig != null && !_showOrderFlow ? _buildBottomBar() : null,
    );
  }

  Widget _buildContent() {
    final user = _gig!['user'] as Map<String, dynamic>?;
    final rating = (_gig!['rating'] ?? 0).toDouble();
    final reviewsCount = _gig!['reviews_count'] ?? _totalReviewsCount;
    final images = _gigImages;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Gallery with Navigation
          _buildImageGallery(images),

          // Content Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  _gig!['title'] ?? '',
                  style: const TextStyle(
                      fontSize: 19.5,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      letterSpacing: -0.3,
                      color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),

                // Seller Info Card
                _buildSellerInfo(user, rating, reviewsCount),
                const SizedBox(height: 14),

                // Description
                Text(_t('workspace_about_gig', 'এই গিগ সম্পর্কে'),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Text(
                  // Descriptions written on the web carry HTML wrappers.
                  HtmlContentUtils.toPlainText(_gig!['description'] ?? ''),
                  style: const TextStyle(
                      color: Color(0xFF334155), fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 18),

                // What You'll Get
                Text(_t('workspace_what_you_get', 'যা যা পাবেন:'),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                ..._getGigFeatures().map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle,
                              size: 17, color: Colors.green),
                          const SizedBox(width: 9),
                          Expanded(
                              child: Text(feature,
                                  style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 14.5,
                                      height: 1.45))),
                        ],
                      ),
                    )),
                const SizedBox(height: 14),

                // Skills & Expertise
                Text(_t('workspace_skills_expertise', 'দক্ষতা ও অভিজ্ঞতা:'),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _getGigSkills()
                      .map((skill) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(skill,
                                style: const TextStyle(
                                    color: Color(0xFF8B5CF6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Pricing and Package Details
          _buildPricingSection(),
          const SizedBox(height: 6),

          // Trust Indicators
          _buildTrustIndicators(),
          const SizedBox(height: 6),

          // Related Gigs
          if (_relatedGigs.isNotEmpty) _buildRelatedGigs(),

          // Reviews Section
          _buildReviewsSection(reviewsCount),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PageView.builder(
            controller: _imageController,
            onPageChanged: (index) =>
                setState(() => _currentImageIndex = index),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              );
            },
          ),
          // Navigation Arrows
          if (images.length > 1) ...[
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentImageIndex > 0) {
                      _imageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                    } else {
                      _imageController.animateToPage(images.length - 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_left, size: 20),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentImageIndex < images.length - 1) {
                      _imageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                    } else {
                      _imageController.animateToPage(0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_right, size: 20),
                  ),
                ),
              ),
            ),
          ],
          // Dots Indicator
          if (images.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  return GestureDetector(
                    onTap: () => _imageController.animateToPage(index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _currentImageIndex == index ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: _currentImageIndex == index
                            ? const Color(0xFF8B5CF6)
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo(
      Map<String, dynamic>? user, double rating, int reviewsCount) {
    return GestureDetector(
      onTap: () {
        // Navigate to seller profile
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            // Avatar with Pro ring
            Stack(
              children: [
                if (user?['is_pro'] == true)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFF97316)]),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: Colors.grey[50])),
                  ),
                CircleAvatar(
                  radius: 18,
                  backgroundImage: user?['avatar'] != null
                      ? CachedNetworkImageProvider(
                          _getImageUrl(user!['avatar']))
                      : null,
                  child: user?['avatar'] == null
                      ? Text((user?['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 14))
                      : null,
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(user?['name'] ?? 'Unknown',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      if (user?['kyc'] == true)
                        const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified,
                                size: 14, color: Colors.blue)),
                      if (user?['is_pro'] == true)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFF97316)]),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text('PRO',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      ...List.generate(
                          5,
                          (i) => Icon(Icons.star,
                              size: 12,
                              color: i < rating.round()
                                  ? Colors.amber
                                  : Colors.grey[300])),
                      const SizedBox(width: 4),
                      Text('${rating.toStringAsFixed(1)} ',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 11)),
                      GestureDetector(
                        onTap: _scrollToReviews,
                        child: Text(
                            '($reviewsCount ${_t('workspace_reviews', 'রিভিউ')})',
                            style: const TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontSize: 11,
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price and Package Details Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('৳${_gigPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                      ],
                    ),
                    Text(_t('workspace_starting_price', 'শুরুর দাম'),
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ),
              // Package Features
              Expanded(
                child: Column(
                  children: [
                    _buildPackageRow(_t('workspace_delivery', 'ডেলিভারি'),
                        '${_gig!['delivery_time'] ?? 3} ${_t('workspace_days', 'দিন')}'),
                    _buildPackageRow(_t('workspace_revisions', 'রিভিশন'),
                        '${_gig!['revisions'] ?? 2}'),
                    _buildPackageRow(_t('workspace_category', 'ক্যাটাগরি'),
                        _getCategoryLabel(_gig!['category']),
                        isCategory: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Order Flow or Buttons
          if (_showOrderFlow)
            _buildOrderFlow()
          else if (!_isOwnGig)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                        '${_t('workspace_order', 'অর্ডার')} (৳${_gigPrice.toStringAsFixed(0)})',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _contactSeller,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/icons/chat_icon.png',
                            width: 18,
                            height: 18,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.chat, size: 18)),
                        const SizedBox(width: 6),
                        Text(_t('workspace_contact', 'যোগাযোগ'),
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          _t('workspace_own_gig_notice',
                              'এটি আপনার গিগ। আমার গিগ থেকে ম্যানেজ করুন।'),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF8B5CF6)))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderFlow() {
    return Column(
      children: [
        // Progress Steps
        Row(
          children: [
            _buildOrderStep(1, _t('workspace_step_review', 'রিভিউ')),
            Expanded(
                child: Container(
                    height: 2,
                    color: _orderStep > 1 ? Colors.green : Colors.grey[300])),
            _buildOrderStep(2, _t('workspace_step_payment', 'পেমেন্ট')),
            Expanded(
                child: Container(
                    height: 2,
                    color: _orderStep > 2 ? Colors.green : Colors.grey[300])),
            _buildOrderStep(3, _t('workspace_step_complete', 'সম্পন্ন')),
          ],
        ),
        const SizedBox(height: 16),

        // Step Content
        if (_orderStep == 1) _buildReviewStep(),
        if (_orderStep == 2) _buildPaymentStep(),
        if (_orderStep == 3) _buildCompleteStep(),
      ],
    );
  }

  Widget _buildOrderStep(int step, String label) {
    final isCompleted = _orderStep > step;
    final isCurrent = _orderStep == step;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.green
                : isCurrent
                    ? const Color(0xFF8B5CF6)
                    : Colors.grey[300],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text('$step',
                    style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: isCurrent ? Colors.black87 : Colors.grey[500])),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              _buildSummaryRow(_t('workspace_gig', 'গিগ'),
                  _truncateTitle(_gig!['title']?.toString() ?? '', 25)),
              _buildSummaryRow(_t('workspace_delivery', 'ডেলিভারি'),
                  '${_gig!['delivery_time'] ?? 3} ${_t('workspace_days', 'দিন')}'),
              _buildSummaryRow(_t('workspace_revisions', 'রিভিশন'),
                  '${_gig!['revisions'] ?? 2}'),
              const Divider(height: 16),
              _buildSummaryRow(_t('workspace_total', 'মোট'),
                  '৳${_gigPrice.toStringAsFixed(2)}',
                  isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(_t('workspace_requirements_optional', 'প্রয়োজনীয়তা (ঐচ্ছিক)'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: _requirementsController,
          maxLines: 3,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText:
                _t('workspace_requirements_hint', 'আপনার চাহিদা লিখুন...'),
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(10),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelOrder,
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10)),
                child: Text(_t('workspace_cancel', 'ক্যান্সেল'),
                    style: const TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _orderStep = 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(_t('workspace_continue', 'পরবর্তী'),
                    style: const TextStyle(fontSize: 13, color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balance Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF14B8A6)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('workspace_your_balance', 'আপনার ব্যালেন্স'),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('৳${_userBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              GestureDetector(
                onTap: _refreshBalance,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: _isRefreshingBalance
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: AdsyLoadingIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh,
                          color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Payment Summary
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              _buildSummaryRow(_t('workspace_order_amount', 'অর্ডারের টাকা'),
                  '৳${_gigPrice.toStringAsFixed(2)}'),
              _buildSummaryRow(
                  '${_t('workspace_service_fee', 'সার্ভিস ফি')} (${_formatFeePercent(_buyerFeePercent)}%)',
                  '৳${_serviceFee.toStringAsFixed(2)}'),
              const Divider(height: 16),
              _buildSummaryRow(_t('workspace_total_to_pay', 'মোট দিতে হবে'),
                  '৳${_totalToPay.toStringAsFixed(2)}',
                  isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Balance Status
        if (!_hasSufficientBalance)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                          _t('workspace_insufficient_balance',
                              'ব্যালেন্স যথেষ্ট নয়'),
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.red[800],
                              fontSize: 12)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const WalletScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(_t('workspace_add_funds', 'টাকা যোগ করুন'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    '${_t('workspace_you_need', 'আপনার আরও দরকার')} ৳${_balanceShortfall.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.red[600], fontSize: 11)),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                const SizedBox(width: 6),
                Text(
                    '${_t('workspace_balance_after', 'পেমেন্টের পর ব্যালেন্স')}: ৳${_balanceAfterPayment.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 11, color: Colors.blue[800])),
              ],
            ),
          ),
        const SizedBox(height: 8),

        // Escrow Notice
        Row(
          children: [
            Icon(Icons.shield, size: 14, color: Colors.green[600]),
            const SizedBox(width: 6),
            Expanded(
                child: Text(
                    _t('workspace_escrow_notice',
                        'কাজ শেষ না হওয়া পর্যন্ত টাকা এসক্রোতে রাখা থাকবে'),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]))),
          ],
        ),
        const SizedBox(height: 12),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _orderStep = 1),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10)),
                child: Text(_t('workspace_back', 'পেছনে'),
                    style: const TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _hasSufficientBalance && !_isPlacingOrder
                    ? _submitOrder
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasSufficientBalance
                      ? const Color(0xFF8B5CF6)
                      : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: _isPlacingOrder
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: AdsyLoadingIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        '${_t('workspace_pay', 'পে')} ৳${_totalToPay.toStringAsFixed(2)}',
                        style:
                            const TextStyle(fontSize: 13, color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration:
              BoxDecoration(color: Colors.green[100], shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 32, color: Colors.green),
        ),
        const SizedBox(height: 12),
        Text(_t('workspace_order_placed', 'অর্ডার হয়ে গেছে!'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
            _t('workspace_payment_success',
                'পেমেন্ট সফল। সেলারকে জানানো হয়েছে।'),
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              _buildSummaryRow(
                  _t('workspace_order_id', 'অর্ডার আইডি'),
                  _orderResult?['order']?['id']
                          ?.toString()
                          .substring(0, 8)
                          .toUpperCase() ??
                      'N/A'),
              _buildSummaryRow(_t('workspace_new_balance', 'নতুন ব্যালেন্স'),
                  '৳${_orderResult?['payment']?['new_balance']?.toString() ?? '0'}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelOrder,
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10)),
                child: Text(_t('workspace_close', 'বন্ধ করুন'),
                    style: const TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to orders
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(_t('workspace_view_order', 'অর্ডার দেখুন'),
                    style: const TextStyle(fontSize: 13, color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  fontSize: isBold ? 14 : 12)),
        ],
      ),
    );
  }

  Widget _buildTrustIndicators() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrustItem(Icons.visibility,
              '${_formatViewCount(_gig!['views_count'] ?? 0)} ${_t('workspace_views', 'ভিউ')}'),
          _buildTrustItem(
              Icons.access_time, _getActiveStatus(_gig!['updated_at'])),
          GestureDetector(
            onTap: _handleShare,
            child:
                _buildTrustItem(Icons.share, _t('workspace_share', 'শেয়ার')),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildRelatedGigs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_t('workspace_similar_gigs', 'একই ধরনের গিগ'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(_t('workspace_view_all', 'সব দেখুন'),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8B5CF6))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _relatedGigs.length,
              itemBuilder: (context, index) {
                final gig = _relatedGigs[index];
                final user = gig['user'] as Map<String, dynamic>?;
                final rating = (gig['rating'] ?? 0).toDouble();
                final reviewsCount = gig['reviews_count'] ?? 0;

                return GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              GigDetailScreen(gigId: gig['id'].toString())),
                    );
                  },
                  child: Container(
                    width: 160,
                    margin: EdgeInsets.only(
                        right: index < _relatedGigs.length - 1 ? 10 : 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          child: CachedNetworkImage(
                            imageUrl:
                                _getImageUrl(gig['image_url'] ?? gig['image']),
                            height: 80,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (c, u) =>
                                Container(color: Colors.grey[200]),
                            errorWidget: (c, u, e) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 20)),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Owner info
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundImage: user?['avatar'] != null
                                          ? CachedNetworkImageProvider(
                                              _getImageUrl(user!['avatar']))
                                          : null,
                                      child: user?['avatar'] == null
                                          ? Text(
                                              (user?['name'] ?? 'U')[0]
                                                  .toUpperCase(),
                                              style:
                                                  const TextStyle(fontSize: 8))
                                          : null,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        user?['name'] ?? 'Unknown',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600]),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (user?['kyc'] == true)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 3),
                                        child: Icon(Icons.verified,
                                            size: 12, color: Colors.blue),
                                      ),
                                    if (user?['is_pro'] == true)
                                      Container(
                                        margin: const EdgeInsets.only(left: 3),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFF59E0B),
                                                Color(0xFFF97316)
                                              ]),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: const Text('PRO',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 7,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Title
                                Text(
                                  gig['title'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                // Rating with review count and price
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 12, color: Colors.amber),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${rating.toStringAsFixed(1)} ($reviewsCount)',
                                      style: TextStyle(
                                          fontSize: 9, color: Colors.grey[600]),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '৳${gig['price']}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF8B5CF6)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildReviewsSection(int reviewsCount) {
    return Container(
      key: _reviewsSectionKey,
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_t('workspace_reviews', 'রিভিউ')} ($_totalReviewsCount)',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                      '${(_gig!['rating'] ?? 0).toStringAsFixed(1)} ${_t('workspace_out_of_5', '৫-এর মধ্যে')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_reviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Icon(Icons.star_border, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(_t('workspace_no_reviews', 'এখনো কোনো রিভিউ নেই'),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            )
          else ...[
            Text(
                '$_totalReviewsCount ${_t('workspace_reviews', 'রিভিউ')}-এর মধ্যে ${_reviews.length} দেখানো হচ্ছে',
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            const SizedBox(height: 8),
            ..._reviews.map((review) => _buildReviewCard(review)),
            if (_hasMoreReviews)
              Center(
                child: TextButton(
                  onPressed: _isLoadingMoreReviews ? null : _loadMoreReviews,
                  child: _isLoadingMoreReviews
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: AdsyLoadingIndicator(strokeWidth: 2))
                      : Text(
                          '${_t('workspace_see_more', 'আরও দেখুন')} (${_totalReviewsCount - _reviews.length} ${_t('workspace_remaining', 'বাকি')})',
                          style: const TextStyle(fontSize: 12)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPackageRow(String label, String value,
      {bool isCategory = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color:
                      isCategory ? const Color(0xFF8B5CF6) : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final user = review['user'] as Map<String, dynamic>?;
    final rating = (review['rating'] ?? 0).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: user?['avatar'] != null
                    ? CachedNetworkImageProvider(_getImageUrl(user!['avatar']))
                    : null,
                child: user?['avatar'] == null
                    ? Text((user?['name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 10))
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                            user?['name'] ??
                                _t('workspace_anonymous', 'অজ্ঞাত'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 12)),
                        if (user?['kyc'] == true)
                          const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.verified,
                                  size: 12, color: Colors.blue)),
                        if (user?['is_pro'] == true)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFFF59E0B),
                                Color(0xFFF97316)
                              ]),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text('PRO',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        ...List.generate(
                            5,
                            (i) => Icon(Icons.star,
                                size: 10,
                                color: i < rating
                                    ? Colors.amber
                                    : Colors.grey[300])),
                        const SizedBox(width: 4),
                        Text('$rating/5',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
              Text(_formatReviewDate(review['created_at']),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
          if (review['comment'] != null &&
              review['comment'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review['comment'],
                style: TextStyle(
                    color: Colors.grey[700], fontSize: 12, height: 1.4)),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, -1))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t('workspace_starting_at', 'শুরু'),
                    style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                Text('৳${_gigPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5CF6))),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _startOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(_t('workspace_order_now', 'এখনই অর্ডার করুন'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(_t('workspace_gig_not_found', 'গিগ পাওয়া যায়নি'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(_t('workspace_gig_removed', 'গিগটি হয়তো সরিয়ে ফেলা হয়েছে'),
              style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t('workspace_go_back', 'ফিরে যান'))),
        ],
      ),
    );
  }
}
