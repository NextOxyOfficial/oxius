import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/news_service.dart';
import '../services/translation_service.dart';
import '../services/notification_service.dart';
import '../services/user_state_service.dart';
import '../models/news_models.dart';
import '../config/app_config.dart';
import '../screens/eshop_screen.dart';
import '../screens/elearning_screen.dart';
import '../screens/news_screen.dart';
import '../screens/news_detail_screen.dart';
import '../screens/rideshare/rideshare_screen.dart';
import 'ios_web_redirect_screen.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  final PageController _heroController = PageController();
  Timer? _heroTimer;
  Timer? _newsTickerTimer;
  int _currentHeroIndex = 0;
  int _newsTickerIndex = 0;
  List<dynamic> bannerImages = [];
  List<BreakingNewsItem> _featuredNews = [];
  bool isLoading = true;
  bool _newsGlow = true;
  final TranslationService _translationService = TranslationService();
  final UserStateService _userStateService = UserStateService();
  int _unreadNotificationCount = 0;

  // Build absolute URL for static assets
  String _absStatic(String path) {
    return AppConfig.getAbsoluteUrl(path);
  }

  // Provide candidate URLs for static assets
  List<String> _absStaticCandidates(String path) {
    final absUrl = AppConfig.getAbsoluteUrl(path);
    return [absUrl];
  }

  // Mobile service buttons data with local asset icons
  List<Map<String, dynamic>> get mobileServices => [
        {
          'icon': Icons.group,
          'image': 'assets/images/globalconnection.png',
          'label': _translationService.t('business_network',
              fallback: 'Business Network'),
          'color': const Color(0xFF3B82F6), // Blue
          'bgColor': const Color(0xFFEFF6FF),
        },
        {
          'icon': Icons.newspaper,
          'image': 'assets/images/news.png',
          'label': _translationService.t('adsy_news', fallback: 'News'),
          'color': const Color(0xFFF59E0B), // Amber
          'bgColor': const Color(0xFFFFF7ED),
        },
        {
          'icon': Icons.monetization_on,
          'image': 'assets/images/money.png',
          'label': _translationService.t('earn_money', fallback: 'Earn Money'),
          'color': const Color(0xFF10B981), // Emerald
          'bgColor': const Color(0xFFECFDF5),
        },
        {
          'icon': Icons.shopping_cart,
          'image': 'assets/images/onlineshopping.png',
          'label': _translationService.t('eshop', fallback: 'eShop'),
          'color': const Color(0xFF8B5CF6), // Purple
          'bgColor': const Color(0xFFF5F3FF),
        },
        {
          'icon': Icons.sell,
          'image': 'assets/images/sign.png',
          'label':
              _translationService.t('sale_listing', fallback: 'Buy & Sell'),
          'color': const Color(0xFF4F46E5), // Indigo
          'bgColor': const Color(0xFFF0F9FF),
        },
        {
          'icon': Icons.directions_car_rounded,
          'image': 'assets/images/rideshare.png',
          'label': _translationService.t('ride_share', fallback: 'Ride Share'),
          'color': const Color(0xFF10B981), // Green
          'bgColor': const Color(0xFFECFDF5),
        },
        {
          'icon': Icons.psychology,
          'image': 'assets/images/question.png',
          'label': _translationService.t('mindforce', fallback: 'MindForce'),
          'color': const Color(0xFF06B6D4), // Cyan
          'bgColor': const Color(0xFFE0F7FA),
        },
        {
          'icon': Icons.school,
          'image': 'assets/images/onlinelearning.png',
          'label': _translationService.t('elearning', fallback: 'eLearning'),
          'color': const Color(0xFFE11D48), // Rose
          'bgColor': const Color(0xFFFFF1F2),
        },
        {
          'icon': Icons.medical_services,
          'image': 'assets/images/medicalreport.png',
          'label': _translationService.t('classified_service',
              fallback: 'আমার সেবা'),
          'color': const Color(0xFF0FA36B),
          'bgColor': const Color(0xFFECFDF5),
        },
        {
          'icon': Icons.phone_android,
          'image': 'assets/images/mobileapp.png',
          'label': _translationService.t('mobile_recharge',
              fallback: 'Mobile Recharge'),
          'color': const Color(0xFFEA580C), // Orange
          'bgColor': const Color(0xFFFFF7ED),
        },
        {
          'icon': Icons.account_balance_wallet,
          'image': 'assets/images/transaction.png',
          'label': _translationService.t('adsy_pay', fallback: 'AdsyPay'),
          'color': const Color(0xFF84CC16), // Lime
          'bgColor': const Color(0xFFF7FEE7),
        },
        {
          'icon': Icons.star,
          'image': 'assets/images/premium.png',
          'label': _translationService.t('packeges', fallback: 'Membership'),
          'color': const Color(0xFFDB2777), // Pink
          'bgColor': const Color(0xFFFDF2F8),
        },
      ];

  @override
  void initState() {
    super.initState();
    // Listen for language changes BEFORE initialization to avoid missing early notifications
    _translationService.addListener(_onTranslationsChanged);
    // Initialize translations and ensure we rebuild once initial load completes
    _translationService.initialize().then((_) {
      if (mounted) setState(() {});
    });
    _loadBannerImages();
    _loadFeaturedNews();
    _startHeroTimer();

    // Listen to user state changes
    _userStateService.addListener(_onUserStateChanged);

    // Load notification count if authenticated
    if (_userStateService.isAuthenticated) {
      _loadUnreadNotificationCount();
    }
  }

  void _onTranslationsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onUserStateChanged() {
    if (mounted) {
      setState(() {});
      // Refresh notification count when user state changes
      if (_userStateService.isAuthenticated) {
        _loadUnreadNotificationCount();
      } else {
        setState(() {
          _unreadNotificationCount = 0;
        });
      }
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final result = await NotificationService.getNotifications(page: 1);
      final count = result['unreadCount'] ?? 0;

      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      print('❌ Hero Banner: Error loading notification count: $e');
    }
  }

  Future<void> _loadFeaturedNews() async {
    final items = await NewsService.getBreakingNews();
    if (!mounted) return;
    setState(() {
      _featuredNews = items.take(8).toList();
      _newsTickerIndex = 0;
    });
    _startNewsTicker();
  }

  void _startNewsTicker() {
    _newsTickerTimer?.cancel();
    if (_featuredNews.length <= 1) return;
    _newsTickerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _featuredNews.isEmpty) return;
      setState(() {
        _newsTickerIndex = (_newsTickerIndex + 1) % _featuredNews.length;
        _newsGlow = !_newsGlow;
      });
    });
  }

  // Load banner images from API
  Future<void> _loadBannerImages() async {
    try {
      final images = await ApiService.loadBannerImages();
      setState(() {
        bannerImages = images;
        isLoading = false;
      });
    } catch (e) {
      // Leave bannerImages empty on network error
      setState(() {
        isLoading = false;
      });
      print('Error loading banner images: $e');
    }
  }

  void _startHeroTimer() {
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;

      final totalImages = bannerImages.length;
      if (totalImages > 1) {
        setState(() {
          _currentHeroIndex = (_currentHeroIndex + 1) % totalImages;
        });

        if (_heroController.hasClients) {
          _heroController.animateToPage(
            _currentHeroIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _newsTickerTimer?.cancel();
    _heroController.dispose();
    _translationService.removeListener(_onTranslationsChanged);
    _userStateService.removeListener(_onUserStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Mobile-only banner height
    double bannerHeight = screenWidth *
        0.40; // Reduced from 0.45 to make room for service buttons

    // Mobile layout: slider, then service grid
    return Column(
      children: [
        _buildHeroSlider(bannerHeight),
        const SizedBox(height: 8),
        _buildServicesSection(),
      ],
    );
  }

  // Professional card that wraps the services with a clean header
  Widget _buildServicesSection() {
    return Container(
      // Mobile-only margin
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFeaturedNewsTicker(),
          // Grid area
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 8),
            child: _buildMobileServicesGrid(
              margin: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedNewsTicker() {
    if (_featuredNews.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F8FB), Color(0xFFF2F4F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Center(
          child: _buildTickerLabel(
            _translationService.t('social_business_network',
                fallback: 'Social Business Network'),
          ),
        ),
      );
    }

    final item = _featuredNews[_newsTickerIndex % _featuredNews.length];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _newsGlow
              ? const [Color(0xFFFFF7ED), Color(0xFFEFF6FF)]
              : const [Color(0xFFECFDF5), Color(0xFFFFFBEB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _newsGlow ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (_newsGlow ? const Color(0xFFF59E0B) : const Color(0xFF10B981))
                    .withOpacity(_newsGlow ? 0.10 : 0.07),
            blurRadius: _newsGlow ? 9 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openFeaturedNews(item),
        child: Row(
          children: [
            _buildBreakingHeader(),
            const SizedBox(width: 7),
            Expanded(child: _buildFeaturedNewsTitle(item)),
            const SizedBox(width: 8),
            _buildDetailsPill(),
          ],
        ),
      ),
    );
  }

  String get _breakingNewsLabel {
    final languageCode = _translationService.currentLanguage
        .toLowerCase()
        .split(RegExp(r'[-_]'))
        .first;
    return _translationService.t(
      'breaking_news',
      fallback: languageCode.startsWith('en')
          ? 'Breaking News'
          : '\u09ac\u09bf\u09b6\u09c7\u09b7 \u09b8\u0982\u09ac\u09be\u09a6',
    );
  }

  Widget _buildBreakingHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 850),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(_newsGlow ? 0.20 : 0.10),
            blurRadius: _newsGlow ? 6 : 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.campaign_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            _breakingNewsLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedNewsTitle(BreakingNewsItem item) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0.10, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return SlideTransition(
            position: offset,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Text(
          item.displayTitle,
          key: ValueKey('${item.id}_${item.displayTitle}'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            height: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'বিস্তারিত',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D9488),
            ),
          ),
          SizedBox(width: 1),
          Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0D9488)),
        ],
      ),
    );
  }

  Widget _buildTickerLabel(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.apps, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ) ??
                TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
          ),
        ],
      ),
    );
  }

  void _openFeaturedNews(BreakingNewsItem item) {
    final slug = (item.newsSlug ?? '').trim();
    if (slug.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NewsScreen()),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewsDetailScreen(slug: slug)),
    );
  }

  Widget _buildPremiumArea({required double height, required bool isMobile}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 8 : 12, horizontal: 8),
              child: Text(
                _translationService.t('bangladesh_first_title',
                    fallback: 'Bangladesh’s first'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ) ??
                    TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
              ),
            ),
            // You can extend with more premium content blocks here later
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSlider(double height) {
    if (isLoading) {
      return Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final imagesToShow = bannerImages;

    if (imagesToShow.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Hero PageView
            PageView.builder(
              controller: _heroController,
              itemCount: imagesToShow.length,
              onPageChanged: (index) {
                setState(() {
                  _currentHeroIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final banner = Map<String, dynamic>.from(imagesToShow[index]);
                final rawImageUrl = banner['image'] ?? '';
                final imageUrl = AppConfig.getAbsoluteUrl(rawImageUrl);
                final target = _bannerTarget(banner);

                print('🖼️ Loading banner image: $imageUrl');

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap:
                      target == null ? null : () => _openBannerTarget(target),
                  child: Container(
                    width: double.infinity,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade300,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('❌ Banner image error: $error');
                        print('❌ URL: $imageUrl');
                        return Container(
                          color: Colors.grey.shade300,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    size: 48, color: Colors.grey.shade600),
                                const SizedBox(height: 8),
                                Text(
                                  'Image failed to load',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            // Slide Indicators
            if (imagesToShow.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    imagesToShow.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 4,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentHeroIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _bannerTarget(Map<String, dynamic> banner) {
    final raw = (banner['link'] ?? banner['target'] ?? banner['url'] ?? '')
        .toString()
        .trim();
    return raw.isEmpty ? null : raw;
  }

  Future<void> _openBannerTarget(String target) async {
    final parsed = Uri.tryParse(target);
    if (parsed != null && parsed.hasScheme) {
      final isAdsyclub =
          parsed.host == 'adsyclub.com' || parsed.host == 'www.adsyclub.com';
      if (!isAdsyclub) {
        await launchUrl(parsed, mode: LaunchMode.externalApplication);
        return;
      }

      final internalPath = parsed.path.isEmpty ? '/' : parsed.path;
      _navigateToBannerRoute(
        parsed.hasQuery ? '$internalPath?${parsed.query}' : internalPath,
      );
      return;
    }

    _navigateToBannerRoute(target);
  }

  void _navigateToBannerRoute(String target) {
    final normalized = target.trim().toLowerCase();
    final withoutSlash =
        normalized.startsWith('/') ? normalized.substring(1) : normalized;
    final pathOnly = withoutSlash.split('?').first;
    final aliases = <String, String>{
      '': '/',
      'home': '/',
      'eshop': '/eshop',
      'e-shop': '/eshop',
      'shop': '/eshop',
      'business-network': '/business-network',
      'business_network': '/business-network',
      'network': '/business-network',
      'bn': '/business-network',
      'adsy-news': '/adsy-news',
      'news': '/adsy-news',
      'rideshare': '/rideshare',
      'ride-share': '/rideshare',
      'ride_share': '/rideshare',
      'sale': '/sale',
      'sale-marketplace': '/sale',
      'marketplace': '/sale',
      'buy-sell': '/sale',
      'classified': '/classified',
      'my-services': '/classified',
      'services': '/classified',
      'micro-gigs': '/micro-gigs',
      'microgigs': '/micro-gigs',
      'earn-money': '/micro-gigs',
      'mobile-recharge': '/mobile-recharge',
      'recharge': '/mobile-recharge',
      'adsy-pay': '/deposit-withdraw',
      'wallet': '/deposit-withdraw',
      'deposit-withdraw': '/deposit-withdraw',
      'mindforce': '/mindforce',
      'elearning': '/elearning',
      'e-learning': '/elearning',
      'courses': '/elearning',
      'food-zone': '/food-zone',
      'membership': '/upgrade-to-pro',
      'packages': '/upgrade-to-pro',
      'upgrade-to-pro': '/upgrade-to-pro',
    };

    final route = aliases[pathOnly] ??
        (normalized.startsWith('/') ? target.trim() : '/$withoutSlash');

    if (route == '/upgrade-to-pro' && isIOSPlatform) {
      _showIOSMembershipDialog(context);
      return;
    }

    try {
      Navigator.pushNamed(context, route);
    } catch (e) {
      debugPrint('Unable to open banner route "$route": $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This banner destination is not available yet.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Widget _buildMobileServicesGrid({EdgeInsets? margin}) {
    final services = isIOSPlatform
        ? mobileServices.where((s) => s['isComingSoon'] != true).toList()
        : mobileServices;
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 4 services per row like in Vue.js
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent:
              90, // Fixed cell height — prevents gap on wide/large screens
        ),
        itemCount: services.length,
        itemBuilder: (context, index) =>
            _buildMobileServiceButton(services[index]),
      ),
    );
  }

  Widget _buildMobileServiceButton(Map<String, dynamic> service) {
    final bool isComingSoon = service['isComingSoon'] ?? false;
    // Check if this is the Business Network service to add notification count
    final isBusinessNetwork = service['label'] ==
            _translationService.t('business_network',
                fallback: 'Business Network') ||
        service['label'] == 'Business Network';

    return _ServiceTile(
      icon: service['icon'] as IconData?,
      imageAsset: service['image'] as String?,
      label: service['label'] as String,
      color: service['color'] as Color,
      bgColor: service['bgColor'] as Color,
      comingSoonLabel:
          _translationService.t('coming_soon', fallback: 'Coming Soon'),
      isComingSoon: isComingSoon,
      notificationCount: isBusinessNetwork ? _unreadNotificationCount : 0,
      onTap: isComingSoon
          ? null
          : () {
              debugPrint('Tapped on ${service['label']}');
              if (service['label'] == _translationService.t('eshop', fallback: 'eShop') ||
                  service['label'] == 'eShop' ||
                  service['label'] == 'E-Shop') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EshopScreen()),
                );
              } else if (service['label'] ==
                      _translationService.t('business_network',
                          fallback: 'Business Network') ||
                  service['label'] == 'Business Network') {
                Navigator.pushNamed(context, '/business-network');
              } else if (service['label'] == _translationService.t('adsy_news', fallback: 'News') ||
                  service['label'] == 'News' ||
                  service['label'] == 'Adsy News') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewsScreen()),
                );
              } else if (service['label'] == _translationService.t('elearning', fallback: 'eLearning') ||
                  service['label'] == 'eLearning' ||
                  service['label'] == 'E-Learning') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ElearningScreen()),
                );
              } else if (service['label'] == _translationService.t('sale_listing', fallback: 'Buy & Sell') ||
                  service['label'] == 'Buy & Sell') {
                Navigator.pushNamed(context, '/sale');
              } else if (service['label'] == _translationService.t('ride_share', fallback: 'Ride Share') ||
                  service['label'] == 'Ride Share') {
                Navigator.pushNamed(context, '/rideshare');
              } else if (service['label'] == _translationService.t('earn_money', fallback: 'Earn Money') ||
                  service['label'] == 'Earn Money') {
                Navigator.pushNamed(context, '/micro-gigs');
              } else if (service['label'] == _translationService.t('classified_service', fallback: 'আমার সেবা') ||
                  service['label'] == 'আমার সেবা' ||
                  service['label'] == 'My Services') {
                Navigator.pushNamed(context, '/classified');
              } else if (service['label'] == _translationService.t('mindforce', fallback: 'MindForce') ||
                  service['label'] == 'MindForce') {
                Navigator.pushNamed(context, '/mindforce');
              } else if (service['label'] == _translationService.t('mobile_recharge', fallback: 'Mobile Recharge') ||
                  service['label'] == 'Mobile Recharge') {
                Navigator.pushNamed(context, '/mobile-recharge');
              } else if (service['label'] ==
                      _translationService.t('adsy_pay', fallback: 'AdsyPay') ||
                  service['label'] == 'AdsyPay' ||
                  service['label'] == 'Adsy Pay') {
                Navigator.pushNamed(context, '/deposit-withdraw');
              } else if (service['label'] ==
                      _translationService.t('packeges', fallback: 'Membership') ||
                  service['label'] == 'Membership' ||
                  service['label'] == 'Packages') {
                if (isIOSPlatform) {
                  _showIOSMembershipDialog(context);
                } else {
                  Navigator.pushNamed(context, '/upgrade-to-pro');
                }
              } else {
                // For any unhandled services, show a debug message
                debugPrint('No navigation configured for: ${service['label']}');
              }
            },
    );
  }

  void _showIOSMembershipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFED7AA), width: 2),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: Color(0xFFEA580C), size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'Feature Unavailable on iOS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pro Membership upgrades are not available for purchase on iOS due to Apple App Store guidelines.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatefulWidget {
  final IconData? icon;
  final String? imageAsset;
  final String label;
  final Color color;
  final Color bgColor;
  final String comingSoonLabel;
  final bool isComingSoon;
  final VoidCallback? onTap;
  final int notificationCount;

  const _ServiceTile({
    this.icon,
    this.imageAsset,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.comingSoonLabel,
    required this.isComingSoon,
    this.onTap,
    this.notificationCount = 0,
  });

  @override
  State<_ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<_ServiceTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _controller;
  late final Animation<double> _breath;
  late final Animation<double> _drift; // vertical bob
  late final Animation<double> _tilt; // slight rotation

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    final ease = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _breath = ease.drive(Tween<double>(begin: 0.99, end: 1.02));
    _drift = ease.drive(Tween<double>(begin: -1.5, end: 1.5));
    _tilt = ease.drive(Tween<double>(begin: -0.015, end: 0.015)); // ~0.9°
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isComingSoon || widget.onTap == null;
    final labelColor = disabled ? Colors.grey.shade600 : Colors.grey.shade800;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with gradient border and aura
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Aura glow
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.color.withOpacity(0.12),
                        widget.color.withOpacity(0.0),
                      ],
                      radius: 0.85,
                    ),
                  ),
                ),
                // Icon container (borderless)
                AnimatedBuilder(
                  animation: _breath,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _drift.value),
                      child: Transform.rotate(
                        angle: _tilt.value,
                        child: Transform.scale(
                          scale: _breath.value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.bgColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.imageAsset != null
                          ? Image.asset(
                              widget.imageAsset!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  widget.icon ?? Icons.widgets_outlined,
                                  color: widget.color,
                                  size: 32,
                                );
                              },
                            )
                          : Icon(
                              widget.icon ?? Icons.widgets_outlined,
                              color: widget.color,
                              size: 32,
                            ),
                    ),
                  ),
                ),
                // Coming soon pill
                if (widget.isComingSoon)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 0.8),
                      ),
                      child: Text(
                        widget.comingSoonLabel,
                        style: const TextStyle(
                          fontSize: 7,
                          color: Colors.grey,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                // Notification badge
                if (widget.notificationCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        widget.notificationCount > 99
                            ? '99+'
                            : widget.notificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Label
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
                color: labelColor,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
