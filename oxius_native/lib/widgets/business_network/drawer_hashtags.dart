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
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/bn/top-tags/'));
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
    } catch (_) {
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
          child: Row(
            children: [
              Icon(Icons.tag, size: 11, color: Colors.purple.shade500),
              const SizedBox(width: 4),
              Text(
                'TRENDING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),

        // Tags wrap
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _isLoading
              ? Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: List.generate(
                    8,
                    (i) => Container(
                      width: 52 + (i % 3) * 18.0,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                )
              : _tags.isEmpty
                  ? Text(
                      'No trending hashtags',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    )
                  : Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: _tags.map((tag) {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SearchScreen(initialQuery: '#${tag['tag']}'),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(11),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(color: Colors.purple.shade100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '#${tag['tag']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatCount(tag['count'] as int),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
