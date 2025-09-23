import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/translation_service.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  final PageController _heroController = PageController();
  Timer? _heroTimer;
  int _currentHeroIndex = 0;
  List<dynamic> bannerImages = [];
  bool isLoading = true;
  final TranslationService _translationService = TranslationService();

  // Default banner images as fallback
  final List<String> defaultImages = [
    'https://picsum.photos/800/360?random=1',
    'https://picsum.photos/800/360?random=2',
    'https://picsum.photos/800/360?random=3',
  ];

  // Mobile service buttons data matching Vue.js structure
  List<Map<String, dynamic>> get mobileServices => [
    {
      'icon': Icons.group,
      'label': _translationService.t('business_network', fallback: 'Business Network'),
      'color': const Color(0xFF3B82F6), // Blue
      'bgColor': const Color(0xFFEFF6FF),
    },
    {
      'icon': Icons.newspaper,
      'label': _translationService.t('adsy_news', fallback: 'News'),
      'color': const Color(0xFFF59E0B), // Amber
      'bgColor': const Color(0xFFFFF7ED),
    },
    {
      'icon': Icons.monetization_on,
      'label': _translationService.t('earn_money', fallback: 'Earn Money'),
      'color': const Color(0xFF10B981), // Emerald
      'bgColor': const Color(0xFFECFDF5),
    },
    {
      'icon': Icons.shopping_cart,
      'label': _translationService.t('eshop', fallback: 'eShop'),
      'color': const Color(0xFF8B5CF6), // Purple
      'bgColor': const Color(0xFFF5F3FF),
    },
    {
      'icon': Icons.sell,
      'label': _translationService.t('sale_listing', fallback: 'Sale Listings'),
      'color': const Color(0xFF4F46E5), // Indigo
      'bgColor': const Color(0xFFF0F9FF),
    },
    {
      'icon': Icons.psychology,
      'label': _translationService.t('mindforce', fallback: 'MindForce'),
      'color': const Color(0xFF06B6D4), // Cyan
      'bgColor': const Color(0xFFE0F7FA),
    },
    {
      'icon': Icons.school,
      'label': _translationService.t('elearning', fallback: 'eLearning'),
      'color': const Color(0xFFE11D48), // Rose
      'bgColor': const Color(0xFFFFF1F2),
    },
    {
      'icon': Icons.medical_services,
      'label': _translationService.t('shastho_sheba', fallback: 'Health Service'),
      'color': Colors.grey,
      'bgColor': const Color(0xFFF9FAFB),
      'isComingSoon': true,
    },
    {
      'icon': Icons.payment,
      'label': _translationService.t('bill_pay', fallback: 'Bill Pay'),
      'color': Colors.grey,
      'bgColor': const Color(0xFFF9FAFB),
      'isComingSoon': true,
    },
    {
      'icon': Icons.phone_android,
      'label': _translationService.t('mobile_recharge', fallback: 'Mobile Recharge'),
      'color': const Color(0xFFEA580C), // Orange
      'bgColor': const Color(0xFFFFF7ED),
    },
    {
      'icon': Icons.account_balance_wallet,
      'label': _translationService.t('adsy_pay', fallback: 'AdsyPay'),
      'color': const Color(0xFF84CC16), // Lime
      'bgColor': const Color(0xFFF7FEE7),
    },
    {
      'icon': Icons.star,
      'label': _translationService.t('packeges', fallback: 'Membership'),
      'color': const Color(0xFFDB2777), // Pink
      'bgColor': const Color(0xFFFDF2F8),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadBannerImages();
    _startHeroTimer();
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
      // Use default images on network error
      setState(() {
        bannerImages = defaultImages.map((url) => {'image': url}).toList();
        isLoading = false;
      });
      print('Error loading banner images: $e');
    }
  }

  void _startHeroTimer() {
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      
      final totalImages = bannerImages.isNotEmpty ? bannerImages.length : defaultImages.length;
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
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    // For mobile, make banner height smaller to accommodate service buttons below
    double bannerHeight;
    if (isMobile) {
      bannerHeight = screenWidth * 0.35; // Reduced from 0.45 to make room for service buttons
    } else {
      bannerHeight = screenWidth * 0.25; // Desktop banner height
    }

    if (isMobile) {
      // Mobile layout with hero slider and service grid
      return Column(
        children: [
          // Hero Banner Slider
          _buildHeroSlider(bannerHeight),
          
          // Mobile Service Buttons Grid
          _buildMobileServicesGrid(),
        ],
      );
    } else {
      // Desktop layout - just the hero slider
      return _buildHeroSlider(bannerHeight);
    }
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

    final imagesToShow = bannerImages.isNotEmpty ? bannerImages : defaultImages.map((url) => {'image': url}).toList();

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
                final imageUrl = imagesToShow[index]['image'] ?? defaultImages[0];

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                      onError: (error, stackTrace) {
                        print('Error loading image: $error');
                      },
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome to AdsyClub',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: const Offset(1, 1),
                                  blurRadius: 3,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Business Network Platform',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              shadows: [
                                Shadow(
                                  offset: const Offset(1, 1),
                                  blurRadius: 3,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                      width: 8,
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

  Widget _buildMobileServicesGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 4 services per row like in Vue.js
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85, // Slightly taller than square
        ),
        itemCount: mobileServices.length,
        itemBuilder: (context, index) => _buildMobileServiceButton(mobileServices[index]),
      ),
    );
  }

  Widget _buildMobileServiceButton(Map<String, dynamic> service) {
    final bool isComingSoon = service['isComingSoon'] ?? false;
    
    return GestureDetector(
      onTap: isComingSoon ? null : () {
        // Handle service button tap
        debugPrint('Tapped on ${service['label']}');
        // TODO: Navigate to respective service pages
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Service Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: service['bgColor'],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: service['color'].withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              service['icon'],
              color: service['color'],
              size: 24,
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Service Label
          Text(
            service['label'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isComingSoon ? Colors.grey.shade600 : Colors.grey.shade800,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Coming Soon Badge
          if (isComingSoon)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 7,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}