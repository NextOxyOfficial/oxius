import 'package:flutter/material.dart';
import 'package:oxius_native/utils/image_utils.dart';
import 'package:oxius_native/utils/app_fonts.dart';
import '../services/eshop_service.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class HotDealsSection extends StatefulWidget {
  final Function(String)? onCategorySelected;

  const HotDealsSection({
    super.key,
    this.onCategorySelected,
  });

  @override
  State<HotDealsSection> createState() => _HotDealsSectionState();
}

class _HotDealsSectionState extends State<HotDealsSection> {
  List<Map<String, dynamic>> _specialDeals = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchSpecialDeals();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSpecialDeals() async {
    try {
      setState(() => _isLoading = true);

      // Fetch categories with special_offer filter
      final response =
          await EshopService.fetchProductCategories(specialOffer: true);

      if (mounted) {
        setState(() {
          _specialDeals = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching special deals: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getBadgeColor(String? badgeColor) {
    if (badgeColor == null) return Colors.red.shade500;

    // Parse Tailwind-like color classes
    if (badgeColor.contains('red')) return Colors.red.shade500;
    if (badgeColor.contains('orange')) return Colors.orange.shade500;
    if (badgeColor.contains('amber')) return Colors.amber.shade600;
    if (badgeColor.contains('yellow')) return Colors.yellow.shade600;
    if (badgeColor.contains('lime')) return Colors.lime.shade600;
    if (badgeColor.contains('green')) return Colors.green.shade600;
    if (badgeColor.contains('emerald')) return Colors.green.shade600;
    if (badgeColor.contains('teal')) return Colors.teal.shade600;
    if (badgeColor.contains('cyan')) return Colors.cyan.shade600;
    if (badgeColor.contains('sky')) return Colors.lightBlue.shade600;
    if (badgeColor.contains('blue')) return Colors.blue.shade600;
    if (badgeColor.contains('indigo')) return Colors.indigo.shade600;
    if (badgeColor.contains('violet')) return Colors.deepPurple.shade500;
    if (badgeColor.contains('purple')) return Colors.purple.shade600;
    if (badgeColor.contains('fuchsia')) return Colors.pink.shade600;
    if (badgeColor.contains('pink')) return Colors.pink.shade400;
    if (badgeColor.contains('rose')) return Colors.red.shade400;

    return Colors.red.shade500;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade400, Colors.orange.shade500],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: AdsyLoadingIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_specialDeals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade400, Colors.orange.shade500],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.flash_on,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Special Deals',
                      style: AppFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Limited Time',
                        style: AppFonts.roboto(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Scrollable Cards
                SizedBox(
                  height: 95,
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _specialDeals.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 4),
                    itemBuilder: (context, index) {
                      final deal = _specialDeals[index];
                      return _buildDealCard(deal);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(Map<String, dynamic> deal) {
    final imageUrl = deal['image']?.toString() ?? '';
    final name = deal['name']?.toString() ?? '';
    final badge = deal['badge']?.toString() ?? 'SALE';
    final badgeColor = _getBadgeColor(deal['badge_color']?.toString());

    return GestureDetector(
      onTap: () {
        if (deal['id'] == null) return;
        final categoryId = deal['id'].toString();
        debugPrint('🔥 Hot deal tapped - ID: ${deal['id']}, Name: ${deal['name']}');

        // If host supplied a callback (e.g. eShop screen), filter in place.
        if (widget.onCategorySelected != null) {
          widget.onCategorySelected!(categoryId);
          return;
        }

        final currentRoute = ModalRoute.of(context)?.settings.name;
        if (currentRoute == '/eshop') {
          Navigator.pushReplacementNamed(
            context,
            '/eshop',
            arguments: {'categoryId': categoryId},
          );
        } else {
          // From homepage: keep home in the back stack so the user can
          // navigate back. Previously this used pushReplacementNamed which
          // removed the home route and made the back button exit the app.
          Navigator.pushNamed(
            context,
            '/eshop',
            arguments: {'categoryId': categoryId},
          );
        }
      },
      // Fixed width — the old IntrinsicWidth wrapper asked the infinite-width
      // image for its intrinsic size, which is unbounded, so in release builds
      // the whole card silently failed to lay out and the strip looked empty.
      child: Container(
          width: 78,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Image with badge
              Container(
                height: 55,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      badgeColor.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Product Image
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: AppImage.network(
                          imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          errorWidget: Container(
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                      ),

                    // Badge
                    Positioned(
                      top: 3,
                      left: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: AppFonts.roboto(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Name - Single line with ellipsis
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(
                  name,
                  style: AppFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
    );
  }
}
