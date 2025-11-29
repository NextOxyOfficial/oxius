import 'package:flutter/material.dart';

/// Skeleton loader for sale products list view
class SaleListSkeletonLoader extends StatefulWidget {
  final int itemCount;
  
  const SaleListSkeletonLoader({
    super.key,
    this.itemCount = 4,
  });

  @override
  State<SaleListSkeletonLoader> createState() => _SaleListSkeletonLoaderState();
}

class _SaleListSkeletonLoaderState extends State<SaleListSkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: widget.itemCount,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image skeleton
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                      child: SizedBox(
                        width: 90,
                        height: 90,
                        child: _buildShimmer(),
                      ),
                    ),
                    
                    // Content skeleton
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title skeleton
                            _buildShimmerBox(
                              width: double.infinity,
                              height: 13,
                              borderRadius: 4,
                            ),
                            const SizedBox(height: 5),
                            
                            // Price and condition row skeleton
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    // Price skeleton
                                    _buildShimmerBox(
                                      width: 70,
                                      height: 14,
                                      borderRadius: 4,
                                    ),
                                    const SizedBox(width: 8),
                                    // Condition badge skeleton
                                    _buildShimmerBox(
                                      width: 50,
                                      height: 18,
                                      borderRadius: 4,
                                    ),
                                  ],
                                ),
                                // Time skeleton
                                _buildShimmerBox(
                                  width: 45,
                                  height: 9,
                                  borderRadius: 2,
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            
                            // Location skeleton
                            Row(
                              children: [
                                _buildShimmerBox(
                                  width: 11,
                                  height: 11,
                                  borderRadius: 2,
                                ),
                                const SizedBox(width: 3),
                                _buildShimmerBox(
                                  width: 120,
                                  height: 10,
                                  borderRadius: 2,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFF3F4F6),
                Color(0xFFE5E7EB),
                Color(0xFFF3F4F6),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFF3F4F6),
                Color(0xFFE5E7EB),
                Color(0xFFF3F4F6),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}
