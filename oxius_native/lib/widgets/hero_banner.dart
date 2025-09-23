import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';

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

  // Default banner images as fallback
  final List<String> defaultImages = [
    'https://picsum.photos/800/360?random=1',
    'https://picsum.photos/800/360?random=2',
    'https://picsum.photos/800/360?random=3',
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
    // Responsive height calculation
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth < 768 ? screenWidth * 0.45 : 280.0;
    
    if (isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          height: bannerHeight,
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
        ),
      );
    }

    final imagesToShow = bannerImages.isNotEmpty ? bannerImages : defaultImages.map((url) => {'image': url}).toList();

    return SliverToBoxAdapter(
      child: Container(
        height: bannerHeight,
        child: Stack(
          children: [
            // Banner Slider
            PageView.builder(
              controller: _heroController,
              onPageChanged: (index) {
                setState(() {
                  _currentHeroIndex = index;
                });
              },
              itemCount: imagesToShow.length,
              itemBuilder: (context, index) {
                final imageUrl = imagesToShow[index]['image'] ?? defaultImages[0];
                
                return Container(
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

            // Slide indicators
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
}