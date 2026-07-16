import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../models/business_network_models.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/business_network/post_card.dart';
import '../../widgets/business_network/gold_sponsors_slider.dart';
import 'post_detail_screen.dart';
import 'profile_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/business_network_service.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({
    super.key,
    this.initialQuery,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<BusinessNetworkPost> _posts = [];
  List<Map<String, dynamic>> _people = [];
  List<String> _hashtags = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _currentQuery = '';
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _debounce;
  String _selectedTab = 'all'; // all, people, hashtags, posts

  // Facebook-style start state: recent searches (persisted) + trending tags.
  static const _recentKey = 'bn_recent_searches';
  List<String> _recentSearches = [];
  List<Map<String, dynamic>> _trendingTags = [];
  List<BusinessNetworkPost> _trendingPosts = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadTrendingTags();
    _loadTrendingPosts();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    } else {
      // Auto-focus search input when screen opens
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_recentKey) ?? [];
      if (mounted) setState(() => _recentSearches = saved);
    } catch (_) {}
  }

  Future<void> _saveRecentSearch(String query) async {
    final q = query.trim();
    if (q.length < 2) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_recentKey) ?? [];
      list.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
      list.insert(0, q);
      final trimmed = list.take(10).toList();
      await prefs.setStringList(_recentKey, trimmed);
      if (mounted) setState(() => _recentSearches = trimmed);
    } catch (_) {}
  }

  Future<void> _removeRecentSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_recentKey) ?? [];
      list.removeWhere((e) => e == query);
      await prefs.setStringList(_recentKey, list);
      if (mounted) setState(() => _recentSearches = list);
    } catch (_) {}
  }

  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentKey);
      if (mounted) setState(() => _recentSearches = []);
    } catch (_) {}
  }

  Future<void> _loadTrendingTags() async {
    try {
      final tags = await BusinessNetworkService.getTopTags();
      if (mounted) setState(() => _trendingTags = tags.take(5).toList());
    } catch (_) {}
  }

  Future<void> _loadTrendingPosts() async {
    try {
      final res = await BusinessNetworkService.getPosts(page: 1, pageSize: 5);
      final posts = (res['posts'] as List?)?.cast<BusinessNetworkPost>() ?? [];
      if (mounted) setState(() => _trendingPosts = posts);
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _posts.clear();
        _people.clear();
        _hashtags.clear();
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _currentQuery = query;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performLiveSearch(query);
    });
  }

  Future<void> _performLiveSearch(String query) async {
    if (query.trim().isEmpty) return;

    await Future.wait([
      _loadSearchResults(query, 1),
      _loadPeopleResults(query),
    ]);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    _saveRecentSearch(query);

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _currentQuery = query;
      _currentPage = 1;
      _posts = [];
      _people = [];
    });

    await _performLiveSearch(query);
  }

  Future<void> _loadSearchResults(String query, int page) async {
    try {
      final token = await AuthService.getValidToken();
      final headers = token != null
          ? {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            }
          : {'Content-Type': 'application/json'};

      // Check if it's a hashtag search
      final isHashtagSearch = query.startsWith('#');
      final normalizedQuery = isHashtagSearch ? query.substring(1) : query;

      // Build query parameters
      final params = {
        'q': normalizedQuery,
        'tag': normalizedQuery,
        'page': page.toString(),
        'page_size': '10',
      };

      final uri = Uri.parse('${ApiService.baseUrl}/bn/posts/search/').replace(
        queryParameters: params,
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        debugPrint(
            'Search API returned ${data['results']?.length ?? 0} results for query: $query');

        final List<BusinessNetworkPost> newPosts = [];
        final Set<String> hashtags = {};

        if (data['results'] != null && data['results'] is List) {
          for (var item in data['results']) {
            final post = BusinessNetworkPost.fromJson(item);
            debugPrint(
                'Post: ${post.title} - ${post.content.substring(0, post.content.length > 50 ? 50 : post.content.length)}');
            debugPrint('Author: ${post.user.name} (@${post.user.username})');
            newPosts.add(post);

            // Extract hashtags from posts
            if (post.tags.isNotEmpty) {
              for (var tag in post.tags) {
                hashtags.add(tag.tag);
              }
            }
          }
        }

        setState(() {
          if (page == 1) {
            _posts = newPosts;
            _hashtags = hashtags.toList();
          } else {
            _posts.addAll(newPosts);
          }
          _hasMore = data['next'] != null;
          _currentPage = page;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error searching: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPeopleResults(String query) async {
    try {
      final token = await AuthService.getValidToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Add authorization header only if user is logged in
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final normalizedQuery =
          query.startsWith('#') ? query.substring(1) : query;

      final params = {
        'q': normalizedQuery,
        'page_size': '5',
      };

      final uri = Uri.parse('${ApiService.baseUrl}/bn/users/search/').replace(
        queryParameters: params,
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final List<Map<String, dynamic>> people = [];

        if (data['results'] != null && data['results'] is List) {
          for (var item in data['results']) {
            people.add(Map<String, dynamic>.from(item));
          }
        }

        setState(() {
          _people = people;
        });
      }
    } catch (e) {
      debugPrint('Error searching people: $e');
    }
  }

  void _loadMore() {
    if (!_isLoading && _hasMore) {
      _loadSearchResults(_currentQuery, _currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        toolbarHeight: 56,
        titleSpacing: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF0F172A), size: 22),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
        ),
        title: Container(
          height: 38,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12, right: 6),
                child: Icon(
                  Icons.search,
                  size: 18,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'Search people, posts, hashtags...',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: _performSearch,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF212121),
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchController.clear();
                      _posts.clear();
                      _people.clear();
                      _hashtags.clear();
                      _hasSearched = false;
                      _currentQuery = '';
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(Icons.cancel,
                        size: 16, color: Colors.grey.shade400),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (!_hasSearched) {
      return _buildInitialState();
    }

    if (_isLoading && _posts.isEmpty && _people.isEmpty) {
      return const Center(child: AdsyLoadingIndicator());
    }

    if (_posts.isEmpty && _people.isEmpty && _hashtags.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Compact Results summary
        if (_hasSearched &&
            (_posts.isNotEmpty || _people.isNotEmpty || _hashtags.isNotEmpty))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            alignment: Alignment.centerLeft,
            child: Text(
              'Results for "$_currentQuery"',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),

        // Compact Tab Bar
        if (_hasSearched &&
            (_posts.isNotEmpty || _people.isNotEmpty || _hashtags.isNotEmpty))
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _buildTab('All', 'all',
                      _people.length + _posts.length + _hashtags.length),
                  const SizedBox(width: 6),
                  _buildTab('People', 'people', _people.length),
                  const SizedBox(width: 6),
                  _buildTab('Hashtags', 'hashtags', _hashtags.length),
                  const SizedBox(width: 6),
                  _buildTab('Posts', 'posts', _posts.length),
                ],
              ),
            ),
          ),

        // Results based on selected tab
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
  }

  Widget _buildTab(String label, String value, int count) {
    final isSelected = _selectedTab == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF475569),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color:
                        isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTab == 'people') {
      return _people.isEmpty
          ? _buildEmptyTabState('No people found')
          : ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _people.length,
              itemBuilder: (context, index) => _buildPersonItem(_people[index]),
            );
    } else if (_selectedTab == 'hashtags') {
      return _hashtags.isEmpty
          ? _buildEmptyTabState('No hashtags found')
          : ListView(
              padding: EdgeInsets.zero,
              children: [_buildHashtagsGrid()],
            );
    } else if (_selectedTab == 'posts') {
      return _posts.isEmpty
          ? _buildEmptyTabState('No posts found')
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _posts.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _posts.length) {
                  return _buildLoadMoreButton();
                }
                return PostCard(
                  key: ValueKey('post_${_posts[index].id}'),
                  post: _posts[index],
                  onPostUpdated: (updatedPost) {
                    setState(() {
                      _posts[index] = updatedPost;
                    });
                  },
                  onCommentAdded: (comment) {},
                  onPostDeleted: () {
                    setState(() {
                      _posts.removeAt(index);
                    });
                  },
                );
              },
            );
    } else {
      // All tab - show everything
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: GoldSponsorsSlider(),
          ),
          if (_people.isNotEmpty) ...[
            _buildSectionHeader('People', _people.length),
            ..._people.map((person) => _buildPersonItem(person)),
            const Divider(height: 1, thickness: 8, color: Color(0xFFF5F5F5)),
          ],
          if (_hashtags.isNotEmpty) ...[
            _buildSectionHeader('Hashtags', _hashtags.length),
            _buildHashtagsGrid(),
            const Divider(height: 1, thickness: 8, color: Color(0xFFF5F5F5)),
          ],
          if (_posts.isNotEmpty) ...[
            _buildSectionHeader('Posts', _posts.length),
            ..._posts.asMap().entries.map((entry) {
              final index = entry.key;
              final post = entry.value;
              return PostCard(
                key: ValueKey('post_${post.id}'),
                post: post,
                onPostUpdated: (updatedPost) {
                  setState(() {
                    _posts[index] = updatedPost;
                  });
                },
                onCommentAdded: (comment) {},
                onPostDeleted: () {
                  setState(() {
                    _posts.remove(post);
                  });
                },
              );
            }),
            if (_hasMore) _buildLoadMoreButton(),
          ],
        ],
      );
    }
  }

  Widget _buildEmptyTabState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPersonFullName(Map<String, dynamic> person) {
    final firstName = person['first_name'] ?? '';
    final lastName = person['last_name'] ?? '';

    // Combine first and last name
    final fullName = '$firstName $lastName'.trim();

    // If no name, use username or 'Unknown'
    if (fullName.isEmpty) {
      return person['username'] ?? 'Unknown';
    }

    return fullName;
  }

  Widget _buildSectionHeader(String title, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonItem(Map<String, dynamic> person) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProfileScreen(userId: person['id'].toString()),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Compact Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                ),
                child: ClipOval(
                  child: person['image'] != null
                      ? Image.network(
                          person['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person,
                                color: Colors.grey.shade400, size: 20);
                          },
                        )
                      : Icon(Icons.person,
                          color: Colors.grey.shade400, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _getPersonFullName(person),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF212121),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (person['kyc'] == true) ...[
                          const SizedBox(width: 3),
                          Icon(Icons.verified,
                              size: 14, color: Colors.blue.shade600),
                        ],
                      ],
                    ),
                    if (person['profession'] != null &&
                        person['profession'].toString().isNotEmpty)
                      Text(
                        person['profession'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Arrow
              Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHashtagsGrid() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _hashtags.map((hashtag) {
          return GestureDetector(
            onTap: () {
              _searchController.text = '#$hashtag';
              _performSearch('#$hashtag');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tag, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 3),
                  Text(
                    hashtag,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Facebook-style start state: recent searches + trending hashtags, so the
  // page is useful before a single letter is typed.
  Widget _buildInitialState() {
    // Plain single-page layout: rows sit directly on the page background with
    // section headers and hairline dividers between them (no per-section cards).
    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 24),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'RECENT SEARCHES',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _clearRecentSearches,
                  child: const Text(
                    'Clear all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < _recentSearches.length; i++)
            _recentRow(_recentSearches[i],
                isLast: i == _recentSearches.length - 1),
          const SizedBox(height: 20),
        ],
        if (_trendingPosts.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Text(
              'TRENDING POSTS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
          ),
          for (var i = 0; i < _trendingPosts.length; i++)
            _trendingPostRow(_trendingPosts[i],
                isLast: i == _trendingPosts.length - 1),
          const SizedBox(height: 20),
        ],
        if (_trendingTags.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Text(
              'TRENDING HASHTAGS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
          ),
          for (var i = 0; i < _trendingTags.length; i++)
            _trendingTagRow(_trendingTags[i],
                isLast: i == _trendingTags.length - 1),
          const SizedBox(height: 20),
        ],
        // Quiet hint at the end (plain, no card).
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 4, 14, 4),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates_outlined,
                  size: 18, color: Color(0xFF94A3B8)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search people by name, posts by keyword, or use # to find hashtags.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _trendingPostRow(BusinessNetworkPost post, {required bool isLast}) {
    final author = post.user.name;
    final rawAvatar = post.user.image ?? post.user.avatar;
    final avatar = ApiService.getAbsoluteUrl(rawAvatar);
    var snippet = post.title.trim();
    if (snippet.isEmpty) {
      snippet = post.content
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
    if (snippet.isEmpty) snippet = 'Photo/video post';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9)),
                ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFF1F5F9),
              backgroundImage:
                  avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty
                  ? Text(
                      author.isNotEmpty ? author[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    snippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _postCountsRow(post),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  // Compact like / comment / share counts (a count is hidden when 0).
  Widget _postCountsRow(BusinessNetworkPost post) {
    final metrics = <Widget>[];
    void addMetric(IconData icon, int count) {
      if (count <= 0) return;
      if (metrics.isNotEmpty) metrics.add(const SizedBox(width: 10));
      metrics.addAll([
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ]);
    }

    addMetric(Icons.favorite_border_rounded, post.likesCount);
    addMetric(Icons.chat_bubble_outline_rounded, post.commentsCount);
    addMetric(Icons.share_outlined, post.shareCount);

    if (metrics.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: metrics);
  }

  Widget _trendingTagRow(Map<String, dynamic> t, {required bool isLast}) {
    final tag = (t['tag'] ?? '').toString();
    final count = t['count'];
    return InkWell(
      onTap: () {
        _searchController.text = '#$tag';
        _performSearch('#$tag');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9)),
                ),
        ),
        child: Row(
          children: [
            const Icon(Icons.tag_rounded,
                size: 17, color: Color(0xFF2563EB)),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            if (count != null)
              Text(
                '$count posts',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _recentRow(String query, {required bool isLast}) {
    return InkWell(
      onTap: () {
        _searchController.text = query;
        _performSearch(query);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9)),
                ),
        ),
        child: Row(
          children: [
            const Icon(Icons.history_rounded,
                size: 18, color: Color(0xFF94A3B8)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _removeRecentSearch(query),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded,
                    size: 16, color: Color(0xFFCBD5E1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isHashtagSearch = _currentQuery.startsWith('#');

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHashtagSearch ? Icons.tag_rounded : Icons.search_off_rounded,
              size: 36,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              isHashtagSearch
                  ? 'No results for this hashtag'
                  : 'No results found',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nothing matched "$_currentQuery". Try a different keyword or check the spelling.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoading
            ? const AdsyLoadingIndicator()
            : TextButton(
                onPressed: _loadMore,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                ),
                child: const Text(
                  'Load more',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
      ),
    );
  }
}
