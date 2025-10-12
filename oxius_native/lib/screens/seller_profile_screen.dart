import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/sale_post.dart';
import '../services/sale_post_service.dart';
import '../services/api_service.dart';

/// Seller Profile Screen - Display seller information and their listings
class SellerProfileScreen extends StatefulWidget {
  final String? userId;

  const SellerProfileScreen({
    Key? key,
    this.userId,
  }) : super(key: key);

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  late SalePostService _postService;
  SaleUser? _seller;
  List<SalePost> _sellerPosts = [];
  bool _isLoading = true;
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _postService = SalePostService(baseUrl: ApiService.baseUrl);
    _fetchSellerInfo();
  }

  Future<void> _fetchSellerInfo() async {
    if (widget.userId == null) return;

    setState(() => _isLoading = true);
    
    try {
      // Fetch seller's posts to get user info
      final response = await _postService.fetchPosts(
        // We'll filter by this seller's posts
        pageSize: 20,
      );
      
      // Find posts by this seller
      final sellerPosts = response.results.where((post) => 
        post.user?.id == widget.userId
      ).toList();
      
      if (sellerPosts.isNotEmpty && mounted) {
        setState(() {
          _seller = sellerPosts.first.user;
          _sellerPosts = sellerPosts;
          _isLoading = false;
          _isLoadingPosts = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('Error fetching seller info: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingPosts = false;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatPrice(double price) {
    return '৳${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Seller Profile',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _seller == null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Seller not found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final seller = _seller!;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Card
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Cover gradient
                Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                ),
                
                // Profile info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Avatar
                      Transform.translate(
                        offset: const Offset(0, -50),
                        child: Column(
                          children: [
                            Container(
                              height: 96,
                              width: 96,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(48),
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(48),
                                child: seller.profilePicture != null
                                    ? CachedNetworkImage(
                                        imageUrl: seller.profilePicture!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: Colors.grey.shade200,
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: Colors.grey.shade200,
                                          child: Center(
                                            child: Text(
                                              seller.displayName[0].toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 36,
                                                color: Color(0xFF6B7280),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: Center(
                                          child: Text(
                                            seller.displayName[0].toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 36,
                                              color: Color(0xFF6B7280),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Name with badges
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  seller.displayName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                if (seller.kyc == true) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.verified,
                                    size: 20,
                                    color: Color(0xFF2563EB),
                                  ),
                                ],
                                if (seller.isPro == true) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.shield, size: 12, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'Pro',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Member since
                            if (seller.dateJoined != null)
                              Text(
                                'Member since ${_formatDate(seller.dateJoined)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            
                            const SizedBox(height: 16),
                            
                            // Stats row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sell, size: 16, color: const Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  '${seller.salePostCount ?? 0} Listings',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Contact button
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          // TODO: Implement contact functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contact feature coming soon!')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1F2937),
                          side: BorderSide(color: Colors.grey.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone, size: 16, color: const Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            const Text(
                              'Contact Seller',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Listings section
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Listings (${_sellerPosts.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                
                _isLoadingPosts
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                    : _sellerPosts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(
                                'No listings yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _sellerPosts.length,
                            itemBuilder: (context, index) {
                              final post = _sellerPosts[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/sale-detail',
                                    arguments: {'slug': post.slug},
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Image
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: post.images != null && post.images!.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: post.images![0].image,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(
                                                    color: Colors.grey.shade100,
                                                  ),
                                                  errorWidget: (context, url, error) => Container(
                                                    color: Colors.grey.shade100,
                                                    child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
                                                  ),
                                                )
                                              : Container(
                                                  color: Colors.grey.shade100,
                                                  child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
                                                ),
                                        ),
                                      ),
                                      // Info
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                post.title,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1F2937),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const Spacer(),
                                              Text(
                                                _formatPrice(post.price),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF10B981),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
