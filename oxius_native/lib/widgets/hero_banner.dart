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

  // Build absolute URL for Django static assets used by Vue (e.g., /static/frontend/images/*.png)
  String _absStatic(String path) {
    if (path.isEmpty) return path;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    // These images live in the frontend's public folder and are served by the Nuxt dev server
    // Use port 3000 (frontend) instead of 8000 (Django) to avoid 404s for /static paths
    const origin = 'http://localhost:3000';
    final p = path.startsWith('/') ? path : '/$path';
    return '$origin$p';
  }

  // Provide candidate URLs (Nuxt dev, then Django) and try them in order
  List<String> _absStaticCandidates(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return [
      'http://localhost:3000$p',
      'http://localhost:8000$p',
    ];
  }

  // Mobile service buttons data matching Vue.js structure
  List<Map<String, dynamic>> get mobileServices => [
    {
      'icon': Icons.group,
      'image': '/static/frontend/images/globalconnection.png',
      'label': _translationService.t('business_network', fallback: 'Business Network'),
      'color': const Color(0xFF3B82F6), // Blue
      'bgColor': const Color(0xFFEFF6FF),
    },
    {
      'icon': Icons.newspaper,
      'image': '/static/frontend/images/news.png',
      'label': _translationService.t('adsy_news', fallback: 'News'),
      'color': const Color(0xFFF59E0B), // Amber
      'bgColor': const Color(0xFFFFF7ED),
    },
    {
      'icon': Icons.monetization_on,
      'image': '/static/frontend/images/money.png',
      'label': _translationService.t('earn_money', fallback: 'Earn Money'),
      'color': const Color(0xFF10B981), // Emerald
      'bgColor': const Color(0xFFECFDF5),
    },
    {
      'icon': Icons.shopping_cart,
      'image': '/static/frontend/images/onlineshopping.png',
      'label': _translationService.t('eshop', fallback: 'eShop'),
      'color': const Color(0xFF8B5CF6), // Purple
      'bgColor': const Color(0xFFF5F3FF),
    },
    {
      'icon': Icons.sell,
      'image': '/static/frontend/images/sign.png',
      'label': _translationService.t('sale_listing', fallback: 'Sale Listings'),
      'color': const Color(0xFF4F46E5), // Indigo
      'bgColor': const Color(0xFFF0F9FF),
    },
    {
      'icon': Icons.psychology,
      'image': '/static/frontend/images/question.png',
      'label': _translationService.t('mindforce', fallback: 'MindForce'),
      'color': const Color(0xFF06B6D4), // Cyan
      'bgColor': const Color(0xFFE0F7FA),
    },
    {
      'icon': Icons.school,
      'image': '/static/frontend/images/onlinelearning.png',
      'label': _translationService.t('elearning', fallback: 'eLearning'),
      'color': const Color(0xFFE11D48), // Rose
      'bgColor': const Color(0xFFFFF1F2),
    },
    {
      'icon': Icons.medical_services,
      'image': '/static/frontend/images/medicalreport.png',
      'label': _translationService.t('shastho_sheba', fallback: 'Health Service'),
      'color': Colors.grey,
      'bgColor': const Color(0xFFF9FAFB),
      'isComingSoon': true,
    },
    {
      'icon': Icons.payment,
      'image': '/static/frontend/images/payment.png',
      'label': _translationService.t('bill_pay', fallback: 'Bill Pay'),
      'color': Colors.grey,
      'bgColor': const Color(0xFFF9FAFB),
      'isComingSoon': true,
    },
    {
      'icon': Icons.phone_android,
      'image': '/static/frontend/images/mobileapp.png',
      'label': _translationService.t('mobile_recharge', fallback: 'Mobile Recharge'),
      'color': const Color(0xFFEA580C), // Orange
      'bgColor': const Color(0xFFFFF7ED),
    },
    {
      'icon': Icons.account_balance_wallet,
      'image': '/static/frontend/images/transaction.png',
      'label': _translationService.t('adsy_pay', fallback: 'AdsyPay'),
      'color': const Color(0xFF84CC16), // Lime
      'bgColor': const Color(0xFFF7FEE7),
    },
    {
      'icon': Icons.star,
      'image': '/static/frontend/images/premium.png',
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
    _startHeroTimer();
  }

  void _onTranslationsChanged() {
    if (!mounted) return;
    setState(() {});
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
    _heroController.dispose();
    _translationService.removeListener(_onTranslationsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Mobile-only banner height
    double bannerHeight = screenWidth * 0.40; // Reduced from 0.45 to make room for service buttons

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
    final title = _translationService.t('social_business_network', fallback: 'Social Business Network');
    return Container(
      // Mobile-only margin
      margin: EdgeInsets.symmetric(horizontal: 2),
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
          // Header bar - professional pill with icon and translated title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF6F8FB), Color(0xFFF2F4F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Center(
              child: Container(
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
              ),
            ),
          ),
          // Grid area
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 12),
            child: _buildMobileServicesGrid(
              margin: EdgeInsets.symmetric(horizontal: 0),
            ),
          ),
        ],
      ),
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
              padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12, horizontal: 8),
              child: Text(
                _translationService.t('bangladesh_first_title', fallback: 'Bangladesh’s first'),
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
                final imageUrl = imagesToShow[index]['image'] ?? '';

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
                  // Remove overlay texts to keep images clean
                  child: const SizedBox.expand(),
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

  Widget _buildMobileServicesGrid({EdgeInsets? margin}) {
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 4 services per row like in Vue.js
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9, // Slightly taller than square
        ),
        itemCount: mobileServices.length,
        itemBuilder: (context, index) => _buildMobileServiceButton(mobileServices[index]),
      ),
    );
  }

  Widget _buildMobileServiceButton(Map<String, dynamic> service) {
    final bool isComingSoon = service['isComingSoon'] ?? false;
    return _ServiceTile(
      icon: service['icon'] as IconData?,
      imageUrl: service['image'] != null ? _absStatic(service['image'] as String) : null,
      imageUrlFallbacks: service['image'] != null ? _absStaticCandidates(service['image'] as String) : const [],
      label: service['label'] as String,
      color: service['color'] as Color,
      bgColor: service['bgColor'] as Color,
      comingSoonLabel: _translationService.t('coming_soon', fallback: 'Coming Soon'),
      isComingSoon: isComingSoon,
      onTap: isComingSoon
          ? null
          : () {
              debugPrint('Tapped on ${service['label']}');
              // TODO: Navigate to respective service pages
            },
    );
  }

}

class _ServiceTile extends StatefulWidget {
  final IconData? icon;
  final String? imageUrl;
  final List<String> imageUrlFallbacks;
  final String label;
  final Color color;
  final Color bgColor;
  final String comingSoonLabel;
  final bool isComingSoon;
  final VoidCallback? onTap;

  const _ServiceTile({
    this.icon,
    this.imageUrl,
    this.imageUrlFallbacks = const [],
    required this.label,
    required this.color,
    required this.bgColor,
    required this.comingSoonLabel,
    required this.isComingSoon,
    this.onTap,
  });

  @override
  State<_ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<_ServiceTile> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _controller;
  late final Animation<double> _breath;
  late final Animation<double> _drift; // vertical bob
  late final Animation<double> _tilt;  // slight rotation
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    final ease = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _breath = ease.drive(Tween<double>(begin: 0.99, end: 1.02));
    _drift  = ease.drive(Tween<double>(begin: -1.5, end: 1.5));
    _tilt   = ease.drive(Tween<double>(begin: -0.015, end: 0.015)); // ~0.9°
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
      onTapDown: disabled
          ? null
          : (_) => setState(() => _pressed = true),
      onTapCancel: disabled
          ? null
          : () => setState(() => _pressed = false),
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
                      child: widget.imageUrl != null
                          ? Image.network(
                              widget.imageUrlFallbacks.isNotEmpty
                                  ? widget.imageUrlFallbacks[_imageIndex]
                                  : widget.imageUrl!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                if (_imageIndex + 1 < widget.imageUrlFallbacks.length) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) setState(() => _imageIndex++);
                                  });
                                  return const SizedBox(width: 32, height: 32);
                                }
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
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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