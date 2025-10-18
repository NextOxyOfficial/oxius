import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/eshop_service.dart';

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
      final response = await EshopService.fetchProductCategories(specialOffer: true);
      
      if (mounted) {
        setState(() {
          _specialDeals = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching special deals: $e');
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
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_specialDeals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Limited Time',
                        style: GoogleFonts.roboto(
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
                  height: 110,
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _specialDeals.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final deal = _specialDeals[index];
                      return _buildDealCard(deal);
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Scroll indicator
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 16,
                ),
              ),
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
        if (widget.onCategorySelected != null && deal['id'] != null) {
          widget.onCategorySelected!(deal['id'].toString());
        }
      },
      child: IntrinsicWidth(
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 75,
            maxWidth: 110,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Image with badge
              Container(
                height: 65,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      badgeColor.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Product Image
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade100,
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 32,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
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
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.roboto(
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
                  style: GoogleFonts.roboto(
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
      ),
    );
  }
}
