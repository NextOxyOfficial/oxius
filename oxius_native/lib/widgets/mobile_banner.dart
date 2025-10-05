import 'dart:async';
import 'package:flutter/material.dart';
import '../services/eshop_service.dart';

class MobileBannerWidget extends StatefulWidget {
  final int autoplayInterval;
  final bool autoplayEnabled;
  final bool showSwipeHint;
  
  const MobileBannerWidget({
    super.key,
    this.autoplayInterval = 4000,
    this.autoplayEnabled = true,
    this.showSwipeHint = false,
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
  Timer? _progressTimer;
  double _progressWidth = 0.0;
  
  // Touch handling
  double _touchStartX = 0;
  double _touchEndX = 0;
  bool _isHandlingTouch = false;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBanners() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await EshopService.fetchEshopBanners(endpoint: '/eshop-banner/mobile/');
      
      if (mounted) {
        setState(() {
          _banners = response;
          _isLoading = false;
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
      print('Error fetching mobile banners: $e');
    }
  }

  void _startAutoplay() {
    _progressTimer?.cancel();
    _autoplayTimer?.cancel();
    
    setState(() {
      _progressWidth = 0.0;
    });

    // Progress bar animation
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && !_isHandlingTouch) {
        setState(() {
          _progressWidth += (100 / (widget.autoplayInterval / 100));
          if (_progressWidth >= 100) {
            _progressWidth = 0.0;
          }
        });
      }
    });

    // Slide transition
    _autoplayTimer = Timer.periodic(Duration(milliseconds: widget.autoplayInterval), (timer) {
      if (mounted && !_isHandlingTouch) {
        _nextSlide();
      }
    });
  }

  void _stopAutoplay() {
    _progressTimer?.cancel();
    _autoplayTimer?.cancel();
  }

  void _resetAutoplay() {
    if (_banners.length > 1 && widget.autoplayEnabled) {
      _startAutoplay();
    }
  }

  void _nextSlide() {
    if (_banners.isEmpty) return;
    setState(() {
      _currentSlide = (_currentSlide + 1) % _banners.length;
    });
  }

  void _previousSlide() {
    if (_banners.isEmpty) return;
    setState(() {
      _currentSlide = (_currentSlide - 1 + _banners.length) % _banners.length;
    });
  }

  void _goToSlide(int index) {
    setState(() {
      _currentSlide = index;
    });
    _resetAutoplay();
  }

  void _handleTouchStart(TapDownDetails details) {
    _isHandlingTouch = true;
    _touchStartX = details.globalPosition.dx;
    _stopAutoplay();
  }

  void _handleTouchEnd(TapUpDetails details) {
    _touchEndX = details.globalPosition.dx;
    _isHandlingTouch = false;

    final swipeDiff = _touchEndX - _touchStartX;
    const minSwipeDistance = 50.0;

    if (swipeDiff > minSwipeDistance) {
      _previousSlide(); // Swipe right = previous slide
    } else if (swipeDiff < -minSwipeDistance) {
      _nextSlide(); // Swipe left = next slide
    }

    _resetAutoplay();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // Loading State
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: 2.0, // 50% height (2:1 ratio)
        child: Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
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
          color: Colors.grey.shade200,
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
          color: Colors.grey.shade200,
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

    // Banner Slider
    return GestureDetector(
      onTapDown: _handleTouchStart,
      onTapUp: _handleTouchEnd,
      child: Stack(
        children: [
          // Banners
          AspectRatio(
            aspectRatio: 2.0,
            child: Stack(
              children: [
                for (int i = 0; i < _banners.length; i++)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: i == _currentSlide ? 1.0 : 0.0,
                    child: _buildBannerItem(_banners[i], i),
                  ),
              ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
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
                                : Colors.white.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

          // Progress Bar
          if (_banners.length > 1 && widget.autoplayEnabled)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                color: Colors.white.withOpacity(0.2),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressWidth / 100,
                  child: Container(
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Swipe Hint
          if (widget.showSwipeHint && _banners.length > 1)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.1),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left, size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Swipe to see more',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade700),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade300,
                child: Icon(
                  Icons.broken_image,
                  size: 48,
                  color: Colors.grey.shade500,
                ),
              );
            },
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
                    Colors.black.withOpacity(0.7),
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
