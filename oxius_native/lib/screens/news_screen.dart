import 'package:flutter/material.dart';
import '../models/news_models.dart';
import '../services/news_service.dart';
import '../services/translation_service.dart';
import '../utils/network_error_handler.dart';
import '../widgets/news/hero_banner.dart';
import '../widgets/news/trending_carousel.dart';
import '../widgets/news/news_card.dart';
import '../widgets/news/news_search_delegate.dart';
import 'news_detail_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TranslationService _translationService = TranslationService();
  List<NewsPost> _allPosts = [];
  List<NewsCategory> _categories = [];
  List<TipSuggestion> _tips = [];
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isGridLayout = false;
  List<TipSuggestion> _visibleTips = [];
  String? _newsLogoUrl;
  NewsCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _translationService.addListener(_onTranslationsChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _translationService.removeListener(_onTranslationsChanged);
    super.dispose();
  }

  void _onTranslationsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  String _t(String key, {required String en, required String bn}) {
    final fallback =
        _translationService.currentLanguage.startsWith('en') ? en : bn;
    return _translationService.t(key, fallback: fallback);
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
        _selectedCategory = null;
        _currentPage = 1;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_loadingMore || !_hasMore || _selectedCategory != null) return;

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

  Future<void> _selectCategory(NewsCategory? category) async {
    Navigator.of(context).maybePop();

    setState(() {
      _selectedCategory = category;
      _loading = true;
      _error = null;
      _currentPage = 1;
      _hasMore = category == null;
    });

    try {
      final posts = category == null
          ? (await NewsService.getPosts(page: 1)).results
          : await NewsService.getPostsByCategory(category.slug);

      if (!mounted) return;
      setState(() {
        _allPosts = posts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
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
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _newsLogoUrl != null && _newsLogoUrl!.isNotEmpty
            ? Image.network(
                _newsLogoUrl!,
                height: 28,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) =>
                    _buildAdsyNewsTextLogo(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _buildAdsyNewsTextLogo();
                },
              )
            : _buildAdsyNewsTextLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded,
                color: Color(0xFF1F2937), size: 22),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NewsSearchDelegate(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded,
                color: Color(0xFF1F2937), size: 22),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      endDrawer: _buildCategoryDrawer(),
      body: _loading
          ? const Center(child: AdsyLoadingIndicator())
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
                        child: Text(_t('news_retry',
                            en: 'Retry', bn: 'আবার চেষ্টা করুন')),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    margin: const EdgeInsets.all(2),
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
                          padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedCategory?.name ??
                                      _t('all_news',
                                          en: 'All News', bn: 'সব সংবাদ'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.1,
                                    color: Color(0xFF1F2937),
                                  ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _isGridLayout
                              ? GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
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
                                      onTap: () =>
                                          _navigateToDetail(_allPosts[index]),
                                    );
                                  },
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _allPosts.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: NewsCard(
                                        post: _allPosts[index],
                                        isListLayout: true,
                                        onTap: () =>
                                            _navigateToDetail(_allPosts[index]),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        // Load More Button
                        if (_hasMore)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 2),
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
                                  _loadingMore
                                      ? _t('loading_news',
                                          en: 'Loading news...',
                                          bn: 'সংবাদ লোড হচ্ছে...')
                                      : _t('read_more_news',
                                          en: 'Read More News',
                                          bn: 'আরও সংবাদ পড়ুন'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                          ),

                        // Tips and Suggestions
                        if (_tips.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 2),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t('tips_and_suggestions',
                                      en: 'Tips and Suggestions',
                                      bn: 'টিপস ও পরামর্শ'),
                                  style: const TextStyle(
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
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
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
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                          backgroundColor:
                                              const Color(0xFFE53E3E),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                            _t('news_load_more',
                                                en: 'Load More',
                                                bn: 'আরও দেখুন'),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
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

  Widget _buildCategoryDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      width: mathMin(MediaQuery.of(context).size.width * 0.82, 340),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _t('news_categories',
                          en: 'News Categories', bn: 'সংবাদ ক্যাটাগরি'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                children: [
                  _buildCategoryDrawerTile(null),
                  ..._categories.map(_buildCategoryDrawerTile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double mathMin(double a, double b) => a < b ? a : b;

  Widget _buildCategoryDrawerTile(NewsCategory? category) {
    final selected = category == null
        ? _selectedCategory == null
        : _selectedCategory?.slug == category.slug;
    final title =
        category?.name ?? _t('all_news', en: 'All News', bn: 'সব সংবাদ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0xFFFFF1F2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _selectCategory(category),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  category == null
                      ? Icons.newspaper_rounded
                      : Icons.label_outline_rounded,
                  size: 19,
                  color: selected
                      ? const Color(0xFFE53E3E)
                      : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? const Color(0xFFE53E3E)
                          : const Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdsyNewsTextLogo() {
    return const Text(
      'AdsyNews',
      style: TextStyle(
        color: Color(0xFFE53E3E),
        fontWeight: FontWeight.w700,
        fontSize: 18,
        letterSpacing: -0.2,
      ),
    );
  }
}
