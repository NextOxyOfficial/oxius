import 'package:flutter/material.dart';
import '../models/news_models.dart';
import '../services/news_service.dart';
import '../utils/network_error_handler.dart';
import '../widgets/news/hero_banner.dart';
import '../widgets/news/trending_carousel.dart';
import '../widgets/news/news_card.dart';
import '../widgets/news/news_search_delegate.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsPost> _allPosts = [];
  List<NewsCategory> _categories = [];
  List<TipSuggestion> _tips = [];
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isGridLayout = true;
  List<TipSuggestion> _visibleTips = [];
  String? _newsLogoUrl;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        NewsService.getPosts(page: 1),
        NewsService.getCategories(),
        NewsService.getTipsAndSuggestions(),
        NewsService.getNewsLogo(),
      ]);

      final paginatedResponse = results[0] as PaginatedNewsResponse;
      final categories = results[1] as List<NewsCategory>;
      final tips = results[2] as List<TipSuggestion>;
      final logoUrl = results[3] as String?;

      setState(() {
        _allPosts = paginatedResponse.results;
        _categories = categories;
        _tips = tips;
        _visibleTips = tips.take(6).toList();
        _hasMore = paginatedResponse.hasMore;
        _newsLogoUrl = logoUrl;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_loadingMore || !_hasMore) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      _currentPage++;
      final response = await NewsService.getPosts(page: _currentPage);

      setState(() {
        _allPosts.addAll(response.results);
        _hasMore = response.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _loadingMore = false;
        _currentPage--;
      });
    }
  }

  void _loadMoreTips() {
    setState(() {
      final nextTips = _tips.skip(_visibleTips.length).take(6).toList();
      _visibleTips.addAll(nextTips);
    });
  }

  void _navigateToDetail(NewsPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(slug: post.slug),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _newsLogoUrl != null
            ? Image.network(
                _newsLogoUrl!,
                height: 28,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/adsy-news-logo.png',
                    height: 28,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'AdsyNews',
                        style: TextStyle(
                          color: Color(0xFFE53E3E),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: -0.2,
                        ),
                      );
                    },
                  );
                },
              )
            : Image.asset(
                'assets/images/adsy-news-logo.png',
                height: 28,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'AdsyNews',
                    style: TextStyle(
                      color: Color(0xFFE53E3E),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: -0.2,
                    ),
                  );
                },
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF1F2937), size: 22),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NewsSearchDelegate(),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        NetworkErrorHandler.getErrorIcon(_error),
                        size: 44,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          NetworkErrorHandler.getErrorMessage(_error),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInitialData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    margin: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Banner
                        if (_allPosts.isNotEmpty)
                          HeroBanner(
                            article: _allPosts.first,
                            onTap: () => _navigateToDetail(_allPosts.first),
                          ),

                        // Trending Carousel
                        if (_allPosts.length > 1)
                          TrendingCarousel(
                            articles: _getTrendingArticles(),
                            onArticleTap: _navigateToDetail,
                          ),

                        // All News Section Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'All News',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isGridLayout = true;
                                      });
                                    },
                                    icon: Icon(
                                      Icons.grid_view_rounded,
                                      size: 20,
                                      color: _isGridLayout
                                          ? const Color(0xFFE53E3E)
                                          : Colors.grey,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isGridLayout = false;
                                      });
                                    },
                                    icon: Icon(
                                      Icons.view_list_rounded,
                                      size: 20,
                                      color: !_isGridLayout
                                          ? const Color(0xFFE53E3E)
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // News Grid/List
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _isGridLayout
                              ? GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isMobile ? 2 : 4,
                                    crossAxisSpacing: 6,
                                    mainAxisSpacing: 6,
                                    childAspectRatio: 0.75,
                                  ),
                                  itemCount: _allPosts.length,
                                  itemBuilder: (context, index) {
                                    return NewsCard(
                                      post: _allPosts[index],
                                      isListLayout: false,
                                      onTap: () => _navigateToDetail(_allPosts[index]),
                                    );
                                  },
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _allPosts.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: NewsCard(
                                        post: _allPosts[index],
                                        isListLayout: true,
                                        onTap: () => _navigateToDetail(_allPosts[index]),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        // Load More Button
                        if (_hasMore)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: _loadingMore ? null : _loadMorePosts,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53E3E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _loadingMore ? 'Loading...' : 'Load More Articles',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ),
                          ),

                        // Trending Topics
                        if (_categories.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Trending Topics',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.1,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _categories.take(7).map((category) {
                                    return InkWell(
                                      onTap: () {
                                        // TODO: Navigate to category
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.trending_up_rounded,
                                              size: 14,
                                              color: Color(0xFFE53E3E),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              category.name,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                        // Tips and Suggestions
                        if (_tips.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tips and Suggestions',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.1,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isMobile ? 1 : 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: isMobile ? 3 : 2,
                                  ),
                                  itemCount: _visibleTips.length,
                                  itemBuilder: (context, index) {
                                    final tip = _visibleTips[index];
                                    return Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tip.title,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.1,
                                              color: Color(0xFF1F2937),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Expanded(
                                            child: Text(
                                              tip.description,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                if (_visibleTips.length < _tips.length)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Center(
                                      child: ElevatedButton(
                                        onPressed: _loadMoreTips,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFE53E3E),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Load More', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  List<NewsPost> _getTrendingArticles() {
    final sorted = List<NewsPost>.from(_allPosts);
    sorted.sort((a, b) => b.comments.length.compareTo(a.comments.length));
    return sorted.take(8).toList();
  }
}
