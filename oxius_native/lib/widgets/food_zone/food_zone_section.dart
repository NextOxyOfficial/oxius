import 'package:flutter/material.dart';
import '../../models/classified_post.dart';
import '../../services/food_zone_service.dart';
import '../../services/translation_service.dart';
import '../../screens/classified_post_details_screen.dart';
import 'food_zone_card.dart';

class FoodZoneSection extends StatefulWidget {
  final String baseUrl;

  const FoodZoneSection({
    super.key,
    required this.baseUrl,
  });

  @override
  State<FoodZoneSection> createState() => _FoodZoneSectionState();
}

class _FoodZoneSectionState extends State<FoodZoneSection> {
  late FoodZoneService _foodZoneService;
  final TranslationService _translationService = TranslationService();
  List<ClassifiedPost> _posts = [];

  @override
  void initState() {
    super.initState();
    _foodZoneService = FoodZoneService(baseUrl: widget.baseUrl);
    _loadData();
  }

  Future<void> _loadData() async {
    
    try {
      final results = await Future.wait([
        _foodZoneService.fetchFoodZonePosts(pageSize: 10),
        _foodZoneService.fetchFoodZoneCategories(),
      ]);
      
      setState(() {
        _posts = results[0] as List<ClassifiedPost>;
      });
    } catch (e) {
      debugPrint('Error loading food zone data: $e');
    }
  }

  void _navigateToPost(ClassifiedPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassifiedPostDetailsScreen(
          postId: post.id,
          postSlug: post.slug ?? post.id,
        ),
      ),
    );
  }

  void _navigateToFoodZoneScreen() {
    Navigator.pushNamed(context, '/food-zone');
  }

  @override
  Widget build(BuildContext context) {
    // Don't show section if loading (no data yet) or empty after load
    if (_posts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Plain icon next to the title (no background box).
                    const Icon(
                      Icons.restaurant_menu,
                      color: Color(0xFFE91E63),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _translationService.t('food_zone',
                              fallback: 'ফুড জোন'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE91E63),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          _translationService.t('food_zone_subtitle',
                              fallback: 'আপনার কাছের মজাদার খাবার'),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _navigateToFoodZoneScreen,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E63),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _translationService.t('see_all', fallback: 'সব দেখুন'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Posts List
          SizedBox(
              height: 195,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return FoodZoneCard(
                    post: post,
                    onTap: () => _navigateToPost(post),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
