import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';
import '../../screens/business_network/search_screen.dart';

class DrawerHashtags extends StatefulWidget {
  const DrawerHashtags({super.key});

  @override
  State<DrawerHashtags> createState() => _DrawerHashtagsState();
}

class _DrawerHashtagsState extends State<DrawerHashtags> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadHashtags();
  }

  Future<void> _loadHashtags() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/bn/top-tags/'),
      );
      
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            final mapped = List<Map<String, dynamic>>.from(
              data.map((item) => {
                'id': item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                'tag': item['tag'] ?? '',
                'count': item['count'] ?? 0,
              }),
            );

            mapped.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
            _tags = mapped.take(12).toList();
          });
        }
      }
    } catch (e) {
      print('Error loading hashtags: $e');
      // Set default tags on error
      if (mounted) {
        setState(() {
          _tags = [
            {'id': '1', 'tag': 'adsy', 'count': 120},
            {'id': '2', 'tag': 'business', 'count': 85},
            {'id': '3', 'tag': 'network', 'count': 74},
            {'id': '4', 'tag': 'tech', 'count': 63},
            {'id': '5', 'tag': 'startup', 'count': 57},
          ];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.tag,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Trending Hashtags',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Hashtags
        if (_isLoading)
          _buildLoadingTags()
        else if (_tags.isEmpty)
          _buildEmptyState()
        else
          _buildHashtagsWrap(),
      ],
    );
  }

  Widget _buildLoadingTags() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(
        10,
        (index) => Container(
          width: 60 + (index % 3) * 20.0,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          'No trending hashtags',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildHashtagsWrap() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _tags.map((tag) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    initialQuery: '#${tag['tag']}',
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.purple.shade100,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#${tag['tag']}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatCount(tag['count'] as int),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
