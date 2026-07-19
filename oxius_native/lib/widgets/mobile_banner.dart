import 'dart:async';
import 'package:flutter/material.dart';
import 'package:oxius_native/utils/image_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/deep_link_service.dart';
import '../services/eshop_service.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class MobileBannerWidget extends StatefulWidget {
  final int autoplayInterval;
  final bool autoplayEnabled;
  final bool showSwipeHint;
  final String endpoint;

  const MobileBannerWidget({
    super.key,
    this.autoplayInterval = 4000,
    this.autoplayEnabled = true,
    this.showSwipeHint = false,
    this.endpoint = '/banners/', // Default to main banners
  });

  @override
  State<MobileBannerWidget> createState() => _MobileBannerWidgetState();
}

class _MobileBannerWidgetState extends State<MobileBannerWidget> {
  List<Map<String, dynamic>> _banners = [];
  bool _isLoading = true;
  String? _error;
  int _currentSlide = 0;
  Timer? _autoplayTimer;

  // Peek carousel: the next banner stays partially visible on the right so
  // it's obvious there are more slides waiting. A single banner gets the
  // full width (no peek to hint at).
  PageController _pageController = PageController(viewportFraction: 0.92);

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchBanners() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Use the endpoint from widget parameter
      final response =
          await EshopService.fetchEshopBanners(endpoint: widget.endpoint);

      if (mounted) {
        setState(() {
          _banners = response;
          _isLoading = false;
          if (_banners.length <= 1) {
            _pageController.dispose();
            _pageController = PageController();
          }
        });

        // Start autoplay if there are multiple banners
        if (_banners.length > 1 && widget.autoplayEnabled) {
          _startAutoplay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load banners. Please try again later.';
          _isLoading = false;
        });
      }
      debugPrint('Error fetching mobile banners from ${widget.endpoint}: $e');
    }
  }

  void _startAutoplay() {
    _autoplayTimer?.cancel();
    _autoplayTimer = Timer.periodic(
        Duration(milliseconds: widget.autoplayInterval), (timer) {
      if (mounted) _nextSlide();
    });
  }

  void _resetAutoplay() {
    if (_banners.length > 1 && widget.autoplayEnabled) {
      _startAutoplay();
    }
  }

  void _nextSlide() {
    if (_banners.isEmpty) return;
    _animateToSlide((_currentSlide + 1) % _banners.length);
  }

  void _goToSlide(int index) {
    _animateToSlide(index);
    _resetAutoplay();
  }

  void _animateToSlide(int index) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
    setState(() => _currentSlide = index);
  }

  Future<void> _openBanner(int index) async {
    if (_banners.isEmpty || index >= _banners.length) return;
    final banner = _banners[index];
    final target = (banner['link'] ??
            banner['link_url'] ??
            banner['linkUrl'] ??
            banner['action_link'] ??
            banner['actionLink'] ??
            banner['target'] ??
            banner['url'] ??
            banner['href'] ??
            '')
        .toString()
        .trim();
    if (target.isEmpty) return;

    final linkType = (banner['link_type'] ??
            banner['linkType'] ??
            banner['open_type'] ??
            'internal')
        .toString()
        .trim()
        .toLowerCase();

    if (linkType == 'external') {
      final parsed = Uri.tryParse(target);
      final externalUri = parsed?.hasScheme == true
          ? parsed!
          : Uri.tryParse(
              target.startsWith('http') ? target : 'https://$target');
      if (externalUri != null) {
        await launchUrl(externalUri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    await DeepLinkService.instance.openInternalLink(target);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    // Loading State
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: 2.0, // 50% height (2:1 ratio)
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: AdsyLoadingIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
            ),
          ),
        ),
      );
    }

    // Error State
    if (_error != null) {
      return AspectRatio(
        aspectRatio: 2.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // No Banners State
    if (_banners.isEmpty) {
      return AspectRatio(
        aspectRatio: 2.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No mobile banners available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Banner Slider — peek carousel: next slide shows on the right edge.
    final singleBanner = _banners.length == 1;
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 2.08,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            onPageChanged: (i) {
              setState(() => _currentSlide = i);
              _resetAutoplay();
            },
            itemCount: _banners.length,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(right: singleBanner ? 0 : 8),
              child: GestureDetector(
                onTap: () => _openBanner(i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildBannerItem(_banners[i], i),
                ),
              ),
            ),
          ),
        ),

        // Dots Indicator
        if (_banners.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_banners.length, (index) {
                    return GestureDetector(
                      onTap: () => _goToSlide(index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _currentSlide
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBannerItem(Map<String, dynamic> banner, int index) {
    final imageUrl = banner['image']?.toString() ?? '';
    final title = banner['title']?.toString();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Banner Image
        if (imageUrl.isNotEmpty)
          AppImage.network(
            imageUrl,
            fit: BoxFit.cover,
            errorWidget: Container(
              color: Colors.grey.shade300,
              child: Icon(
                Icons.broken_image,
                size: 48,
                color: Colors.grey.shade500,
              ),
            ),
          )
        else
          Container(
            color: Colors.grey.shade300,
            child: Icon(
              Icons.image,
              size: 48,
              color: Colors.grey.shade500,
            ),
          ),

        // Title Overlay
        if (title != null && title.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}
