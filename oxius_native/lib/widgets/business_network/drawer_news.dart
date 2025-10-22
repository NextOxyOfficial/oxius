import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class DrawerNews extends StatefulWidget {
  const DrawerNews({super.key});

  @override
  State<DrawerNews> createState() => _DrawerNewsState();
}

class _DrawerNewsState extends State<DrawerNews> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _newsItems = [];
  int _currentIndex = 0;
  Timer? _autoPlayTimer;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/news/posts/?limit=5'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _newsItems = (data['results'] as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          });
          _startAutoPlay();
        }
      }
    } catch (e) {
      print('Error loading news: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (_newsItems.isEmpty) return;
    
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final nextIndex = (_currentIndex + 1) % _newsItems.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  void _navigateToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with "See All" button
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.newspaper, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'ADSY NEWS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Navigate to /adsy-news
                },
                icon: const Text(
                  'See All',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
                label: Icon(Icons.chevron_right, size: 14),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        
        // News carousel
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _isLoading
              ? _buildLoadingState()
              : _newsItems.isEmpty
                  ? _buildEmptyState()
                  : _buildNewsCarousel(),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          'No news available',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCarousel() {
    return Column(
      children: [
        // Carousel
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MouseRegion(
              onEnter: (_) => _stopAutoPlay(),
              onExit: (_) => _startAutoPlay(),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemCount: _newsItems.length,
                  itemBuilder: (context, index) {
                    final news = _newsItems[index];
                    return _buildNewsSlide(news);
                  },
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Dot indicators
            Row(
              children: List.generate(_newsItems.length, (index) {
                return Container(
                  width: _currentIndex == index ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? Colors.blue.shade600
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            
            // Navigation buttons
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, size: 16),
                  onPressed: () {
                    final prevIndex = (_currentIndex - 1 + _newsItems.length) % _newsItems.length;
                    _navigateToPage(prevIndex);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                    backgroundColor: Colors.grey.shade100,
                    shape: const CircleBorder(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.chevron_right, size: 16),
                  onPressed: () {
                    final nextIndex = (_currentIndex + 1) % _newsItems.length;
                    _navigateToPage(nextIndex);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                    backgroundColor: Colors.grey.shade100,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNewsSlide(Map<String, dynamic> news) {
    final imageUrl = news['image'] ?? '';
    
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to /adsy-news/${news['slug']}
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image, size: 40, color: Colors.grey),
                    );
                  },
                )
              : Container(
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
          
          // Gradient overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge and date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'News',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.white.withOpacity(0.8)),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(news['created_at']),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Title
                  Text(
                    news['title'] ?? 'Untitled',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
