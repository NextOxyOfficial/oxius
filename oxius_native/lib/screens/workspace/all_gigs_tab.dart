import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/workspace_service.dart';
import '../../services/api_service.dart';
import '../../services/translation_service.dart';
import 'gig_detail_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class AllGigsTab extends StatefulWidget {
  const AllGigsTab({super.key});

  @override
  State<AllGigsTab> createState() => _AllGigsTabState();
}

class _AllGigsTabState extends State<AllGigsTab> {
  final WorkspaceService _workspaceService = WorkspaceService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) =>
      _i18n.translate(key, fallback: fallback);

  List<Map<String, dynamic>> _gigs = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _selectedCategory;
  String _searchQuery = '';
  final String _ordering = '-created_at';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadGigs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreGigs();
    }
  }

  Future<void> _loadCategories() async {
    final categories = await _workspaceService.fetchCategories();
    if (mounted) {
      setState(() => _categories = categories);
    }
  }

  Future<void> _loadGigs({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _isLoading = true;
      });
    }

    try {
      final result = await _workspaceService.fetchGigs(
        category: _selectedCategory,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        ordering: _ordering,
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          if (refresh || _currentPage == 1) {
            _gigs = result['results'];
          } else {
            _gigs.addAll(result['results']);
          }
          _hasMore = result['next'] != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreGigs() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    try {
      final result = await _workspaceService.fetchGigs(
        category: _selectedCategory,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        ordering: _ordering,
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          _gigs.addAll(result['results']);
          _hasMore = result['next'] != null;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  String _getImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiService.baseUrl.replaceAll('/api', '')}$url';
  }

  @override
  Widget build(BuildContext context) {
    return AdsyRefreshIndicator(
      onRefresh: () => _loadGigs(refresh: true),
      child: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: _t('workspace_search_gigs', 'গিগ খুঁজুন...'),
                      hintStyle:
                          TextStyle(fontSize: 15, color: Colors.grey[400]),
                      prefixIcon:
                          Icon(Icons.search, color: Colors.grey[400], size: 18),
                      prefixIconConstraints: const BoxConstraints(minWidth: 36),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _loadGigs(refresh: true);
                              },
                              child: Icon(Icons.clear,
                                  size: 16, color: Colors.grey[400]),
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(minWidth: 32),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                    ),
                    onSubmitted: (value) {
                      setState(() => _searchQuery = value);
                      _loadGigs(refresh: true);
                    },
                  ),
                ),
                const SizedBox(height: 6),
                // Category Filter
                SizedBox(
                  height: 28,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip(_t('workspace_all', 'সব'), null),
                      ..._categories.map((cat) => _buildFilterChip(
                            cat['label'] ?? cat['name'] ?? '',
                            cat['value']?.toString() ?? cat['id']?.toString(),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Gigs Grid
          Expanded(
            child: _isLoading
                ? const Center(child: AdsyLoadingIndicator())
                : _gigs.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
                        itemCount: _gigs.length + (_isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index >= _gigs.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: AdsyLoadingIndicator(),
                              ),
                            );
                          }
                          return _buildGigCard(_gigs[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? categoryId) {
    final isSelected = _selectedCategory == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedCategory = isSelected ? null : categoryId);
          _loadGigs(refresh: true);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGigCard(Map<String, dynamic> gig) {
    final user = gig['user'] as Map<String, dynamic>?;
    final rating = (gig['rating'] ?? 0).toDouble();
    final price = gig['price']?.toString() ?? '0';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GigDetailScreen(gigId: gig['id'].toString()),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDF0F5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: SizedBox(
                width: 112,
                height: 88,
                child: CachedNetworkImage(
                  imageUrl: _getImageUrl(gig['image_url'] ?? gig['image']),
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child:
                        const Icon(Icons.image, color: Colors.grey, size: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gig['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  // Seller row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: const Color(0xFFEDE9FE),
                        backgroundImage: user?['avatar'] != null
                            ? CachedNetworkImageProvider(
                                _getImageUrl(user!['avatar']))
                            : null,
                        child: user?['avatar'] == null
                            ? Text(
                                (user?['name'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF7C3AED),
                                    fontWeight: FontWeight.w700),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          user?['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user?['kyc'] == true)
                        const Padding(
                          padding: EdgeInsets.only(left: 3),
                          child:
                              Icon(Icons.verified, size: 13, color: Colors.blue),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Rating + Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 15, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '৳$price',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8B5CF6),
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
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _t('workspace_no_gigs_found', 'কোনো গিগ পাওয়া যায়নি'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t('workspace_adjust_filters', 'ফিল্টার বা সার্চ একটু বদলে দেখুন'),
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
