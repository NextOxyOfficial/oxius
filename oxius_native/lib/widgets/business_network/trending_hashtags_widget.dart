import 'package:flutter/material.dart';
import '../../services/business_network_service.dart';

class TrendingHashtagsWidget extends StatefulWidget {
  final Function(String)? onHashtagTap;
  
  const TrendingHashtagsWidget({
    super.key,
    this.onHashtagTap,
  });

  @override
  State<TrendingHashtagsWidget> createState() => _TrendingHashtagsWidgetState();
}

class _TrendingHashtagsWidgetState extends State<TrendingHashtagsWidget> {
  List<Map<String, dynamic>> _hashtags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHashtags();
  }

  Future<void> _loadHashtags() async {
    try {
      final hashtags = await BusinessNetworkService.getTrendingTags(limit: 7);
      if (mounted) {
        setState(() {
          _hashtags = hashtags;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading trending hashtags: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAllHashtags() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AllHashtagsBottomSheet(
        onHashtagTap: widget.onHashtagTap,
      ),
    );
  }

  double _getPercentage(Map<String, dynamic> tag) {
    if (_hashtags.isEmpty) return 0;
    
    final maxCount = _hashtags.map((t) => t['count'] as int? ?? 0).reduce((a, b) => a > b ? a : b);
    if (maxCount <= 0) return 0;
    
    return ((tag['count'] as int? ?? 0) / maxCount * 100).clamp(10.0, 100.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tag_rounded,
                      size: 16,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TRENDING HASHTAGS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _showAllHashtags,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          'Top 100',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Colors.blue.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  ),
                ),
              ),
            )
          else if (_hashtags.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No trending hashtags available.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: _hashtags.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade100,
              ),
              itemBuilder: (context, index) {
                final tag = _hashtags[index];
                return InkWell(
                  onTap: () {
                    if (widget.onHashtagTap != null) {
                      widget.onHashtagTap!(tag['tag'] as String);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.tag_rounded,
                                size: 14,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '#${tag['tag']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${tag['count'] ?? 0}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Progress bar
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _getPercentage(tag) / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AllHashtagsBottomSheet extends StatefulWidget {
  final Function(String)? onHashtagTap;
  
  const _AllHashtagsBottomSheet({this.onHashtagTap});

  @override
  State<_AllHashtagsBottomSheet> createState() => _AllHashtagsBottomSheetState();
}

class _AllHashtagsBottomSheetState extends State<_AllHashtagsBottomSheet> {
  List<Map<String, dynamic>> _allHashtags = [];
  List<Map<String, dynamic>> _filteredHashtags = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllHashtags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllHashtags() async {
    try {
      final hashtags = await BusinessNetworkService.getTopTags();
      if (mounted) {
        setState(() {
          _allHashtags = hashtags;
          _filteredHashtags = hashtags;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading all hashtags: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterHashtags(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredHashtags = _allHashtags;
      } else {
        _filteredHashtags = _allHashtags
            .where((tag) => (tag['tag'] as String)
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Color _getRankBadgeColor(int index) {
    if (index == 0) return const Color(0xFFFBBF24); // Gold
    if (index == 1) return const Color(0xFF9CA3AF); // Silver
    if (index == 2) return const Color(0xFFF59E0B); // Bronze
    return const Color(0xFF3B82F6); // Blue
  }

  Color _getBarColor(int index) {
    if (index == 0) return const Color(0xFFFBBF24);
    if (index == 1) return const Color(0xFF9CA3AF);
    if (index == 2) return const Color(0xFFF59E0B);
    if (index < 10) return const Color(0xFF3B82F6);
    return const Color(0xFF6366F1);
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = _allHashtags.isNotEmpty
        ? _allHashtags.map((t) => t['count'] as int? ?? 0).reduce((a, b) => a > b ? a : b)
        : 1;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.indigo.shade600],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tag_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Top 100 Trending Hashtags',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _filterHashtags,
              decoration: InputDecoration(
                hintText: 'Search hashtags...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600, size: 20),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                    ),
                  )
                : _filteredHashtags.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No hashtags available'
                                  : 'No hashtags found matching "$_searchQuery"',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        itemCount: _filteredHashtags.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade100,
                        ),
                        itemBuilder: (context, index) {
                          final tag = _filteredHashtags[index];
                          final count = tag['count'] as int? ?? 0;
                          final percentage = (count / maxCount * 100).clamp(0.0, 100.0);

                          return InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              if (widget.onHashtagTap != null) {
                                widget.onHashtagTap!(tag['tag'] as String);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Row(
                                children: [
                                  // Rank badge
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _getRankBadgeColor(index).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _getRankBadgeColor(index),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Hashtag info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '#${tag['tag']}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1F2937),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              '$count ${count == 1 ? "post" : "posts"}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // Progress bar
                                        Container(
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: percentage / 100,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: _getBarColor(index),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
