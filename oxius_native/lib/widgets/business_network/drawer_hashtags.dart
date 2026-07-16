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
        const Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Text(
            'TRENDING',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.6,
            ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '#${tag['tag']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatCount(tag['count'] as int),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF94A3B8),
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
