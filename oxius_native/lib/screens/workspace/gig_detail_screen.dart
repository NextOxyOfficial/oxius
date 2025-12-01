import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/workspace_service.dart';
import '../../services/api_service.dart';

class GigDetailScreen extends StatefulWidget {
  final String gigId;

  const GigDetailScreen({super.key, required this.gigId});

  @override
  State<GigDetailScreen> createState() => _GigDetailScreenState();
}

class _GigDetailScreenState extends State<GigDetailScreen> {
  final WorkspaceService _workspaceService = WorkspaceService();
  
  Map<String, dynamic>? _gig;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  bool _isOrdering = false;
  int _currentImageIndex = 0;
  final PageController _imageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadGigDetails();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadGigDetails() async {
    setState(() => _isLoading = true);
    
    try {
      final gig = await _workspaceService.fetchGigDetails(widget.gigId);
      final reviewsResult = await _workspaceService.fetchGigReviews(widget.gigId);
      
      if (mounted) {
        setState(() {
          _gig = gig;
          _reviews = reviewsResult['results'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load gig: $e')),
        );
      }
    }
  }

  String _getImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiService.baseUrl.replaceAll('/api', '')}$url';
  }

  Future<void> _placeOrder() async {
    setState(() => _isOrdering = true);
    
    try {
      await _workspaceService.createOrder(widget.gigId, {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOrdering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gig Details',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _gig?['is_favorited'] == true ? Icons.favorite : Icons.favorite_border,
              color: _gig?['is_favorited'] == true ? Colors.red : Colors.grey,
              size: 20,
            ),
            onPressed: () async {
              await _workspaceService.toggleFavorite(widget.gigId);
              _loadGigDetails();
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.grey, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _gig == null
              ? _buildErrorState()
              : _buildContent(),
      bottomNavigationBar: _gig != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildContent() {
    final user = _gig!['user'] as Map<String, dynamic>?;
    final images = _gig!['images'] as List<dynamic>? ?? [_gig!['image_url'] ?? _gig!['image']];
    final rating = (_gig!['rating'] ?? 0).toDouble();
    final reviewsCount = _gig!['reviews_count'] ?? _reviews.length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Gallery
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _imageController,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final imageUrl = images[index] is Map 
                        ? images[index]['url'] ?? images[index]['image']
                        : images[index];
                    return CachedNetworkImage(
                      imageUrl: _getImageUrl(imageUrl?.toString()),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                    );
                  },
                ),
                // Image Indicators
                if (images.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (index) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  _gig!['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Seller Info
                GestureDetector(
                  onTap: () {
                    // Navigate to seller profile
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: user?['avatar'] != null
                              ? CachedNetworkImageProvider(_getImageUrl(user!['avatar']))
                              : null,
                          child: user?['avatar'] == null
                              ? Text(
                                  (user?['name'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 18),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    user?['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (user?['kyc'] == true)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: Icon(Icons.verified, size: 16, color: Colors.blue),
                                    ),
                                  if (user?['is_pro'] == true)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'PRO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  ...List.generate(5, (i) {
                                    return Icon(
                                      Icons.star,
                                      size: 14,
                                      color: i < rating.round() ? Colors.amber : Colors.grey[300],
                                    );
                                  }),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${rating.toStringAsFixed(1)} ($reviewsCount reviews)',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                const Text(
                  'About This Gig',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _gig!['description'] ?? '',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Package Details
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Package Details',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPackageRow('Delivery Time', '${_gig!['delivery_time'] ?? 3} days'),
                _buildPackageRow('Revisions', '${_gig!['revisions'] ?? 2} included'),
                _buildPackageRow('Category', _gig!['category_name'] ?? 'General'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Reviews Section
          if (_reviews.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reviews ($reviewsCount)',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._reviews.take(3).map((review) => _buildReviewCard(review)),
                ],
              ),
            ),
          
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildPackageRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final user = review['user'] as Map<String, dynamic>?;
    final rating = (review['rating'] ?? 0).toInt();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: user?['avatar'] != null
                    ? CachedNetworkImageProvider(_getImageUrl(user!['avatar']))
                    : null,
                child: user?['avatar'] == null
                    ? Text((user?['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 12))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?['name'] ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          Icons.star,
                          size: 12,
                          color: i < rating ? Colors.amber : Colors.grey[300],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review['comment'] != null && review['comment'].isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review['comment'],
              style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final price = _gig!['price']?.toString() ?? '0';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Starting at',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  '৳$price',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: _isOrdering ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _isOrdering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Order Now',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Gig not found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'This gig may have been removed',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
