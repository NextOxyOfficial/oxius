import 'package:flutter/material.dart';
import '../../models/classified_post.dart';
import '../../services/food_zone_service.dart';
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
  List<ClassifiedPost> _posts = [];
  List<FoodZoneCategory> _categories = [];
  bool _isLoading = true;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _foodZoneService = FoodZoneService(baseUrl: widget.baseUrl);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _foodZoneService.fetchFoodZonePosts(pageSize: 10),
        _foodZoneService.fetchFoodZoneCategories(),
      ]);
      
      setState(() {
        _posts = results[0] as List<ClassifiedPost>;
        _categories = results[1] as List<FoodZoneCategory>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading food zone data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPostsByCategory(String? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _isLoading = true;
    });
    
    try {
      final posts = await _foodZoneService.fetchFoodZonePosts(
        pageSize: 10,
        categoryId: categoryId,
      );
      
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading food zone posts: $e');
      setState(() => _isLoading = false);
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
    // Don't show section if no posts
    if (!_isLoading && _posts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFCE4EC),
            const Color(0xFFFCE4EC).withOpacity(0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE91E63).withOpacity(0.2),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFFD81B60)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE91E63).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Food Zone',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE91E63),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Delicious food near you',
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
                          color: const Color(0xFFE91E63).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
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
          if (_isLoading)
            const SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE91E63),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_posts.isEmpty)
            SizedBox(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No food items available',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
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
