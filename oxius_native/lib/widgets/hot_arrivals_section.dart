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
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        height: 140,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_hotArrivals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981),
                        const Color(0xFF059669),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'New & Hot Arrivals',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                
                const Spacer(),
                
                // View All Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleViewAll,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_viewAllLoading)
                            SizedBox(
                              width: 14,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF10B981)),
                              ),
                            )
                          else ...[
                            Text(
                              'View All',
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: const Color(0xFF059669),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Scrollable Cards
          SizedBox(
            height: 140,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
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
    final name = arrival['name']?.toString() ?? 'Unnamed Category';
    final badge = arrival['badge']?.toString();
    final badgeColorStr = arrival['badge_color']?.toString();
    final description = arrival['description']?.toString();
    final productCount = arrival['product_count'];
    
    // Only show badge if it exists in the data
    final hasBadge = badge != null && badge.isNotEmpty;
    final badgeColor = hasBadge ? _getBadgeColor(badgeColorStr) : Colors.transparent;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (widget.onCategorySelected != null && arrival['id'] != null) {
            widget.onCategorySelected!(arrival['id'].toString());
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 105,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image with dynamic badge
              Container(
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  color: const Color(0xFFF9FAFB),
                ),
                child: Stack(
                  children: [
                    // Product Image
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image_rounded,
                                size: 32,
                                color: const Color(0xFF9CA3AF),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Center(
                        child: Icon(
                          Icons.image_rounded,
                          size: 32,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    
                    // Dynamic Badge - only show if exists
                    if (hasBadge)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: badgeColor.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            badge!.toUpperCase(),
                            style: GoogleFonts.roboto(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    
                    // Product count badge - bottom left
                    if (productCount != null && productCount > 0)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$productCount items',
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
              
              // Name - Compact padding
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  alignment: Alignment.center,
                  child: Text(
                    name,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
