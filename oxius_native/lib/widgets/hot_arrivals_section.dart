import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/eshop_service.dart';

class HotArrivalsSection extends StatefulWidget {
  final Function(String)? onCategorySelected;
  final VoidCallback? onViewAllPressed;
  
  const HotArrivalsSection({
    super.key,
    this.onCategorySelected,
    this.onViewAllPressed,
  });

  @override
  State<HotArrivalsSection> createState() => _HotArrivalsSectionState();
}

class _HotArrivalsSectionState extends State<HotArrivalsSection> {
  List<Map<String, dynamic>> _hotArrivals = [];
  bool _isLoading = true;
  bool _viewAllLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchHotArrivals();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchHotArrivals() async {
    try {
      setState(() => _isLoading = true);
      
      // Fetch categories with hot_arrival filter
      final response = await EshopService.fetchProductCategories(hotArrival: true);
      
      if (mounted) {
        setState(() {
          _hotArrivals = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching hot arrivals: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getBadgeColor(String? badgeColor) {
    if (badgeColor == null) return Colors.green.shade600;
    
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
    
    return Colors.green.shade600;
  }

  void _handleViewAll() {
    setState(() => _viewAllLoading = true);
    
    if (widget.onViewAllPressed != null) {
      widget.onViewAllPressed!();
    }
    
    // Reset loading after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _viewAllLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        height: 150,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      );
    }

    if (_hotArrivals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Title with accent bar
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'New & Hot Arrivals',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Just In',
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade600,
                    ),
                  ),
                ),
                const Spacer(),
                
                // View All Button
                GestureDetector(
                  onTap: _handleViewAll,
                  child: Row(
                    children: [
                      if (_viewAllLoading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                          ),
                        )
                      else
                        Text(
                          'View All',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade600,
                          ),
                        ),
                      if (!_viewAllLoading) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.green.shade600,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Scrollable Cards
          SizedBox(
            height: 120,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: _hotArrivals.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final arrival = _hotArrivals[index];
                return _buildArrivalCard(arrival);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrivalCard(Map<String, dynamic> arrival) {
    final imageUrl = arrival['image']?.toString() ?? '';
    final name = arrival['name']?.toString() ?? '';
    final badge = arrival['badge']?.toString() ?? 'NEW';
    final badgeColor = _getBadgeColor(arrival['badge_color']?.toString());
    
    return GestureDetector(
      onTap: () {
        if (widget.onCategorySelected != null && arrival['id'] != null) {
          widget.onCategorySelected!(arrival['id'].toString());
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.26, // ~26% width
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image with badge
            Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    badgeColor.withOpacity(0.05),
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
                            color: Colors.grey.shade50,
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 24,
                              color: Colors.grey.shade300,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey.shade50,
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 24,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  
                  // Badge
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.roboto(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Name
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text(
                    name,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
