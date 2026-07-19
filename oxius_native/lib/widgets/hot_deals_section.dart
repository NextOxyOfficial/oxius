import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oxius_native/utils/image_utils.dart';
import '../services/eshop_service.dart';
import '../services/translation_service.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

// Clean marketplace palette — matches the eShop / vendor store pages.
const _dealGreen = Color(0xFF22C55E);
const _dealDark = Color(0xFF111827);
const _dealSlate50 = Color(0xFFF8FAFC);
const _dealSlate200 = Color(0xFFE2E8F0);
const _dealSlate400 = Color(0xFF94A3B8);

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
  final TranslationService _translationService = TranslationService();

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
        margin: const EdgeInsets.fromLTRB(10, 12, 10, 0),
        height: 120,
        decoration: BoxDecoration(
          color: _dealSlate50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: AdsyLoadingIndicator(color: _dealGreen),
        ),
      );
    }

    if (_specialDeals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header — clean section title + limited-time pill.
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
          child: Text(
            _translationService.t('special_deals', fallback: 'বিশেষ অফার'),
            style: GoogleFonts.inter(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: _dealDark,
              letterSpacing: -0.3,
            ),
          ),
        ),

        // Scrollable Cards
        SizedBox(
          height: 122,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _specialDeals.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final deal = _specialDeals[index];
              return _buildDealCard(deal);
            },
          ),
        ),
      ],
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
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            // Image card with badge (vendor category-rail style).
            Container(
              width: 80,
              height: 74,
              decoration: BoxDecoration(
                color: _dealSlate50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _dealSlate200),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    AppImage.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: const Center(
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 26,
                          color: _dealSlate400,
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 26,
                        color: _dealSlate400,
                      ),
                    ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.inter(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Name — up to two lines so longer names stay readable.
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: _dealDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
