import 'package:flutter/material.dart';
import 'package:oxius_native/theme/app_text.dart';
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — 6px screen-side inset
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
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
                          style: AppText.sectionTitle(
                            color: const Color(0xFFE91E63),
                          ),
                        ),
                        Text(
                          _translationService.t('food_zone_subtitle',
                              fallback: 'আপনার কাছের মজাদার খাবার'),
                          style: AppText.sectionSubtitle(),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _navigateToFoodZoneScreen,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    color: Colors.transparent,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _translationService.t('see_all', fallback: 'সব দেখুন'),
                          style: AppText.linkText(
                            color: const Color(0xFFE91E63),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: Color(0xFFE91E63),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Posts List — height fits the card's content exactly (image 100 +
          // padded text block); anything taller leaves a dead band above the
          // price row via the card's internal Spacer.
          SizedBox(
              height: 186,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 2),
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
