import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../models/business_network_models.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/business_network/post_card.dart';
import '../../widgets/business_network/gold_sponsors_slider.dart';
import 'profile_screen.dart';
import 'post_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
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
      final token = await AuthService.getToken();
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
        print('Search API returned ${data['results']?.length ?? 0} results for query: $query');
        
        final List<BusinessNetworkPost> newPosts = [];
        final Set<String> hashtags = {};

        if (data['results'] != null && data['results'] is List) {
          for (var item in data['results']) {
            final post = BusinessNetworkPost.fromJson(item);
            print('Post: ${post.title} - ${post.content.substring(0, post.content.length > 50 ? 50 : post.content.length)}');
            print('Author: ${post.user.name} (@${post.user.username})');
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
      print('Error searching: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPeopleResults(String query) async {
    try {
      final token = await AuthService.getToken();
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // Add authorization header only if user is logged in
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final normalizedQuery = query.startsWith('#') ? query.substring(1) : query;

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
      print('Error searching people: $e');
    }
  }

  void _loadMore() {
    if (!_isLoading && _hasMore) {
      _loadSearchResults(_currentQuery, _currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isHashtagSearch = _currentQuery.startsWith('#');

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  Icons.search,
                  size: 20,
                  color: Color(0xFF757575),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.cancel, size: 18, color: Colors.grey.shade500),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _posts.clear();
                                _people.clear();
                                _hashtags.clear();
                                _hasSearched = false;
                                _currentQuery = '';
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : null,
                  ),
                  onSubmitted: _performSearch,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF212121),
                  ),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty && _people.isEmpty && _hashtags.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Results summary
        if (_hasSearched && (_posts.isNotEmpty || _people.isNotEmpty || _hashtags.isNotEmpty))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              'Results for "$_currentQuery"',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF616161),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        
        // Tab Bar
        if (_hasSearched && (_posts.isNotEmpty || _people.isNotEmpty || _hashtags.isNotEmpty))
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildTab('All', 'all', _people.length + _posts.length + _hashtags.length),
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
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = value;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1976D2) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF424242),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF757575),
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
                  post: _posts[index],
                  onLikeToggle: () {},
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
          // Gold Sponsors Slider
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
            ..._posts.map((post) => PostCard(
              post: post,
              onLikeToggle: () {},
              onCommentAdded: (comment) {},
              onPostDeleted: () {
                setState(() {
                  _posts.remove(post);
                });
              },
            )),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF757575),
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
              builder: (context) => ProfileScreen(userId: person['id'].toString()),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                ),
                child: ClipOval(
                  child: person['image'] != null
                      ? Image.network(
                          person['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person, color: Colors.grey.shade400, size: 24);
                          },
                        )
                      : Icon(Icons.person, color: Colors.grey.shade400, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: person['profession'] != null && person['profession'].toString().isNotEmpty
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _getPersonFullName(person),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF212121),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (person['kyc'] == true) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified, size: 16, color: Colors.blue.shade600),
                        ],
                      ],
                    ),
                    if (person['profession'] != null && person['profession'].toString().isNotEmpty)
                      Text(
                        person['profession'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Arrow
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHashtagsGrid() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _hashtags.map((hashtag) {
          return InkWell(
            onTap: () {
              _searchController.text = '#$hashtag';
              _performSearch('#$hashtag');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tag, size: 14, color: Colors.grey.shade700),
                  const SizedBox(width: 4),
                  Text(
                    hashtag,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
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

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search,
                size: 40,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Search Business Network',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find posts, people, and hashtags',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Tip: Use # to search hashtags',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
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
    final isHashtagSearch = _currentQuery.startsWith('#');
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Icon(
                isHashtagSearch ? Icons.tag : Icons.search,
                size: 32,
                color: Colors.blue.shade500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isHashtagSearch ? 'No Results for this Hashtag' : 'No Results Found',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isHashtagSearch
                  ? 'We couldn\'t find any posts using the hashtag "$_currentQuery"'
                  : 'We couldn\'t find any matches for "$_currentQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Feed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
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
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _loadMore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade500,
                  side: BorderSide(color: Colors.blue.shade200),
                ),
                child: const Text('Load more'),
              ),
      ),
    );
  }
}
