import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

class AdsScrollWidget extends StatefulWidget {
  final Map<String, dynamic> ads;
  final String sectionTitle;

  const AdsScrollWidget({
    super.key,
    required this.ads,
    required this.sectionTitle,
  });

  @override
  State<AdsScrollWidget> createState() => _AdsScrollWidgetState();
}

class _AdsScrollWidgetState extends State<AdsScrollWidget>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;
  bool _isPaused = false;
  
  // Responsive card dimensions
  double _cardWidth = 180;
  double _cardGap = 12;
  double _animationSpeed = 0.8;
  
  // Touch interaction
  double _startX = 0;
  double _startScrollPos = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCarousel();
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Process ads data with performance optimization (matching Vue logic)
  List<Map<String, dynamic>> get _adsArray {
    if (widget.ads['results'] == null) return [];
    
    final results = List<Map<String, dynamic>>.from(widget.ads['results']);
    const maxAds = 10; // Limit to maximum 10 random recent posts
    
    if (results.length <= maxAds) return results;
    
    // Randomly select 10 posts from available results
    final shuffled = List<Map<String, dynamic>>.from(results);
    shuffled.shuffle();
    return shuffled.take(maxAds).toList();
  }

  // Create duplicates for smooth continuous scrolling
  List<Map<String, dynamic>> get _displayedAds {
    if (_adsArray.isEmpty) return [];
    
    // Create duplicates based on array size for smooth scrolling
    final duplicateCount = _adsArray.length <= 5 ? 6 : 
                          _adsArray.length <= 8 ? 4 : 3;
    
    final duplicatedAds = <Map<String, dynamic>>[];
    for (int i = 0; i < duplicateCount; i++) {
      duplicatedAds.addAll(_adsArray);
    }
    
    return duplicatedAds;
  }

  void _initializeCarousel() {
    if (!mounted || _displayedAds.isEmpty) return;

    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Adaptive card sizing (matching Vue breakpoints)
    if (screenWidth < 640) {
      // Mobile: show 2 cards
      _cardWidth = screenWidth * 0.45;
      _animationSpeed = 0.6;
    } else if (screenWidth < 1024) {
      // Tablet: show 3 cards
      _cardWidth = screenWidth * 0.3;
      _animationSpeed = 0.8;
    } else {
      // Desktop: show 4-5 cards
      _cardWidth = screenWidth * 0.21;
      _animationSpeed = 1.0;
    }

    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    
    if (!_scrollController.hasClients || _displayedAds.isEmpty || !mounted) return;
    
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_isPaused || _isUserInteracting || !mounted || !_scrollController.hasClients) return;

      final currentPosition = _scrollController.offset;
      final maxScroll = _scrollController.position.maxScrollExtent;
      
      // Additional safety checks
      if (maxScroll <= 0 || _adsArray.isEmpty) {
        timer.cancel();
        return;
      }
      
      // Calculate one set width for continuous scrolling
      final originalLength = _adsArray.length;
      final oneSetWidth = originalLength * (_cardWidth + _cardGap);
      
      final newPosition = currentPosition + _animationSpeed;
      
      // Reset position for continuous scrolling effect
      if (newPosition > oneSetWidth && _displayedAds.length > originalLength * 2) {
        _scrollController.jumpTo(1.0); // Small offset to avoid visual jumps
      } else if (newPosition <= maxScroll) {
        _scrollController.animateTo(
          newPosition,
          duration: const Duration(milliseconds: 40),
          curve: Curves.linear,
        );
      }
    });
  }

  void _pauseAutoScroll() {
    _isPaused = true;
    _autoScrollTimer?.cancel();
  }

  void _resumeAutoScroll() {
    _isPaused = false;
    _startAutoScroll();
  }

  String _getImageSrc(Map<String, dynamic> ad) {
    // Check for medias array first
    if (ad['medias'] != null && 
        ad['medias'] is List && 
        (ad['medias'] as List).isNotEmpty) {
      final media = (ad['medias'] as List).first;
      if (media['image'] != null) {
        return media['image'].toString();
      }
    }
    
    // Check for direct image field
    if (ad['image'] != null) {
      return ad['image'].toString();
    }
    
    return 'https://placehold.co/300x200?text=No+Image';
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final priceStr = price.toString().trim();
    if (priceStr.isEmpty || priceStr == 'null') return '0';
    
    // Remove any non-digit characters except decimal points
    final cleanPrice = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleanPrice.isEmpty) return '0';
    
    // Format with commas
    try {
      final numericPrice = double.parse(cleanPrice);
      final intPrice = numericPrice.toInt();
      return intPrice.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
    } catch (e) {
      return '0';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inMinutes}m ago';
      }
    } catch (e) {
      return '';
    }
  }

  String _formatLocation(Map<String, dynamic> ad) {
    final upazila = ad['upazila']?.toString().trim() ?? '';
    final city = ad['city']?.toString().trim() ?? '';
    
    if (upazila.isNotEmpty && city.isNotEmpty) {
      return '$upazila, $city';
    } else if (city.isNotEmpty) {
      return city;
    } else if (upazila.isNotEmpty) {
      return upazila;
    } else {
      return 'Location not specified';
    }
  }

  String _formatTitle(Map<String, dynamic> ad) {
    final title = ad['title']?.toString().trim() ?? '';
    return title.isNotEmpty ? title : 'Untitled Ad';
  }

  @override
  Widget build(BuildContext context) {
    try {
      if (_displayedAds.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with accent line
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Stack(
                  children: [
                    // Gradient accent line
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF10B981), // emerald-500
                              Color(0xFF3B82F6), // blue-500
                              Color(0xFF8B5CF6), // purple-500
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Header content
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              
                            ),
                            child: Icon(
                              Icons.access_time,
                              size: 20,
                              color: Colors.green.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Recent Posts', // Changed from Recent Ads to Recent Posts
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Carousel content
              GestureDetector(
                onPanStart: (details) {
                  _isUserInteracting = true;
                  _startX = details.globalPosition.dx;
                  _startScrollPos = _scrollController.offset;
                  _pauseAutoScroll();
                },
                onPanUpdate: (details) {
                  if (!_scrollController.hasClients || !mounted) return;
                  
                  final currentX = details.globalPosition.dx;
                  final diff = _startX - currentX;
                  final newPosition = _startScrollPos + diff;
                  
                  // Apply position with bounds
                  final maxScroll = _scrollController.position.maxScrollExtent;
                  if (newPosition >= 0 && newPosition <= maxScroll) {
                    try {
                      _scrollController.jumpTo(newPosition);
                    } catch (e) {
                      // Ignore scroll errors during user interaction
                    }
                  }
                },
                onPanEnd: (details) {
                  _isUserInteracting = false;
                  // Resume auto-scroll after delay
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) _resumeAutoScroll();
                  });
                },
                child: MouseRegion(
                  onEnter: (_) => _pauseAutoScroll(),
                  onExit: (_) => _resumeAutoScroll(),
                  child: Container(
                    height: 220, // Fixed height for card + padding
                    padding: const EdgeInsets.all(14),
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(), // Prevent overscroll
                      itemCount: _displayedAds.length,
                      itemBuilder: (context, index) {
                        final ad = _displayedAds[index];
                        return Container(
                          width: _cardWidth,
                          margin: EdgeInsets.only(
                            right: index < _displayedAds.length - 1 ? _cardGap : 0,
                          ),
                          child: _buildAdCard(ad),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Return a fallback widget if there's any error
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load ads',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    try {
      return SizedBox(
        height: 192, // Fixed total card height
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image container with price badge - fixed 120px
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: CachedNetworkImage(
                        imageUrl: _getImageSrc(ad),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 32),
                        ),
                      ),
                    ),
                  ),
                  
                  // Price badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '\u09f3${_formatPrice(ad['price'])}',
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Content area
              Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      _formatTitle(ad),
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Location
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _formatLocation(ad),
                            style: GoogleFonts.roboto(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 1),
                    
                    // Date
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            _formatDate(ad['created_at']?.toString()),
                            style: GoogleFonts.roboto(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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
    } catch (e) {
      // Return a fallback ad card if there's any error
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 24,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 4),
              Text(
                'Ad unavailable',
                style: GoogleFonts.roboto(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}