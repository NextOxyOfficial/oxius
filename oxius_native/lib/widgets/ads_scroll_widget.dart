import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/classified_post.dart';
import '../screens/classified_post_details_screen.dart';
import 'package:intl/intl.dart';

/// AdsScroll Widget - Horizontal scrolling carousel for recent classified ads
/// Optimized for mobile performance with auto-scrolling and touch controls
class AdsScrollWidget extends StatefulWidget {
  final List<ClassifiedPost>? ads;
  final String sectionTitle;

  const AdsScrollWidget({
    Key? key,
    this.ads,
    this.sectionTitle = 'Recent Posts',
  }) : super(key: key);

  @override
  State<AdsScrollWidget> createState() => _AdsScrollWidgetState();
}

class _AdsScrollWidgetState extends State<AdsScrollWidget> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _isPaused = false;
  double _scrollSpeed = 1.0;
  
  // Card dimensions
  double _cardWidth = 180.0;
  final double _cardGap = 12.0;

  @override
  void initState() {
    super.initState();
    _initializeAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAutoScroll() {
    if (widget.ads == null || widget.ads!.isEmpty) return;

    // Adjust card width based on screen size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final screenWidth = MediaQuery.of(context).size.width;
      setState(() {
        if (screenWidth < 600) {
          // Mobile: ~42% of screen width minus padding for 2 cards visible
          _cardWidth = (screenWidth - 48) * 0.42;
          _scrollSpeed = 0.6;
        } else if (screenWidth < 1024) {
          // Tablet: ~28% of screen width for 3 cards visible
          _cardWidth = (screenWidth - 48) * 0.28;
          _scrollSpeed = 0.8;
        } else {
          // Desktop: ~19% of screen width for 4-5 cards visible
          _cardWidth = (screenWidth - 48) * 0.19;
          _scrollSpeed = 1.0;
        }
      });

      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    
    if (widget.ads == null || widget.ads!.isEmpty) return;

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_isPaused || !_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      // Auto-scroll forward
      double newPosition = currentScroll + _scrollSpeed;

      // Loop back to start when reaching the end
      if (newPosition >= maxScroll) {
        newPosition = 0;
      }

      _scrollController.jumpTo(newPosition);
    });
  }

  void _pauseAutoScroll() {
    setState(() => _isPaused = true);
  }

  void _resumeAutoScroll() {
    setState(() => _isPaused = false);
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,##,###');
    return formatter.format(price);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  String _getImageUrl(ClassifiedPost ad) {
    try {
      if (ad.medias != null && ad.medias!.isNotEmpty) {
        final firstMedia = ad.medias![0];
        if (firstMedia.image != null && firstMedia.image!.isNotEmpty) {
          return firstMedia.image!;
        }
      }
    } catch (e) {
      print('Error getting image URL: $e');
    }
    return 'https://via.placeholder.com/300x200?text=No+Image';
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Handle null or empty ads list
      if (widget.ads == null || widget.ads!.isEmpty) {
        return const SizedBox.shrink();
      }

      // Limit to max 10 random ads for performance
      final displayAds = widget.ads!.length > 10
          ? (List<ClassifiedPost>.from(widget.ads!)..shuffle()).take(10).toList()
          : widget.ads!;

      // Create duplicates for infinite scroll effect
      final duplicatedAds = <ClassifiedPost>[];
      final duplicateCount = displayAds.length <= 5 ? 6 : 
                            displayAds.length <= 8 ? 4 : 3;
      for (int i = 0; i < duplicateCount; i++) {
        duplicatedAds.addAll(displayAds);
      }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate card width based on available space
        final availableWidth = constraints.maxWidth;
        double cardWidth;
        
        if (availableWidth < 600) {
          // Mobile: 2 cards visible with gaps
          cardWidth = (availableWidth - 36) * 0.45; // 12px padding on sides + gaps
        } else if (availableWidth < 1024) {
          // Tablet: 3 cards visible
          cardWidth = (availableWidth - 48) * 0.30;
        } else {
          // Desktop: 4-5 cards visible
          cardWidth = (availableWidth - 60) * 0.21;
        }
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
          // Compact Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 8),
                // Title
                Text(
                  widget.sectionTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Scrolling ads carousel
          GestureDetector(
            onPanStart: (_) => _pauseAutoScroll(),
            onPanEnd: (_) => _resumeAutoScroll(),
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: duplicatedAds.length,
                itemBuilder: (context, index) {
                  final ad = duplicatedAds[index];
                  return _buildAdCard(ad, cardWidth);
                },
              ),
            ),
          ),

          const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    } catch (e, stackTrace) {
      print('Error building AdsScrollWidget: $e');
      print('Stack trace: $stackTrace');
      return const SizedBox.shrink();
    }
  }

  Widget _buildAdCard(ClassifiedPost ad, double cardWidth) {
    // Safety check
    if (ad.id.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassifiedPostDetailsScreen(
                postId: ad.id,
                postSlug: ad.slug ?? ad.id,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: _getImageUrl(ad),
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  // Price badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '৳',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              (ad.negotiable ?? false) ? 'Negotiable' : _formatPrice(ad.price ?? 0),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      ad.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Location & Date
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${ad.city ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatDate(ad.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
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
      ),
    );
  }
}
