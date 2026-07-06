import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';
import '../../screens/business_network/profile_screen.dart';

class DrawerContributors extends StatefulWidget {
  const DrawerContributors({super.key});

  @override
  State<DrawerContributors> createState() => _DrawerContributorsState();
}

class _DrawerContributorsState extends State<DrawerContributors> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _contributors = [];

  @override
  void initState() {
    super.initState();
    _loadContributors();
  }

  Future<void> _loadContributors() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/bn/top-contributors/?limit=5'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            _contributors = List<Map<String, dynamic>>.from(
              data.take(5).map((item) => Map<String, dynamic>.from(item)),
            );
          });
        }
      }
    } catch (_) {
      // ignore
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
              Icon(Icons.people_alt_rounded, size: 11, color: Colors.green.shade600),
              const SizedBox(width: 4),
              Text(
                'TOP CONTRIBUTORS',
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

        // List
        if (_isLoading)
          Column(
            children: List.generate(
              3,
              (i) => Container(
                margin: const EdgeInsets.only(bottom: 5),
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          )
        else if (_contributors.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'No contributors yet',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          )
        else
          Column(
            children: _contributors.asMap().entries.map((entry) {
              final index = entry.key;
              final contributor = entry.value;
              final name = contributor['name'] ?? contributor['username'] ?? 'User';
              final postCount = contributor['post_count'] ?? 0;
              final isVerified = contributor['is_verified'] == true;
              final avatarUrl = contributor['avatar'] ?? contributor['image'];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final userId = contributor['uuid'] ?? contributor['id']?.toString();
                    if (userId != null) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        // Rank badge
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _rankColor(index),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),

                        // Avatar
                        ClipOval(
                          child: avatarUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 128,
                                  errorWidget: (_, __, ___) => _avatarPlaceholder(),
                                )
                              : _avatarPlaceholder(),
                        ),
                        const SizedBox(width: 7),

                        // Name + posts
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isVerified) ...[
                                    const SizedBox(width: 3),
                                    const Icon(Icons.verified, size: 11, color: Color(0xFF3B82F6)),
                                  ],
                                ],
                              ),
                              Text(
                                '$postCount posts',
                                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),

                        // Trophy for top 3
                        if (index < 3)
                          Icon(Icons.emoji_events, size: 14, color: _trophyColor(index)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      width: 24,
      height: 24,
      color: Colors.grey.shade200,
      child: Icon(Icons.person, size: 14, color: Colors.grey.shade400),
    );
  }

  Color _rankColor(int index) {
    switch (index) {
      case 0: return const Color(0xFFFFB800);
      case 1: return const Color(0xFF94A3B8);
      case 2: return const Color(0xFFCD7F32);
      default: return Colors.grey.shade400;
    }
  }

  Color _trophyColor(int index) {
    switch (index) {
      case 0: return const Color(0xFFFFB800);
      case 1: return const Color(0xFF94A3B8);
      case 2: return const Color(0xFFCD7F32);
      default: return Colors.grey;
    }
  }
}
