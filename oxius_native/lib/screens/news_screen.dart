import 'package:flutter/material.dart';
import '../models/news_models.dart';
import '../services/news_service.dart';
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
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isGridLayout = true;
  List<TipSuggestion> _visibleTips = [];

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
      ]);

      final paginatedResponse = results[0] as PaginatedNewsResponse;
      final categories = results[1] as List<NewsCategory>;
      final tips = results[2] as List<TipSuggestion>;

      setState(() {
        _allPosts = paginatedResponse.results;
        _categories = categories;
        _tips = tips;
        _visibleTips = tips.take(6).toList();
        _hasMore = paginatedResponse.hasMore;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
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
        elevation: 0.5,
        title: Image.asset(
          'assets/images/adsy-news-logo.png',
          height: 32,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'AdsyNews',
              style: TextStyle(
                color: Color(0xFFE53E3E),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF1F2937)),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NewsSearchDelegate(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
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
                    margin: const EdgeInsets.symmetric(horizontal: 0),
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
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'All News',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
                                      Icons.grid_view,
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
                                      Icons.view_list,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _isGridLayout
                              ? GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isMobile ? 2 : 4,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
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
                                      padding: const EdgeInsets.only(bottom: 16),
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
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: _loadingMore ? null : _loadMorePosts,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade200,
                                  foregroundColor: const Color(0xFF1F2937),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Text(
                                  _loadingMore ? 'Loading...' : 'Load More Articles',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ),

                        // Trending Topics
                        if (_categories.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _categories.take(7).map((category) {
                                    return InkWell(
                                      onTap: () {
                                        // TODO: Navigate to category
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
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
                                              Icons.trending_up,
                                              size: 16,
                                              color: Color(0xFFE53E3E),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              category.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
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
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isMobile ? 1 : 3,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: isMobile ? 3 : 2,
                                  ),
                                  itemCount: _visibleTips.length,
                                  itemBuilder: (context, index) {
                                    final tip = _visibleTips[index];
                                    return Container(
                                      padding: const EdgeInsets.all(12),
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
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1F2937),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Expanded(
                                            child: Text(
                                              tip.description,
                                              style: TextStyle(
                                                fontSize: 12,
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
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Center(
                                      child: ElevatedButton(
                                        onPressed: _loadMoreTips,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey.shade200,
                                          foregroundColor: const Color(0xFF1F2937),
                                        ),
                                        child: const Text('Load More'),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 40),
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
